# terraform-aws-vpc

A reusable Terraform module that provisions a production-style AWS VPC networking
foundation: public and private subnets across multiple availability zones, an
internet gateway, NAT gateway(s), locked-down default security group, and VPC
flow logs shipped to CloudWatch.

## Architecture

The module builds a single VPC with a classic two-tier subnet layout:

- **One VPC** with DNS support and DNS hostnames enabled, so services like RDS
  and EKS that rely on private DNS resolution work out of the box.
- **Public subnets** — one per AZ, carved from the first `az_count` /24 blocks
  of the VPC CIDR. They route `0.0.0.0/0` through the internet gateway and get
  public IPs on launch. This is where load balancers, bastion hosts, and NAT
  gateways live.
- **Private subnets** — one per AZ, carved from the next `az_count` /24 blocks.
  No direct internet ingress. Outbound traffic leaves through the NAT
  gateway(s) when `enable_nat_gateway` is true; with it disabled the private
  subnets are fully isolated (no default route at all).
- **Route tables** — one shared public route table; one private route table per
  NAT gateway so each AZ's outbound traffic stays in-AZ (no cross-AZ data
  charges on the return path). A single shared private table is used when there
  is only one NAT gateway or NAT is disabled.
- **Default security group** — AWS ships it wide open (self-referencing
  ingress). This module manages it and strips the default ingress rule, leaving
  outbound-only. Workloads should get their own explicit security groups.
- **Network ACLs** — left at their AWS defaults (allow all), which is the
  standard practice when security groups are the enforcement point.
- **VPC flow logs** — `ALL` traffic (accepted and rejected) published to a
  CloudWatch log group with 30-day retention, using a least-privilege IAM role
  assumed by the flow-logs service.

With the defaults (`az_count = 3`, single NAT gateway), a `/16` VPC yields:

| Subnet            | CIDR          | AZ      |
| ----------------- | ------------- | ------- |
| public (x3)       | 10.0.0.0/24   | a       |
|                   | 10.0.1.0/24   | b       |
|                   | 10.0.2.0/24   | c       |
| private (x3)      | 10.0.3.0/24   | a       |
|                   | 10.0.4.0/24   | b       |
|                   | 10.0.5.0/24   | c       |

## Prerequisites

- Terraform >= 1.5
- AWS provider ~> 5.0 (declared in `versions.tf`)
- AWS credentials with permissions to manage VPC networking, IAM, and
  CloudWatch Logs. No credentials are stored in this repo.

## Usage

```hcl
module "vpc" {
  source = "github.com/Forsaken360/terraform-aws-vpc"

  project            = "portfolio"
  environment        = "dev"
  vpc_cidr           = "10.0.0.0/16"
  az_count           = 3
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_flow_logs   = true
}
```

A runnable version lives in [`examples/complete`](examples/complete/main.tf).

## Inputs

| Name                | Type     | Default | Description                                                        |
| ------------------- | -------- | ------- | ------------------------------------------------------------------ |
| `project`           | `string` | —       | Project slug; prefixed to resource names and the `Project` tag.    |
| `environment`       | `string` | —       | `dev`, `staging`, or `prod`; used in names and the `Environment` tag. |
| `vpc_cidr`          | `string` | —       | VPC CIDR block. Must be `/16` or larger (subnets are carved as /24s). |
| `az_count`          | `number` | `3`     | AZs to span; one public + one private subnet per AZ (1–6).         |
| `enable_nat_gateway`| `bool`   | `true`  | Provision NAT gateway(s) for private-subnet outbound traffic.      |
| `single_nat_gateway`| `bool`   | `true`  | One shared NAT gateway instead of one per AZ.                      |
| `enable_flow_logs`  | `bool`   | `true`  | Ship VPC flow logs (`ALL`) to CloudWatch Logs.                     |

## Outputs

| Name                       | Description                                              |
| -------------------------- | -------------------------------------------------------- |
| `vpc_id`                   | ID of the created VPC.                                   |
| `public_subnet_ids`        | Public subnet IDs, ordered by AZ.                        |
| `private_subnet_ids`       | Private subnet IDs, ordered by AZ.                       |
| `nat_gateway_ids`          | NAT gateway IDs (empty when NAT is disabled).            |
| `default_security_group_id`| ID of the locked-down default security group.            |

## Notes

### NAT gateway cost tradeoff

A NAT gateway costs roughly $32–45/month per AZ before data processing
(~$0.045/GB). One NAT per AZ across 3 AZs is ~$100–135/month idle; a single
shared NAT is ~$35–45/month. The module defaults to `single_nat_gateway = true`
because for dev and small workloads the savings dominate — but know what you
give up: an AZ outage takes the NAT with it, and all private-subnet outbound
traffic hairpins through one AZ, adding cross-AZ data charges. For production
workloads that need AZ-level resilience, set `single_nat_gateway = false`.

### Disabling NAT entirely

With `enable_nat_gateway = false`, private subnets get no default route. That
is the right shape for fully isolated tiers (e.g. databases with no outbound
needs), but anything pulling container images or OS updates from a private
subnet will fail — use VPC endpoints for ECR, S3, and SSM in that setup.

### Flow log volume

`traffic_type = "ALL"` on a busy VPC generates significant CloudWatch ingest.
The 30-day retention in `main.tf` is a sane default; tighten the filter to
`REJECT` or ship to S3 if log costs become the line item you notice.

## License

MIT — see [LICENSE](LICENSE).
