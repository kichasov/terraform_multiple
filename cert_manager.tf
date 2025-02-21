resource "helm_release" "cert-manager" {
  name = "cert-manager"

  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  # version          = "1.17.0"
  set {
    name  = "prometheus.enabled"
    value = "true"
  }
  set {
    name  = "crds.enabled"
    value = "true"
  }
}
