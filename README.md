# ntp-k3s-terraform

Infrastructure-as-code project to provision NTP server capacity on k3s clusters using Terraform:
- An AWS k3s cluster on a free-tier EC2 instance for IPv4-serving NTP
- A GCP k3s cluster (cheapest free-tier option) for IPv6-serving NTP

Both clusters are intended to follow pool.ntp.org server guidelines and run a hardened NTP service.
