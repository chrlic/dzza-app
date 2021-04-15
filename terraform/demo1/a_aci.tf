
resource "aci_tenant" "application_vm_tenant" {
  name        = var.common.app_name  
  description = "Application tenant ${var.common.app_name}"
}

resource "aci_vrf" "vrf_for_demo_app" {
  tenant_dn  = aci_tenant.application_vm_tenant.id
  name       = var.aci.vm_vrf_name
}

resource "aci_bridge_domain" "bd_for_databases" {
  tenant_dn   = aci_tenant.application_vm_tenant.id
  name        = var.aci.vm_bd_name
  relation_fv_rs_ctx = aci_vrf.vrf_for_demo_app.id
  description = "This bridge domain is created by the Terraform ACI provider"
}

resource "aci_subnet" "application_vm_subnet" {
  parent_dn                    = aci_bridge_domain.bd_for_databases.id
  ip                           = var.aci.vm_subnet
  scope                        = "shared"
  description                  = "This subject is created by Terraform v3"
}

resource "aci_application_profile" "app_profile" {
  tenant_dn  = aci_tenant.application_vm_tenant.id
  name       = var.aci.app_profile
}

resource "aci_application_epg" "database_epg" {
  application_profile_dn  = aci_application_profile.app_profile.id
  name                    = var.aci.db_epg
  description             = "EPG for ${var.aci.db_epg}"
  relation_fv_rs_bd       = aci_bridge_domain.bd_for_databases.id
}

resource "aci_epg_to_domain" "vmm_domain_to_epg" {
  application_epg_dn    = aci_application_epg.database_epg.id
  tdn                   = "uni/vmmp-VMware/dom-${var.aci.vmm_domain}"
  vmm_allow_promiscuous = "accept"
  vmm_forged_transmits  = "reject"
  vmm_mac_changes       = "accept"
}

#resource "aci_epg_to_domain" "phys_domain_to_epg" {
#  application_epg_dn    = aci_application_epg.database_epg.id
#  tdn                   = "uni/phys-${var.aci.phys_domain}"
#  vmm_allow_promiscuous = "accept"
#  vmm_forged_transmits  = "reject"
#  vmm_mac_changes       = "accept"
#}

resource "aci_contract" "database_access_to" {
  tenant_dn   = aci_tenant.application_vm_tenant.id
  name        = "database_contract_to"
  scope       = "global"
  filter {
    annotation  = "tag_filter"
    description = "first filter from contract resource"
    filter_entry {
      entry_description   = "mysql"
      filter_entry_name   = "mysql"
      d_from_port         = "3306"
      ether_t             = "ipv4"
      prot                = "tcp"  
    }
    filter_entry {
      entry_description   = "mongodb"
      filter_entry_name   = "mongodb"
      d_from_port         = "27017"
      ether_t             = "ipv4"
      prot                = "tcp"  
    }
    filter_entry {
      entry_description   = "icmp"
      filter_entry_name   = "icmp"
      ether_t             = "ip"
      prot                = "icmp"  
    }
    filter_name  = "database_access"
  }
}

# contract_to ------------------------------------------------------------------------------

resource "aci_contract_subject" "database_access_to" {
  contract_dn   = aci_contract.database_access_to.id
  name          = aci_contract.database_access_to.name
  rev_flt_ports = "yes"
  relation_vz_rs_subj_filt_att = [aci_contract.database_access_to.filter[0].id]
}

resource "aci_epg_to_contract" "database_access_to_provider" {
    application_epg_dn = aci_application_epg.database_epg.id
    contract_dn  = aci_contract.database_access_to.id
    contract_type = "provider"
}

resource "aci_rest" "database_access_contract_to_export" {
  path = "/api/node/mo/uni/tn-${var.aci.k8s_cluster_tenant}/cif-${aci_contract.database_access_to.name}.json"
  payload = <<EOF
  {
    "vzCPIf": {
      "attributes": {
        "dn": "uni/tn-${var.aci.k8s_cluster_tenant}/cif-${aci_contract.database_access_to.name}",
        "name": "${aci_contract.database_access_to.name}",
        "status": "created,modified"
      },
      "children": [
        {
          "vzRsIf": {
            "attributes": {
              "tDn": "uni/tn-${var.common.app_name}/brc-${aci_contract.database_access_to.name}",
              "status": "created,modified"
            },
            "children": []
          }
        }
      ]
    }
  }
EOF
}

resource "aci_rest" "database_access_contract_to_interface_consume" {
  depends_on = [aci_rest.database_access_contract_to_export]

  path = "/api/node/mo/uni/tn-${var.aci.k8s_cluster_tenant}/ap-${var.aci.k8s_cluster_ap}/epg-${var.aci.k8s_cluster_epg}.json"
  payload = <<EOF
{
  "fvRsConsIf": {
    "attributes": {
      "tnVzCPIfName": "${aci_contract.database_access_to.name}",
      "status": "created,modified"
    },
    "children": []
  }
}
EOF
}

