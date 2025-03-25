terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.73.2"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure = true
}

# Resource pool for our cluster
resource "proxmox_virtual_environment_pool" "k3s_pool" {
  comment = "K3s cluster resources"
  pool_id = "k3s"
}

# Master node
resource "proxmox_virtual_environment_vm" "k3s_master" {
  name = "k3s-master"
  node_name = var.proxmox_node
  pool_id = proxmox_virtual_environment_pool.k3s_pool.pool_id
  vm_id = 200

  clone {
    vm_id = var.template_vm_id
    full = true
  }

  cpu {
    cores = 2
    type = "host"
  }

  memory {
    dedicated = 2048
  }

  network_device {
    bridge = var.network_config.bridge
    model = "virtio"
    vlan_id = 30
  }

  disk {
    datastore_id = "local-zfs"
    size = 40
    interface = "scsi0"
    file_format = "raw"
  }

  initialization {
    datastore_id = "local-zfs"

    ip_config {
      ipv4 {
        address = var.kubernetes_master.ip
        gateway = var.network_config.gateway
      }
    }
    
    user_account {
      keys = [var.ssh_public_key]
      username = "ubuntu"
    }
  }
}

# Worker nodes
resource "proxmox_virtual_environment_vm" "k3s_worker" {
  count = 2  # Start with 2 workers

  name = "k3s-worker-${count.index + 1}"
  node_name = var.proxmox_node
  pool_id = proxmox_virtual_environment_pool.k3s_pool.pool_id
  vm_id = 201 + count.index

  clone {
    vm_id = var.template_vm_id
    full = true
  }

  cpu {
    cores = 2
    type = "host"
  }

  memory {
    dedicated = 2048
  }

  network_device {
    bridge = var.network_config.bridge
    model = "virtio"
    vlan_id = 30
  }

  disk {
    datastore_id = "local-zfs"
    size = 40
    interface = "scsi0"
    file_format = "raw"
  }

  initialization {
    datastore_id = "local-zfs"
    
    ip_config {
      ipv4 {
        address = "192.168.30.${var.kubernetes_workers.ip_start + count.index}/24"
        gateway = var.network_config.gateway
      }
    }
    
    user_account {
      keys = [var.ssh_public_key]
      username = "ubuntu"
    }
  }
} 