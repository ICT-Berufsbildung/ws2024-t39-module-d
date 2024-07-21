packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "lnx01-solved" {
  vm_name = "wsc2024-mod-d-lnx01-solved.qcow2"

  iso_url = "output-debian-base/wsc2024-base"
  iso_checksum = "none"
  disk_image = true

  format = "qcow2"
  accelerator = "kvm"
  net_device        = "virtio-net"
  disk_interface    = "virtio"

  memory = "2048"
  cpus = 2

  headless = true
  http_directory = "http"
  ssh_username = "sysop"
  ssh_password = "Skill39@Lyon"
  ssh_timeout = "15m"
  shutdown_command = "sudo -S /sbin/shutdown -h now"
}

source "qemu" "lnx02-solved" {
  vm_name = "wsc2024-mod-d-lnx02-solved.qcow2"

  iso_url = "output-debian-base/wsc2024-base"
  iso_checksum = "none"
  disk_image = true

  format = "qcow2"
  accelerator = "kvm"
  net_device        = "virtio-net"
  disk_interface    = "virtio"

  memory = "2048"
  cpus = 2

  headless = true
  http_directory = "http"
  ssh_username = "sysop"
  ssh_password = "Skill39@Lyon"
  ssh_timeout = "15m"
  shutdown_command = "sudo -S /sbin/shutdown -h now"
}
source "qemu" "lnx03-solved" {
  vm_name = "wsc2024-mod-d-lnx03-solved.qcow2"

  iso_url = "output-debian-base/wsc2024-base"
  iso_checksum = "none"
  disk_image = true

  format = "qcow2"
  accelerator = "kvm"
  net_device        = "virtio-net"
  disk_interface    = "virtio"

  memory = "2048"
  cpus = 2

  headless = true
  http_directory = "http"
  ssh_username = "sysop"
  ssh_password = "Skill39@Lyon"
  ssh_timeout = "15m"
  shutdown_command = "sudo -S /sbin/shutdown -h now"
}

source "qemu" "partner01" {
  vm_name = "wsc2024-mod-d-partner01.qcow2"

  iso_url = "output-debian-base/wsc2024-base"
  iso_checksum = "none"
  disk_image = true

  format = "qcow2"
  accelerator = "kvm"
  net_device        = "virtio-net"
  disk_interface    = "virtio"

  memory = "2048"
  cpus = 2

  headless = true
  http_directory = "http"
  ssh_username = "sysop"
  ssh_password = "Skill39@Lyon"
  ssh_timeout = "15m"
  shutdown_command = "sudo -S /sbin/shutdown -h now"
}

source "qemu" "ws02" {
  vm_name = "wsc2024-mod-d-ws02.qcow2"

  iso_url = "output-debian-base/wsc2024-base"
  iso_checksum = "none"
  disk_image = true

  format = "qcow2"
  accelerator = "kvm"
  net_device        = "virtio-net"
  disk_interface    = "virtio"

  memory = "2048"
  cpus = 2

  headless = true
  http_directory = "http"
  ssh_username = "sysop"
  ssh_password = "Skill39@Lyon"
  ssh_timeout = "15m"
  shutdown_command = "sudo -S /sbin/shutdown -h now"
}

build {
  sources = ["source.qemu.lnx01-solved", "source.qemu.lnx02-solved", "source.qemu.lnx03-solved", "source.qemu.ws02", "source.qemu.partner01"]

  provisioner "file" {
    only   = ["qemu.lnx01-solved", "qemu.lnx03-solved"]
    source = "./scripts/linux/wwwroot"
    destination = "/tmp"
  }

  provisioner "shell" {
    only   = ["qemu.lnx01-solved"]
    execute_command = "chmod +x {{ .Path }}; sudo -E -S {{ .Path }}"
    script = "./scripts/linux/lnx01-clean-install.sh"
  }

  provisioner "shell" {
    only   = ["qemu.lnx02-solved"]
    execute_command = "chmod +x {{ .Path }}; sudo -E -S {{ .Path }}"
    script = "./scripts/linux/lnx02-clean-install.sh"
  }

  provisioner "shell" {
    only   = ["qemu.lnx03-solved"]
    execute_command = "chmod +x {{ .Path }}; sudo -E -S {{ .Path }}"
    script = "./scripts/linux/lnx03-clean-install.sh"
  }

  provisioner "shell" {
    only   = ["qemu.ws02"]
    execute_command = "chmod +x {{ .Path }}; sudo -E -S {{ .Path }}"
    script = "./scripts/linux/ws02-install.sh"
  }

  provisioner "shell" {
    only   = ["qemu.partner01"]
    execute_command = "chmod +x {{ .Path }}; sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    script = "./scripts/linux/partner01-install.sh"
  }

}