resource "kubernetes_namespace" "argocd_ns" {
  metadata {
    name = "infra-tools"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.46.7"
  namespace  = kubernetes_namespace.argocd_ns.metadata[0].name

  values = [
    file("${path.module}/values/argocd-values.yaml")
  ]
}
