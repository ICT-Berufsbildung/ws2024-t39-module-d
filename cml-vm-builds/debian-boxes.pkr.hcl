packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "lnx01" {
  vm_name = "wsc2024-mod-d-lnx01.qcow2"

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
  ssh_password = "Skills39"
  ssh_timeout = "15m"
  shutdown_command = "sudo -S /sbin/shutdown -h now"
}

source "qemu" "lnx02" {
  vm_name = "wsc2024-mod-d-lnx02.qcow2"

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
  ssh_password = "Skills39"
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
  ssh_password = "Skills39"
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
  ssh_password = "Skills39"
  ssh_timeout = "15m"
  shutdown_command = "sudo -S /sbin/shutdown -h now"
}

build {
  sources = ["source.qemu.lnx01", "source.qemu.lnx02", "source.qemu.ws02", "source.qemu.partner01"]

  provisioner "shell" {
    only   = ["qemu.lnx01"]
    execute_command = "chmod +x {{ .Path }}; sudo -E -S {{ .Path }}"
    script = "./scripts/linux/lnx01-install.sh"
  }

  provisioner "shell" {
    only   = ["qemu.lnx02"]
    execute_command = "chmod +x {{ .Path }}; sudo -E -S {{ .Path }}"
    script = "./scripts/linux/lnx02-install.sh"
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