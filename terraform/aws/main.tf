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

# TODO: Define networking, EC2 free-tier instance, and k3s bootstrap for IPv4 NTP server.
