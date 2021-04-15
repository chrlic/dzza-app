
provider "kubernetes" {
  config_path = data.external.secrets.result.kubeconfig
}

provider "kubectl" {
  config_path = data.external.secrets.result.kubeconfig
}

