terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "ap-south-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    ec2 = "http://localhost:4566"
    s3  = "http://localhost:4566"
  }
}

# 1. VPC and Subnets
resource "aws_vpc" "main" {
  cidr_block = "10.20.0.0/16"
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "ap-south-1a"
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "ap-south-1b"
}

# 2. Security Group
resource "aws_security_group" "web_sg" {
  name   = "web-tier-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Two EC2 Instances
resource "aws_instance" "web_1" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.subnet_a.id
  tags          = { Name = "web-tier-1" }
}

resource "aws_instance" "web_2" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.subnet_b.id
  tags          = { Name = "web-tier-2" }
}

# 4. S3 Bucket
resource "aws_s3_bucket" "logs" {
  bucket = "nimbuskart-logs-ankush"
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration { status = "Enabled" }
}

# 5. Orphaned EBS Volume
resource "aws_ebs_volume" "orphan" {
  availability_zone = "ap-south-1a"
  size              = 10
  tags              = { Name = "orphaned-volume" }
}
