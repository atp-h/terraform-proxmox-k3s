# Proxmox K3s Cluster Infrastructure

This repository contains Terraform configurations to automatically provision a lightweight Kubernetes cluster using k3s on Proxmox VE. It creates a cluster with one master node and two worker nodes, all running Ubuntu Server.

## Architecture

The infrastructure consists of:
- 1 k3s master node (VM ID: 200)
- 2 k3s worker nodes (VM IDs: 201, 202)
- All nodes are created from an Ubuntu cloud image template
- Nodes are configured with static IP addresses
- All VMs are placed in a dedicated Proxmox resource pool named "k3s"

## Prerequisites

1. Proxmox VE server (tested with version 8.x)
2. SSH key pair for VM access
3. Ubuntu cloud image template in Proxmox
4. Terraform installed locally
5. Proxmox API token with appropriate permissions
6. Ansible installed locally (for k3s setup)

## Quick Start

1. Clone this repository
2. Copy `terraform.tfvars.example` to `terraform.tfvars`:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
3. Edit `terraform.tfvars` with your specific configuration:
   - Proxmox API credentials
   - Network settings
   - SSH public key
   - VM resource allocations

4. Initialize and apply Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. Set up k3s using Ansible:
   ```bash
   cd ansible
   # Set a secure token for the cluster (optional)
   export K3S_TOKEN=your-secure-token-here
   ansible-playbook -i hosts setup-k3s.yml
   ```

## Detailed Setup Instructions

### 1. Create Ubuntu Cloud Image Template

First, create the Ubuntu cloud image template in Proxmox:

```bash
# Download Ubuntu Cloud Image
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

# Install libguestfs-tools
apt-get install -y libguestfs-tools

# Create VM template (ID 9000)
qm create 9000 --name ubuntu-cloud-init-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 focal-server-cloudimg-amd64.img local-zfs
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-9000-disk-0
qm set 9000 --ide2 local-zfs:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --agent 1
qm template 9000
```

### 2. Configure Terraform Variables

Edit `terraform.tfvars` with your specific settings:

```hcl
proxmox_api_url = "https://your-proxmox-host:8006/api2/json"
proxmox_api_token_id = "root@pam!terraform"
proxmox_api_token_secret = "your-secret-token"
proxmox_node = "pve"
template_vm_id = 9000
ssh_public_key = "your-ssh-public-key"

network_config = {
  bridge = "vmbr0"
  subnet = "192.168.30.0/24"
  gateway = "192.168.30.1"
}

kubernetes_master = {
  ip = "192.168.30.100/24"
}

kubernetes_workers = {
  ip_start = 11
}
```

### 3. Deploy Infrastructure

Run Terraform to create the infrastructure:

```bash
terraform init
terraform plan
terraform apply
```

### 4. Configure Ansible

The Ansible playbooks are located in the `ansible` directory. The setup process is automated and will:

1. Configure all nodes with:
   - System updates
   - Required packages
   - Disabled swap
   - Required kernel modules and parameters

2. Set up the master node with:
   - k3s server installation
   - Systemd service configuration
   - Automatic kubeconfig generation

3. Configure worker nodes with:
   - k3s agent installation
   - Systemd service configuration
   - Automatic cluster joining

To run the setup:

```bash
cd ansible
ansible-playbook -i hosts setup-k3s.yml
```

The playbook will automatically:
- Use the correct IP addresses from your Terraform configuration
- Generate and save the kubeconfig file locally
- Configure all necessary system requirements
- Set up the complete k3s cluster

## Post-Deployment

After the infrastructure and k3s are set up:

1. Access the cluster:
   ```bash
   # The kubeconfig file will be automatically saved in the ansible directory
   export KUBECONFIG=./ansible/k3s.yaml
   kubectl get nodes
   ```

2. Verify the cluster:
   ```bash
   kubectl get nodes
   kubectl get pods -A
   ```

## Resource Requirements

Each VM is configured with:
- 2 CPU cores
- 2GB RAM
- 40GB storage
- Static IP address
- Ubuntu Server 20.04 LTS

## Maintenance

- To add more worker nodes:
  1. Update the `count` parameter in `terraform.tfvars`
  2. Run `terraform apply`
  3. Update the `ansible/hosts` file with the new worker node IPs
  4. Run the Ansible playbook again: `ansible-playbook -i hosts setup-k3s.yml`
- To update VM resources, modify the respective CPU and memory blocks
- To destroy the infrastructure: `terraform destroy`
