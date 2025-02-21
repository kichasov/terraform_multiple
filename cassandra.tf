resource "helm_release" "cassandra-operator" {
  name = "cassandra"
  repository       = "https://helm.k8ssandra.io"
  chart            = "k8ssandra-operator"
  namespace        = "cassandra"
  create_namespace = true
  # version          = "1.21.1"
  depends_on = [helm_release.cert-manager]
}

resource "time_sleep" "wait_cassandra_operator_to_settle" {
  depends_on      = [helm_release.cassandra-operator]
  create_duration = "5s"
}

resource "kubectl_manifest" "cassandra_db" {
  depends_on      = [time_sleep.wait_cassandra_operator_to_settle]
  yaml_body = <<YAML
apiVersion: k8ssandra.io/v1alpha1
kind: K8ssandraCluster
metadata:
  name: cassandra
  namespace: cassandra
spec:
  cassandra:
    serverVersion: "4.0.1"
    datacenters:
      - metadata:
          name: dc1
        size: 1
        storageConfig:
          cassandraDataVolumeClaimSpec:
            storageClassName: local-path
            accessModes:
              - ReadWriteOnce
            resources:
              requests:
                storage: 5Gi
        config:
          jvmOptions:
            heapSize: 2048M
YAML
  wait_for {
    condition {
    type   = "CassandraInitialized"
    status = "True"
    }
  }
}
