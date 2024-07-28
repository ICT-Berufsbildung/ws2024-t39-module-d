packer {
  required_plugins {
    vsphere = {
      version = "~> 1"
      source  = "github.com/hashicorp/vsphere"
    }
  }
}

variable "esx_host" {
  type    = string
  default = "esx1.homenet.local"
}

variable "esx_username" {
  type    = string
  default = "root"
}

variable "esx_password" {
  type    = string
}

variable "esx_datastore" {
  type    = string
  default = "datastor3_512GB"
}

variable "esx_iso_datastore" {
  type    = string
  default = "datastore2_1TB"
}

variable "esx_vm_network" {
  type    = string
  default = "VM Network"
}

source "vsphere-iso" "base" {
  CPUs         = 2
  RAM          = 2048
  boot_command = [
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed-sc.cfg interface=ens192<wait>", "<enter><wait>"
  ]
  disk_controller_type = ["pvscsi"]
  guest_os_type        = "debian11_64Guest"
  host                 = var.esx_host
  datastore            = var.esx_datastore
  insecure_connection  = true
  cdrom_type           = "sata"
  iso_paths            = [
    "[${var.esx_iso_datastore}] ISO/debian-12.5.0-amd64-netinst.iso"
  ]
  password             = var.esx_password
  ssh_password         = "AllTooWell13"
  ssh_username         = "sysop"
  storage {
    disk_size             = 32768
    disk_thin_provisioned = true
  }
  username       = "root"
  vcenter_server = var.esx_host
  http_directory = "http"
  http_port_min  = 5100
  http_port_max  = 5150

}

# Servicedesk
build {
  name = "Servicedesk"
  sources = ["source.vsphere-iso.base"]
  source "source.vsphere-iso.base" {
    vm_name = "Servicedesk"
    network_adapters {
      network_card = "vmxnet3"
      network = var.esx_vm_network
    }
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; echo 'AllTooWell13' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    script = "./scripts/linux/servicedesk-install.sh"
  }

}