terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Created by ../../bootstrap. Replace the bucket name with your own.
  backend "s3" {
    bucket         = "REPLACE-WITH-YOUR-STATE-BUCKET"
    key            = "envs/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment
  cidr_block  = "10.30.0.0/16"
  az_count    = 2
  nat_per_az  = false
}

module "web" {
  source = "../../modules/web"

  project            = var.project
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  instance_type      = "t3.micro"
  desired_capacity   = 2
}
