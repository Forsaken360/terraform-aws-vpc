output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, ordered by AZ."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets, ordered by AZ."
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways (empty when enable_nat_gateway is false)."
  value       = aws_nat_gateway.this[*].id
}

output "default_security_group_id" {
  description = "ID of the VPC default security group (locked down: no ingress)."
  value       = aws_default_security_group.this.id
}
