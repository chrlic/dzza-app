resource "kubectl_manifest" "inventory-deployment" {
    yaml_body = <<YAML
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: inventory
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
        tier: inventory
        x-tech-type: java
    spec:
      containers:
      - name: inventory
        image: chrlic/inventory-ai:latest
        ports:
        - containerPort: 4567
        imagePullPolicy: IfNotPresent
        env:
          - name: APPDYNAMICS_JAVA_AGENT_REUSE_NODE_NAME_PREFIX
            value: "inventory"
          - name: APPDYNAMICS_JAVA_AGENT_REUSE_NODE_NAME
            value: "true"
          - name: APPDYNAMICS_NETVIZ_AGENT_HOST
            valueFrom:
              fieldRef:
                fieldPath: status.hostIP
          - name: APPDYNAMICS_NETVIZ_AGENT_PORT
            value: "3892"
          - name: APPDYNAMICS_AGENT_TIER_NAME
            value: "Inventory"
          - name: WITH_MYSQL
            value: "true"
          - name: STSH_MYSQL_HOST
            value: "mysql.${var.common.app_name}.svc.cluster.local"
          - name: STSH_MYSQL_PORT
            value: "3308"
      imagePullSecrets:
        - name: regcred
YAML
}

resource "kubectl_manifest" "inventory-service" {
    yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: inventory
  namespace: ${var.common.app_name}
spec:
  selector:
    app: appd-demo
    tier: inventory
  ports:
    - protocol: TCP
      port: 8100
      targetPort: 4567
  type: LoadBalancer
YAML
}

resource "kubectl_manifest" "mysql-deployment" {
    yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    name: mysql
  name: mysql
  namespace: ${var.common.app_name}
spec:
  selector:
    matchLabels:
      app: appd-demo
  replicas: 1
  template:
    metadata:
      labels:
        app: appd-demo
        tier: mysql
    spec:
      containers:
      - image: chrlic/mysql
        name: mysql
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3306
        env:
          - name: MYSQL_ROOT_PASSWORD
            value: "Passw0rd."
          - name: MYSQL_DATABASE
            value: "Inventory"
          - name: MYSQL_USER
            value: "inventory"
          - name: MYSQL_PASSWORD
            value: "Passw0rd"
      imagePullSecrets:
        - name: regcred
YAML
}

resource "kubectl_manifest" "mysql-service" {
    yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: ${var.common.app_name}
spec:
  selector:
    app: appd-demo
    tier: mysql
  ports:
    - protocol: TCP
      port: 3308
      targetPort: 3306
  type: LoadBalancer
YAML
}