resource "kubectl_manifest" "restapi-deployment" {
    yaml_body = <<YAML
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: restapi
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
        tier: restapi
    spec:
      containers:
      - name: restapi
        image: chrlic/restapi-ai:latest
        ports:
        - containerPort: 4567
        imagePullPolicy: IfNotPresent
        env:
          - name: APPDYNAMICS_JAVA_AGENT_REUSE_NODE_NAME_PREFIX
            value: "restapi"
          - name: APPDYNAMICS_JAVA_AGENT_REUSE_NODE_NAME
            value: "true"
          - name: APPDYNAMICS_NETVIZ_AGENT_HOST
            valueFrom:
              fieldRef:
                fieldPath: status.hostIP
          - name: APPDYNAMICS_NETVIZ_AGENT_PORT
            value: "3892"
          - name: APPDYNAMICS_AGENT_TIER_NAME
            value: "RestAPI"
          - name: STSH_ORDERS_HOST
            value: "orders.${var.common.app_name}.svc.cluster.local"
          - name: STSH_ORDERS_PORT
            value: "8101"
          - name: STSH_INVENTORY_HOST
            value: "inventory.${var.common.app_name}.svc.cluster.local"
          - name: STSH_INVENTORY_PORT
            value: "8100"
      imagePullSecrets:
        - name: regcred
YAML
}

resource "kubectl_manifest" "restapi-service" {
    yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: restapi-service
  namespace: ${var.common.app_name}
spec:
  selector:
    app: appd-demo
    tier: restapi
  ports:
    - protocol: TCP
      port: 8099
      targetPort: 4567
  type: LoadBalancer
YAML
}