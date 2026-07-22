# kube-vip in ARP mode: control-plane VIP with leader election.
# Mirrors https://kube-vip.io/manifests/rbac.yaml + the k3s docs daemonset.

resource "kubernetes_service_account_v1" "kube_vip" {
  metadata {
    name      = "kube-vip"
    namespace = "kube-system"
  }

  depends_on = [k3s_server.join]
}

resource "kubernetes_cluster_role_v1" "kube_vip" {
  metadata {
    name = "system:kube-vip-role"
    annotations = {
      "rbac.authorization.kubernetes.io/autoupdate" = "true"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["services/status"]
    verbs      = ["update"]
  }
  rule {
    api_groups = [""]
    resources  = ["services", "endpoints"]
    verbs      = ["list", "get", "watch", "update"]
  }
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["list", "get", "watch", "update", "patch"]
  }
  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["list", "get", "watch", "update", "create"]
  }
  rule {
    api_groups = ["discovery.k8s.io"]
    resources  = ["endpointslices"]
    verbs      = ["list", "get", "watch", "update"]
  }

  depends_on = [k3s_server.join]
}

resource "kubernetes_cluster_role_binding_v1" "kube_vip" {
  metadata {
    name = "system:kube-vip-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.kube_vip.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.kube_vip.metadata[0].name
    namespace = "kube-system"
  }
}

resource "kubernetes_daemon_set_v1" "kube_vip" {
  metadata {
    name      = "kube-vip-ds"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"    = "kube-vip-ds"
      "app.kubernetes.io/version" = var.kube_vip_version
    }
  }

  spec {
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "kube-vip-ds"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"    = "kube-vip-ds"
          "app.kubernetes.io/version" = var.kube_vip_version
        }
      }

      spec {
        host_network         = true
        service_account_name = kubernetes_service_account_v1.kube_vip.metadata[0].name

        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "node-role.kubernetes.io/master"
                  operator = "Exists"
                }
              }
              node_selector_term {
                match_expressions {
                  key      = "node-role.kubernetes.io/control-plane"
                  operator = "Exists"
                }
              }
            }
          }
        }

        toleration {
          effect   = "NoSchedule"
          operator = "Exists"
        }
        toleration {
          effect   = "NoExecute"
          operator = "Exists"
        }

        container {
          name              = "kube-vip"
          image             = "ghcr.io/kube-vip/kube-vip:${var.kube_vip_version}"
          image_pull_policy = "IfNotPresent"
          args              = ["manager"]

          env {
            name  = "vip_arp"
            value = "true"
          }
          env {
            name  = "port"
            value = "6443"
          }
          env {
            name = "vip_nodename"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          # vip_interface omitted by default -> kube-vip auto-detects per
          # node, which handles mixed wired/wireless interface names.
          dynamic "env" {
            for_each = var.kube_vip_interface == null ? [] : [var.kube_vip_interface]
            content {
              name  = "vip_interface"
              value = env.value
            }
          }
          env {
            name  = "vip_subnet"
            value = "32"
          }
          env {
            name  = "cp_enable"
            value = "true"
          }
          env {
            name  = "cp_namespace"
            value = "kube-system"
          }
          env {
            name  = "vip_ddns"
            value = "false"
          }
          env {
            name  = "vip_leaderelection"
            value = "true"
          }
          env {
            name  = "vip_leaseduration"
            value = "5"
          }
          env {
            name  = "vip_renewdeadline"
            value = "3"
          }
          env {
            name  = "vip_retryperiod"
            value = "1"
          }
          env {
            name  = "address"
            value = var.vip
          }

          security_context {
            capabilities {
              add = ["NET_ADMIN", "NET_RAW", "SYS_TIME"]
            }
          }
        }
      }
    }
  }
}
