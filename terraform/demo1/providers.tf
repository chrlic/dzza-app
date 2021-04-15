provider "aci" {
  username = data.external.secrets.result.aci_username
  password = data.external.secrets.result.aci_password
  url      = var.aci.apic_url
  insecure = true
}

provider "vsphere" {
  user           = data.external.secrets.result.vsphere_username
  password       = data.external.secrets.result.vsphere_password
  vsphere_server = var.vsphere.server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

provider "kubernetes" {
  config_path = var.k8s.kube_config
}

provider "kubectl" {
  config_path = var.k8s.kube_config
}

