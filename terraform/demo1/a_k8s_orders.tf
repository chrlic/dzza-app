resource "kubectl_manifest" "orders-deployment" {
    yaml_body = <<YAML
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: orders
  namespace: ${var.common.app_name}
  labels:
    app: ${var.common.app_name}
    x-tech-type: java
spec:
  selector:
    matchLabels:
      app: appd-demo
  replicas: 1
  template:
    metadata:
      labels:
        app: appd-demo
        tier: orders
    spec:
      containers:
      - name: orders
        image: chrlic/orders-ai:latest
        ports:
        - containerPort: 4567
        imagePullPolicy: IfNotPresent
        env:
          - name: APPDYNAMICS_JAVA_AGENT_REUSE_NODE_NAME_PREFIX
            value: "orders"
          - name: APPDYNAMICS_JAVA_AGENT_REUSE_NODE_NAME
            value: "true"
          - name: APPDYNAMICS_NETVIZ_AGENT_HOST
            valueFrom:
              fieldRef:
                fieldPath: status.hostIP
          - name: APPDYNAMICS_NETVIZ_AGENT_PORT
            value: "3892"
          - name: APPDYNAMICS_AGENT_TIER_NAME
            value: "Orders"
          - name: WITH_MONGO
            value: "true"
          - name: STSH_MONGO_HOST
            value: "10.133.30.12"
      imagePullSecrets:
        - name: regcred
YAML
}

resource "kubectl_manifest" "orders-service" {
    yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: orders
  namespace: ${var.common.app_name}
spec:
  selector:
    app: appd-demo
    tier: orders
  ports:
    - protocol: TCP
      port: 8101
      targetPort: 4567
  type: LoadBalancer
YAML
}