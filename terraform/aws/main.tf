terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region for the free-tier EC2-hosted k3s cluster (e.g., us-east-1)."
  type        = string
}

variable "aws_instance_type" {
  description = "Instance type for the k3s EC2 node. Use a free-tier eligible type where possible (e.g., t2.micro)."
  type        = string
  default     = "t2.micro"
}

variable "aws_key_name" {
  description = "Optional EC2 key pair name for SSH access to the k3s node."
  type        = string
  default     = ""
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_ami" "ubuntu_2204" {
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

resource "aws_security_group" "ntp_k3s" {
  name        = "ntp-k3s-sg"
  description = "Security group for k3s NTP node"
  vpc_id      = data.aws_vpc.default.id

  # NTP
  ingress {
    description = "NTP (UDP 123) from anywhere - tighten per pool.ntp.org guidance as needed"
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ntp-k3s-sg"
  }
}

locals {
  aws_user_data = <<-EOF
    #!/bin/bash
    set -eux

    # Basic updates
    apt-get update -y
    apt-get install -y curl

    # Install k3s (single-node server)
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik" sh -

    # Placeholder: deploy NTP server workload via k8s manifests / Helm once k3s is ready.
  EOF
}

resource "aws_instance" "k3s_server" {
  ami                    = data.aws_ami.ubuntu_2204.id
  instance_type          = var.aws_instance_type
  subnet_id              = data.aws_subnet_ids.default.ids[0]
  vpc_security_group_ids = [aws_security_group.ntp_k3s.id]
  user_data              = local.aws_user_data

  associate_public_ip_address = true

  key_name = var.aws_key_name != "" ? var.aws_key_name : null

  tags = {
    Name = "ntp-k3s-aws"
    Role = "ntp-k3s"
  }
}