# contract_from ------------------------------------------------------------------------------

data "aci_tenant" "k8s_cluster_tenant" {
  name = var.aci.k8s_cluster_tenant
}

data "aci_application_profile" "k8s_cluster_ap" {
  tenant_dn = data.aci_tenant.k8s_cluster_tenant.id
  name = var.aci.k8s_cluster_ap
}

data "aci_application_epg" "k8s_cluster_epg" {
  application_profile_dn = data.aci_application_profile.k8s_cluster_ap.id
  name = var.aci.k8s_cluster_epg
}

resource "aci_contract" "database_access_from" {
  tenant_dn   = data.aci_tenant.k8s_cluster_tenant.id
  name        = "database_contract_from"
  scope       = "global"
  filter {
    annotation  = "tag_filter"
    description = "first filter from contract resource"
    filter_entry {
      entry_description   = "mysql"
      filter_entry_name   = "mysql"
      d_from_port         = "3306"
      ether_t             = "ipv4"
      prot                = "tcp"  
    }
    filter_entry {
      entry_description   = "mongodb"
      filter_entry_name   = "mongodb"
      d_from_port         = "27017"
      ether_t             = "ipv4"
      prot                = "tcp"  
    }
    filter_entry {
      entry_description   = "icmp"
      filter_entry_name   = "icmp"
      ether_t             = "ip"
      prot                = "icmp"  
    }
    filter_name  = "database_access"
  }
}

resource "aci_contract_subject" "database_access_from" {
  contract_dn   = aci_contract.database_access_from.id
  name          = aci_contract.database_access_from.name
  rev_flt_ports = "yes"
  relation_vz_rs_subj_filt_att = [aci_contract.database_access_from.filter[0].id]
}

resource "aci_epg_to_contract" "database_access_from_provider" {
    application_epg_dn = data.aci_application_epg.k8s_cluster_epg.id
    contract_dn  = aci_contract.database_access_from.id
    contract_type = "provider"
}

resource "aci_rest" "database_access_contract_from_export" {
  depends_on = [aci_epg_to_contract.database_access_from_provider]
  path = "/api/node/mo/uni/tn-${var.common.app_name}/cif-${aci_contract.database_access_from.name}.json"
  payload = <<EOF
  {
    "vzCPIf": {
      "attributes": {
        "dn": "uni/tn-${var.common.app_name}/cif-${aci_contract.database_access_from.name}",
        "name": "${aci_contract.database_access_from.name}",
        "status": "created,modified"
      },
      "children": [
        {
          "vzRsIf": {
            "attributes": {
              "tDn": "uni/tn-${var.aci.k8s_cluster_tenant}/brc-${aci_contract.database_access_from.name}",
              "status": "created,modified"
            },
            "children": []
          }
        }
      ]
    }
  }
EOF
}

resource "null_resource" "delay2" {
  depends_on = [aci_epg_to_contract.database_access_from_provider]
  provisioner "local-exec" {
    command = "sleep 5"
  }

  triggers = {
    "epg_db" = aci_rest.database_access_contract_from_export.id
  }
}

resource "aci_rest" "database_access_contract_from_interface_consume" {
  depends_on = [null_resource.delay2]

  path = "/api/node/mo/uni/tn-${var.common.app_name}/ap-${var.aci.app_profile}/epg-${var.aci.db_epg}.json"
  payload = <<EOF
{
  "fvRsConsIf": {
    "attributes": {
      "tnVzCPIfName": "${aci_contract.database_access_from.name}",
      "status": "created,modified"
    },
    "children": []
  }
}
EOF
}

# resource "aci_epg_to_contract" "kubernetes_consumer" {
#    application_epg_dn = aci_application_epg.database_epg.id
#    contract_dn  = aci_contract.database_access.id
#    contract_type = "provider"
# }

resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep 5"
  }

  triggers = {
    "epg_db" = aci_application_epg.database_epg.id
  }
}

# following is a hack - undeploy resources provisioned via ACI REST resource
resource "null_resource" "destroy" {

  triggers = {
    url = var.aci.apic_url
    tenant = var.aci.k8s_cluster_tenant
    ap = var.aci.k8s_cluster_ap
    epg = var.aci.k8s_cluster_epg
    ctrct = aci_contract.database_access_to.name
  }

  provisioner "local-exec" {
    when    = destroy
    command = "./destroy.sh ${self.triggers.url} ${self.triggers.tenant} ${self.triggers.ap}  ${self.triggers.epg} ${self.triggers.ctrct}"
  }
}

