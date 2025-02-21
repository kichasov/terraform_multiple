resource "helm_release" "open-telemetry" {
  name             = "open-telemetry"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-operator"
  namespace        = "opentelemetry"
  create_namespace = true
  depends_on       = [helm_release.cert-manager]
  set {
    name  = "manager.collectorImage.repository"
    value = "otel/opentelemetry-collector-contrib"
  }
  set {
    name  = "manager.extraArgs"
    value = "{--enable-go-instrumentation=true,--enable-nginx-instrumentation=true}"
  }
}

resource "kubectl_manifest" "otel_collector" {
  depends_on = [helm_release.open-telemetry]
  yaml_body = <<YAML
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector
  namespace: business-app
spec:
  config:
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
    processors:
      memory_limiter:
        check_interval: 1s
        limit_percentage: 75
        spike_limit_percentage: 15
      batch:
        send_batch_size: 10000
        timeout: 10s
    exporters:
      debug: {}
      otlp:
        endpoint: "jaeger-collector.jaeger.svc.cluster.local:4317"
        tls:
          insecure: true
      prometheus:
        endpoint: "0.0.0.0:8889"
      prometheusremotewrite:
        endpoint: "http://vmsingle-k8s-vmsingle.monitoring.svc.cluster.local:8429/api/v1/write"
        tls:
          insecure: true
        headers:
          Content-Type: application/x-protobuf
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [debug, otlp]
        metrics:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [prometheusremotewrite, debug]
YAML
}

resource "kubectl_manifest" "otel_instrumentation" {
  depends_on = [kubectl_manifest.otel_collector]
  yaml_body = <<YAML
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: otel-instrumentation
  namespace: business-app
spec:
  exporter:
    endpoint: http://otel-collector-collector:4317
  propagators:
    - tracecontext
    - baggage
    - b3
  sampler:
    type: parentbased_traceidratio
    argument: "1.0"
YAML
}
