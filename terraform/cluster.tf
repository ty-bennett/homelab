# 2026-07-21 00:27:04 Terraform file to create k3s cluster with 3 agents and 4 workers based on current hardware and an external LB for HA

variable "hosts" {
  type    = list(string)
  default = []

  validation {
    condition     = length(var.hosts) > 1 && length(var.hosts) % 2 != 0
    error_message = "Ensure more than 3 and odd nodes"
  }
}

variable "user" {
  type = string
}

variable "private_key" {
  type      = string
  sensitive = true
}

variable "config" {
  type    = string
  default = null
}

resource "k3s_server" "node0" {
  auth = {
    host        = var.hosts[0]
    user        = var.user
    private_key = var.private_key
  }
  config = var.config
  highly_available = {
    cluster_init = true
  }
}

resource "k3s_server" "node1" {
  count = length(var.hosts) - 1

  auth = {
    host        = var.hosts[count.index + 1]
    user        = var.user
    private_key = var.private_key
  }
  config = var.config
  highly_available = {
    token  = k3s_server.node0.token
    server = k3s_server.node0.server
  }
}

resource "k3s_server" "opensuse" {
  count = length(var.hosts) - 1

  auth = {
    host        = var.hosts[count.index + 1]
    user        = var.user
    private_key = var.private_key
  }
  config = var.config
  highly_available = {
    token  = k3s_server.node0.token
    server = k3s_server.node0.server
  }
}

