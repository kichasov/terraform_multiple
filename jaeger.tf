data "kubernetes_secret" "cassandra_creds" {
  depends_on = [kubectl_manifest.cassandra_db]
  metadata {
    name      = "cassandra-superuser"
    namespace = "cassandra"
  }
}

resource "helm_release" "jaeger" {
  name             = "jaeger"
  repository       = "https://ildarminaev.github.io/jaeget-helm-test"
  chart            = "qubership-jaeger"
  namespace        = "jaeger"
  create_namespace = true
  depends_on       = [kubectl_manifest.cassandra_db]
  timeout          = "900"
  set {
    name  = "CASSANDRA_SVC"
    value = "cassandra-dc1-service.cassandra.svc.cluster.local"
  }
  set {
    name  = "jaeger.prometheusMonitoringDashboard"
    value = "false"
  }
  set {
    name  = "jaeger.prometheusMonitoring"
    value = "false"
  }
  set {
    name  = "query.ingress.install"
    value = "true"
  }
  set {
    name  = "query.ingress.host"
    value = "query.jaeger.k8s.home"
  }
  set {
    name  = "cassandraSchemaJob.host"
    value = "cassandra-dc1-service.cassandra.svc.cluster.local"
  }
  set {
    name  = "cassandraSchemaJob.username"
    value = data.kubernetes_secret.cassandra_creds.data["username"]
  }
  set {
    name  = "cassandraSchemaJob.password"
    value = data.kubernetes_secret.cassandra_creds.data["password"]
  }
  set {
    name  = "cassandraSchemaJob.datacenter"
    value = "dc1"
  }
  set {
    name  = "readinessProbe.resources.limits.memory"
    value = "200Mi"
  }
  set {
    name  = "readinessProbe.resources.limits.cpu"
    value = "200m"
  }
  set {
    name  = "readinessProbe.resources.requests.memory"
    value = "100Mi"
  }
  set {
    name  = "readinessProbe.resources.requests.cpu"
    value = "100m"
  }
}
