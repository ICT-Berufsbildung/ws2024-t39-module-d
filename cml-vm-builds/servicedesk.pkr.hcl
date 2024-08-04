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
  CPUs         = 4
  RAM          = 8192
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
  export {
      output_format = "ova"
      output_directory = "./outputs"
  }
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
  sources = ["source.vsphere-iso.base"]
  source "source.vsphere-iso.base" {
    name = "prod"
    vm_name = "wsc2024-mod-d-helpdesk"
    network_adapters {
      network_card = "vmxnet3"
      network = var.esx_vm_network
    }
  }

  source "source.vsphere-iso.base" {
    name = "familiarization"
    vm_name = "wsc2024-mod-d-helpdesk-familiarization"
    network_adapters {
      network_card = "vmxnet3"
      network = var.esx_vm_network
    }
  }

  provisioner "file" {
    sources = [
      "./http/Agents.php",
      "./http/users.csv",
      "./http/saved_reply.sql",
      "./http/SavedRepliesHomepage.php",
      "./http/SavedRepliesPanel.php",
      "./http/SavedRepliesSearch.php",
      "./http/SavedReplies.php",
      "./scripts/linux/uvdesk-import.py"
    ]
    destination = "/tmp/"
  }

  provisioner "file" {
    only   = ["vsphere-iso.prod"]
    source = "./http/tickets_prod.csv"
    destination = "/tmp/tickets.csv"
  }

  provisioner "file" {
    only   = ["vsphere-iso.familiarization"]
    source = "./http/tickets_familiarization.csv"
    destination = "/tmp/tickets.csv"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; echo 'AllTooWell13' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    script = "./scripts/linux/servicedesk-install.sh"
  }

}