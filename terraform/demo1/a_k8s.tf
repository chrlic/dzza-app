resource "kubernetes_namespace" "demo" {
  metadata {
    name = var.common.app_name
  }
}