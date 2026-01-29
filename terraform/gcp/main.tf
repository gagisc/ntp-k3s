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

variable "gcp_zone" {
  description = "GCP zone for the k3s node (must be in the chosen region)."
  type        = string
}

variable "gcp_machine_type" {
  description = "Machine type for the k3s node (e.g., e2-micro for free tier)."
  type        = string
  default     = "e2-micro"
}

variable "gcp_service_account_email" {
  description = "Optional service account email for the k3s node; if empty, the default compute service account is used."
  type        = string
  default     = ""
}

resource "google_compute_network" "ntp" {
  name                    = "ntp-k3s-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "ntp" {
  name          = "ntp-k3s-subnet"
  ip_cidr_range = "10.20.0.0/24"
  region        = var.gcp_region
  network       = google_compute_network.ntp.id

  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
}

resource "google_compute_firewall" "ntp" {
  name    = "ntp-k3s-firewall"
  network = google_compute_network.ntp.name

  allow {
    protocol = "udp"
    ports    = ["123"]
  }

  # Consider tightening this to regions expected by pool.ntp.org
  source_ranges = ["0.0.0.0/0", "::/0"]

  target_tags = ["ntp-k3s"]
}

resource "google_compute_instance" "k3s_server" {
  name         = "ntp-k3s-gcp"
  machine_type = var.gcp_machine_type
  zone         = var.gcp_zone

  tags = ["ntp-k3s"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.ntp.id

    # IPv4 access
    access_config {}

    # External IPv6
    ipv6_access_config {}
  }

  service_account {
    email  = var.gcp_service_account_email != "" ? var.gcp_service_account_email : null
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -eux

    # Basic updates
    apt-get update -y
    apt-get install -y curl

    # Install k3s (single-node server)
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik" sh -

    # Placeholder: deploy IPv6-capable NTP server workload via k8s manifests / Helm.
  EOF
}
