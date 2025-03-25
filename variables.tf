variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

variable "template_name" {
  description = "Name of the VM template to clone"
  type        = string
  default     = "ubuntu-cloud-init-template"
}

variable "template_vm_id" {
  description = "ID of the VM template to clone"
  type        = number
  default     = 9000
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "kubernetes_master" {
  description = "Kubernetes master node configuration"
  type        = object({
    ip      = string
  })
  default     = {
    ip        = "192.168.30.100/24"
  }
}

variable "kubernetes_workers" {
  description = "Kubernetes worker nodes configuration"
  type        = object({
    ip_start  = number
  })
  default     = {
    ip_start  = 101
  }
}

variable "network_config" {
  description = "Network configuration for Kubernetes cluster"
  type        = object({
    bridge = string
    subnet = string
    gateway = string
  })
  default     = {
    bridge = "vmbr0"
    subnet = "192.168.30.0/24"
    gateway = "192.168.30.1"
  }
}
