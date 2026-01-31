resource "kubernetes_priority_class_v1" "priority_class_critical" {
  metadata {
    name = var.priority_class
  }

  value          = 900000000
  global_default = false
  description    = "Critical infrastructure pods"
}