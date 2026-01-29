terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

variable "gcp_project" {
  description = "GCP project ID for the IPv6 k3s NTP cluster (cheapest free-tier option)."
  type        = string
}

variable "gcp_region" {
  description = "GCP region for the IPv6 k3s NTP cluster."
  type        = string
}

# TODO: Define IPv6-capable networking and k3s bootstrap for NTP server.
