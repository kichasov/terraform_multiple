resource "kubernetes_namespace" "testapp" {
  metadata {
    name = "business-app"
  }
}

resource "kubernetes_deployment" "testapp-deploy" {
  depends_on = [kubernetes_namespace.testapp]
  metadata {
    name = "test-app"
    namespace = "business-app"
    labels = {
      app = "testapp"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "testapp"
      }
    }
    template {
      metadata {
        labels = {
          app = "testapp"
        }
      }
      spec {
        container {
          image = "public.ecr.aws/viadee/k8s-demo-app:1.2.0"
          name  = "test-app"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_annotations" "patch_test-app" {
  depends_on = [kubectl_manifest.otel_instrumentation]
  api_version = "apps/v1"
  kind        = "Deployment"
  metadata {
    name = "test-app"
    namespace = "business-app"
  }
  template_annotations = {
    "instrumentation.opentelemetry.io/inject-java" = "true"
  }

  force = true
}
