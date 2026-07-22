variable "k3s_version" {
  description = "K3s version to install (null = latest)"
  type        = string
  default     = null
}

variable "ssh_user" {
  description = "SSH user with passwordless sudo on all nodes"
  type        = string
}

variable "ssh_private_key" {
  description = "Private SSH key contents (e.g. file(\"~/.ssh/id_ed25519\")) valid on every node"
  type        = string
  sensitive   = true
}

variable "server_hosts" {
  description = "Control plane node IPs. First entry is the etcd init node. Must be odd count."
  type        = list(string)

  validation {
    condition     = length(var.server_hosts) % 2 != 0
    error_message = "etcd needs an odd number of server nodes (1, 3, 5...)."
  }
}

variable "agent_hosts" {
  description = "Worker node IPs (the Pis)"
  type        = list(string)
  default     = []
}

variable "ai_agent_host" {
  description = "IP of the big-RAM AI worker (gets workload=ai label). Null to skip."
  type        = string
  default     = null
}

variable "vip" {
  description = "Virtual IP for the control plane (kube-vip, ARP mode). Must be a free address in the nodes' subnet, outside DHCP range."
  type        = string
  default     = "192.168.68.49"
}

variable "tls_san" {
  description = "Extra SANs for the API server cert: VIP, tailscale IPs/names, DNS aliases. The VIP is always added automatically."
  type        = list(string)
  default     = []
}

variable "kube_vip_version" {
  description = "kube-vip image tag"
  type        = string
  default     = "v1.0.4"
}

variable "kube_vip_interface" {
  description = "Interface for the VIP. Leave null for per-node auto-detection (recommended when nodes have different interface names)."
  type        = string
  default     = null
}
