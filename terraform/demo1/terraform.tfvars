common = {
  app_name = "dzza-test-app1"
  }

aci = {
  apic_url = "https://192.168.130.10/"

  vmm_domain = "DZZA_switch"
  phys_domain = "Event_HX"
  vm_bd_name = "vm"
  vm_vrf_name = "vm"
  vm_subnet = "10.133.30.1/24"
  db_epg = "databases"
  app_profile = "DZZA_demo_app"

  k8s_cluster_tenant = "CCC-MD"
  k8s_cluster_ap = "CCC50"
  k8s_cluster_epg = "CCC-MGMT"
  }

vsphere = {
  server = "192.168.180.50"

  dc = "DCEvent"
  datastore = "Event_Datastore1"
  cluster = "HXevent"

  ip_subnet_prefix = "10.133.30"
  ip_subnet_mask = 24
  target_folder = "DZZA/VMs"
  mysql_template = "CentOS8-MySQL-Template"
  mysql_vm_name = "MySQL"
  mysql_vm_domain = "dzza.demo.local"
  mysql_ip_suffix = "11"
  mongodb_template = "CentOS8-MongoDB-Template"
  mongodb_vm_name = "MongoDB"
  mongodb_ip_suffix = "12"
  mongodb_vm_domain = "dzza.demo.local"
  
  }

k8s = {
  kube_config = "~/aaa-800-cali-a-kubeconfig.yaml"
  }


