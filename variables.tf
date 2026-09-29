variable "project" {
  description = "Short project slug. Prefixed to resource names and set as the Project tag."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,32}$", var.project))
    error_message = "project must be 2-32 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment. Used in resource names and set as the Environment tag."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Subnets are carved as /24s with cidrsubnet(var.vpc_cidr, 8, ...), so the block must be /16 or larger."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block, e.g. 10.0.0.0/16."
  }
}

variable "az_count" {
  description = "Number of availability zones to span. One public and one private subnet are created per AZ."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 6 && floor(var.az_count) == var.az_count
    error_message = "az_count must be a whole number between 1 and 6."
  }
}

variable "enable_nat_gateway" {
  description = "Provision NAT gateway(s) so instances in private subnets can initiate outbound internet traffic (package updates, image pulls, API calls)."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway in the first AZ instead of one per AZ. Cheaper, but an AZ outage or NAT failure removes outbound access for every private subnet."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Capture VPC flow logs (ALL traffic, accepted and rejected) to CloudWatch Logs via a dedicated IAM role."
  type        = bool
  default     = true
}
