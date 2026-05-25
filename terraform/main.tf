terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = var.aws_region
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true # Fixes LocalStack S3 routing layout

  endpoints {
    ec2 = "http://localhost:4566"
    s3  = "http://localhost:4566"
  }
}

# -------------------------------------------------------------------------
# LOCALS
# -------------------------------------------------------------------------
locals {
  common_tags = {
    Project     = var.project_name
    Environment = "staging"
    Owner       = "ankush"
  }
}

# -------------------------------------------------------------------------
# MODULES & NETWORKING CONFIGURATION
# -------------------------------------------------------------------------
module "network" {
  source = "./modules/network"
  region = var.aws_region   
  tags   = local.common_tags 
}

# -------------------------------------------------------------------------
# COMPUTE & SECURITY GROUPS
# -------------------------------------------------------------------------
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Allow inbound HTTP traffic"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_instance" "web_1" {
  ami                    = "ami-df5dbec3" 
  instance_type          = "t3.micro"
  # FIX: Automatically cycles through possible list names to find the right one
  subnet_id              = try(module.network.subnet_ids[0], module.network.subnets[0], module.network.public_subnets[0])
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = local.common_tags
}

resource "aws_instance" "web_2" {
  ami                    = "ami-df5dbec3"
  instance_type          = "t3.micro"
  # FIX: Automatically cycles through possible list names to find the right one
  subnet_id              = try(module.network.subnet_ids[1], module.network.subnets[1], module.network.public_subnets[1])
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = local.common_tags
}

# -------------------------------------------------------------------------
# S3 LOGGING STORAGE
# -------------------------------------------------------------------------
resource "aws_s3_bucket" "logs" {
  bucket        = "${var.project_name}-logs-ankush"
  force_destroy = true
  tags          = local.common_tags

  # Kept inline to bypass the LocalStack standalone configuration hang bug.
  # Ignore the deprecation notice—it is required to make v3.8.0 cooperate smoothly.
  lifecycle_rule {
    id      = "expire-noncurrent-versions"
    enabled = true

    noncurrent_version_expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# -------------------------------------------------------------------------
# TARGETED ORPHAN RESOURCE: Standalone Unattached Volume
# -------------------------------------------------------------------------
resource "aws_ebs_volume" "orphan" {
  availability_zone = "${var.aws_region}a"
  size              = 100
  type              = "gp3"

  tags = {
    Name = "nimbuskart-orphan-vol"
  }
}
