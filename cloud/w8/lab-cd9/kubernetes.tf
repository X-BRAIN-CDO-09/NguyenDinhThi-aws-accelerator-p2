# ==============================================================================
# LAB CD9 - Kubernetes Resources Configuration
# Su dung Kubernetes Provider de deploy ung dung trực tiep bang HCL cua Terraform
# ==============================================================================

# 1. Khoi tao K8s Namespace
resource "kubernetes_namespace_v1" "web" {
  metadata {
    name = "lab-cd9"
  }

  depends_on = [null_resource.wait_for_minikube]
}

# 2. ConfigMap chua noi dung trang HTML tuy chinh (thay the trang Nginx mac dinh)
resource "kubernetes_config_map_v1" "web_html" {
  metadata {
    name      = "web-html"
    namespace = kubernetes_namespace_v1.web.metadata[0].name
  }

  # Doc noi dung file index.html tu thu muc scripts/ va nhung vao ConfigMap
  data = {
    "index.html" = file("${path.module}/scripts/index.html")
  }

  depends_on = [kubernetes_namespace_v1.web]
}

# 3. Khoi tao K8s Deployment cho Nginx + mount HTML tuy chinh
resource "kubernetes_deployment_v1" "web" {
  metadata {
    name      = "web-app"
    namespace = kubernetes_namespace_v1.web.metadata[0].name
    labels = {
      app = "web-app"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "web-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "web-app"
        }
        annotations = {
          "configmap-hash" = sha256(file("${path.module}/scripts/index.html"))
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:alpine"

          port {
            container_port = 80
          }

          # Mount ConfigMap vao thu muc html cua Nginx de hien thi trang tuy chinh
          volume_mount {
            name       = "html-volume"
            mount_path = "/usr/share/nginx/html"
            read_only  = true
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }

        # Khai bao Volume tu ConfigMap
        volume {
          name = "html-volume"
          config_map {
            name = kubernetes_config_map_v1.web_html.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_config_map_v1.web_html]
}

# 4. Expose ung dung qua K8s Service NodePort
resource "kubernetes_service_v1" "web" {
  metadata {
    name      = "web-service"
    namespace = kubernetes_namespace_v1.web.metadata[0].name
  }

  spec {
    type = "NodePort"

    selector = {
      app = "web-app"
    }

    port {
      port        = 80
      target_port = 80
      node_port   = var.app_port # 30080
    }
  }

  depends_on = [kubernetes_deployment_v1.web]
}
