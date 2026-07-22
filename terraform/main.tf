locals {
  # Shared server config: VIP + any extra SANs baked into every API cert.
  server_config = yamlencode({
    tls-san = distinct(concat([var.vip], var.tls_san))
  })

  ai_agent_config = yamlencode({
    node-label = ["workload=ai"]
  })
}

# ---------------------------------------------------------------------------
# Control plane: first server initializes embedded etcd, the rest join it.
# ---------------------------------------------------------------------------

resource "k3s_server" "init" {
  auth = {
    host        = var.server_hosts[0]
    user        = var.ssh_user
    private_key = var.ssh_private_key
  }

  config = local.server_config

  highly_available = {
    cluster_init = true
  }
}

resource "k3s_server" "join" {
  count = length(var.server_hosts) - 1

  auth = {
    host        = var.server_hosts[count.index + 1]
    user        = var.ssh_user
    private_key = var.ssh_private_key
  }

  config = local.server_config

  highly_available = {
    token  = k3s_server.init.token
    server = k3s_server.init.server
  }
}

# ---------------------------------------------------------------------------
# Workers
# ---------------------------------------------------------------------------

resource "k3s_agent" "workers" {
  count = length(var.agent_hosts)

  auth = {
    host        = var.agent_hosts[count.index]
    user        = var.ssh_user
    private_key = var.ssh_private_key
  }

  kubeconfig = k3s_server.init.kubeconfig
  server     = k3s_server.init.server
  token      = k3s_server.init.token

  # Join only after the full control plane exists.
  depends_on = [k3s_server.join]
}

resource "k3s_agent" "ai" {
  count = var.ai_agent_host == null ? 0 : 1

  auth = {
    host        = var.ai_agent_host
    user        = var.ssh_user
    private_key = var.ssh_private_key
  }

  kubeconfig = k3s_server.init.kubeconfig
  server     = k3s_server.init.server
  token      = k3s_server.init.token
  config     = local.ai_agent_config

  depends_on = [k3s_server.join]
}
