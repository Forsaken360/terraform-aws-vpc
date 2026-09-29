terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Example   = "complete"
    }
  }
}

module "vpc" {
  source = "../.."

  project            = "portfolio"
  environment        = "dev"
  vpc_cidr           = "10.0.0.0/16"
  az_count           = 3
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_flow_logs   = true
}

output "vpc_id" {
  description = "VPC ID from the example deployment."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs from the example deployment."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs from the example deployment."
  value       = module.vpc.private_subnet_ids
}
