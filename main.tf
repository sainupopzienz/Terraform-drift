terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  
  tags = var.common_tags
}

# S3 Module
module "s3" {
  source = "./modules/s3"
  
  bucket_name = var.s3_bucket_name
  tags        = var.common_tags
}

# EC2 Module
module "ec2" {
  source = "./modules/ec2"
  
  instance_type        = var.instance_type
  key_name            = var.key_name
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  
  tags = var.common_tags
}
