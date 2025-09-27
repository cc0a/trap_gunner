terraform {
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

# Find latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# Default subnet
# Default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  subnet_id = data.aws_subnets.default.ids[0]
}

# Security group allowing SSH from your IP address
resource "aws_security_group" "ssh" {
  name        = "allow_ssh_from_client"
  description = "Allow SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr] # change to your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance
resource "aws_instance" "micro" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  associate_public_ip_address = true
  key_name                    = var.key_name  # reference your existing key pair

  tags = {
    Name = "terraform-micro-instance"
  }
}

# Allocate and attach Elastic IP
resource "aws_eip" "static_ip" {
  domain      = "vpc"
  instance = aws_instance.micro.id
}

output "public_ip" {
  value = aws_eip.static_ip.public_ip
}

output "ssh_command" {
  value = "ssh -i /path/to/your-key.pem ubuntu@${aws_eip.static_ip.public_ip}"
}
