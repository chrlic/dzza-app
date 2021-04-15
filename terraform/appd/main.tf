data "external" "secrets" {
  program  = [ "cat", "secrets.json"]
}

locals {
  namespace = "appdynamics"
}

resource "kubernetes_namespace" "appdynamics" {
  metadata {
    name = local.namespace
  }
}

resource "null_resource" "cluster-agent-operator" {
  depends_on = [kubernetes_namespace.appdynamics]

  provisioner "local-exec" {
    command = "kubectl apply --kubeconfig=${data.external.secrets.result.kubeconfig} -f cluster-agent-operator.yaml"
  }
}

resource "kubectl_manifest" "cluster-agent-secret" {
    depends_on = [kubernetes_namespace.appdynamics]
    yaml_body = <<YAML
apiVersion: v1
data:
  controller-key: "${base64encode(data.external.secrets.result.access_key)}"
kind: Secret
metadata:
  name: cluster-agent-secret
  namespace: appdynamics
type: Opaque
YAML
}

resource "kubectl_manifest" "cluster-agent" {
    depends_on = [kubernetes_namespace.appdynamics, null_resource.cluster-agent-operator]
    yaml_body = <<YAML
apiVersion: appdynamics.com/v1alpha1
kind: Clusteragent
metadata:
  name: appdynamics-cluster-agent
  namespace: appdynamics
spec:
  appName: "dzza-ccp-wrk-800-a"
  controllerUrl: "${data.external.secrets.result.controller}"
  proxyUrl: "http://proxy.esl.cisco.com:80"
  account: "${data.external.secrets.result.account}"
  image: "docker.io/appdynamics/cluster-agent:21.2.0"
  serviceAccountName: appdynamics-cluster-agent
  logLevel: DEBUG
  nsToMonitorRegex: .*
  instrumentationMethod: Env
  defaultEnv: JAVA_TOOL_OPTIONS
  nsToInstrumentRegex: .*
  appNameStrategy: label
  appNameLabel: appname
  defaultAppName: DefaultApplication
  instrumentationRules:
    - namespaceRegex: .*
      appNameLabel: app
      labelMatch:
      - x-tech-type: java
      language: java
      env: JAVA_TOOL_OPTIONS
      imageInfo:
        image: "docker.io/appdynamics/java-agent:latest"
        agentMountPath: /opt/appdynamics
        imagePullPolicy: "IfNotPresent"
    - namespaceRegex: .*
      appNameLabel: app
      labelMatch:
      - x-tech-type: dotnetcore
      language: dotnetcore
      imageInfo:
        image: "docker.io/appdynamics/dotnet-core-agent:20.9.0-linux"
        agentMountPath: /opt/appdynamics
        imagePullPolicy: "IfNotPresent"
    - namespaceRegex: .*
      appNameLabel: app
      labelMatch:
      - x-tech-type: nodejs
      language: nodejs
      imageInfo:
        image: "docker.io/appdynamics/nodejs-agent:latest"
        agentMountPath: /opt/appdynamics
        imagePullPolicy: "IfNotPresent"
  defaultInstrumentationTech: java
  resources: {}
  resourcesToInstrument:
    - Deployment
  clusterMetricsSyncInterval: 60
  imageInfo:
    dotnetcore:
      agentMountPath: /opt/appdynamics
      image: 'docker.io/appdynamics/dotnet-core-agent:20.9.0-linux'
      imagePullPolicy: IfNotPresent
    java:
      agentMountPath: /opt/appdynamics
      image: 'docker.io/appdynamics/java-agent:latest'
      imagePullPolicy: IfNotPresent
    nodejs:
      agentMountPath: /opt/appdynamics
      image: 'docker.io/appdynamics/nodejs-agent:latest'
      imagePullPolicy: IfNotPresent
YAML
}

