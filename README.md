# ntp-k3s-terraform

Infrastructure-as-code project to provision NTP server capacity on k3s clusters using Terraform:
- An AWS k3s cluster on a free-tier EC2 instance for IPv4-serving NTP
- A GCP k3s cluster (cheapest free-tier option) for IPv6-serving NTP

Both clusters are intended to follow pool.ntp.org server guidelines and run a hardened NTP service.

## k3s configuration with Ansible

After you `terraform apply` the AWS and GCP modules, you can use Ansible to configure the k3s clusters on the created instances:

1. Copy `ansible/inventory.example.ini` to `ansible/inventory.ini` and fill in the public IPs for the AWS and GCP nodes.
2. Run the playbook from the repo root:

   ```bash
   ansible-playbook -i ansible/inventory.ini ansible/k3s.yml
   ```

The playbook will:
- Ensure k3s is installed (single-node server) on each instance.
- Wait for the node to become Ready.
- Create an `ntp` namespace.
- Label all nodes with `ntp=server` for NTP workloads.
