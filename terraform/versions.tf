terraform {
  required_version = ">= 1.5.0"

  required_providers {
    k3s = {
      source  = "danielbooth-cloud/k3s"
      version = "0.2.3"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
  }
}

provider "k3s" {
  k3s_version = var.k3s_version
}

# Authenticated against the freshly created cluster using certs exported
# by the init server. Used to deploy kube-vip.
provider "kubernetes" {
  host                   = k3s_server.init.cluster_auth.server
  client_certificate     = k3s_server.init.cluster_auth.client_certificate_data
  client_key             = k3s_server.init.cluster_auth.client_key_data
  cluster_ca_certificate = k3s_server.init.cluster_auth.certificate_authority_data
}
