terraform {
  required_providers {
    k3s = {
      source  = "danielbooth-cloud/k3s"
      version = "0.2.3"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config" # Or use token/host authentication for remote clusters
}
