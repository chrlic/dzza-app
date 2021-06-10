data "vsphere_datacenter" "dc" {
  name = var.vsphere.dc
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  depends_on = [null_resource.delay]

  name          = format("%v|%v|%v",
    aci_tenant.application_vm_tenant.name,
    aci_application_profile.app_profile.name,
    aci_application_epg.database_epg.name)
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "mysql_template" {
  name          = var.vsphere.mysql_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "mysql_vm" {
  name             = var.vsphere.mysql_vm_name
  folder           = var.vsphere.target_folder
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  firmware         = data.vsphere_virtual_machine.mysql_template.firmware

  num_cpus = 2
  memory   = 2048
  guest_id = data.vsphere_virtual_machine.mysql_template.guest_id

  scsi_type = data.vsphere_virtual_machine.mysql_template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.mysql_template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.mysql_template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.mysql_template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.mysql_template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.mysql_template.id

    customize {
      timeout     = 20
      linux_options {
        host_name = var.vsphere.mysql_vm_name
        domain    = var.vsphere.mysql_vm_domain
      }

      network_interface {
        ipv4_address = format("%v.%v",
          var.vsphere.ip_subnet_prefix,
          var.vsphere.mysql_ip_suffix)
        ipv4_netmask = var.vsphere.ip_subnet_mask
      }

      ipv4_gateway = format("%v.%v",
          var.vsphere.ip_subnet_prefix,
          "1")

    }
  }
}

data "vsphere_virtual_machine" "mongodb_template" {
  name          = var.vsphere.mongodb_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "mongodb_vm" {
  name             = var.vsphere.mongodb_vm_name
  folder           = var.vsphere.target_folder
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  firmware         = data.vsphere_virtual_machine.mongodb_template.firmware

  num_cpus = 2
  memory   = 2048
  guest_id = data.vsphere_virtual_machine.mongodb_template.guest_id

  scsi_type = data.vsphere_virtual_machine.mongodb_template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.mongodb_template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.mongodb_template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.mongodb_template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.mongodb_template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.mongodb_template.id

    customize {
      timeout     = 20
      linux_options {
        host_name = var.vsphere.mongodb_vm_name
        domain    = var.vsphere.mongodb_vm_domain
      }

      network_interface {
        ipv4_address = format("%v.%v",
          var.vsphere.ip_subnet_prefix,
          var.vsphere.mongodb_ip_suffix)
        ipv4_netmask = var.vsphere.ip_subnet_mask
      }

      ipv4_gateway = format("%v.%v",
          var.vsphere.ip_subnet_prefix,
          "1")

    }
  }
}
