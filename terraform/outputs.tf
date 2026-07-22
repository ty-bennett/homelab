# Kubeconfig rewritten to point at the VIP instead of the init node.
data "k3s_kubeconfig" "vip" {
  auth = {
    host        = var.server_hosts[0]
    user        = var.ssh_user
    private_key = var.ssh_private_key
  }

  hostname = var.vip

  depends_on = [k3s_server.init]
}

output "kubeconfig" {
  description = "Kubeconfig with server set to the VIP. terraform output -raw kubeconfig > ~/.kube/config"
  value       = data.k3s_kubeconfig.vip.kubeconfig
  sensitive   = true
}

output "api_endpoint" {
  value = "https://${var.vip}:6443"
}

output "join_token" {
  description = "Cluster join token (for adding nodes out-of-band)"
  value       = k3s_server.init.token
  sensitive   = true
}
