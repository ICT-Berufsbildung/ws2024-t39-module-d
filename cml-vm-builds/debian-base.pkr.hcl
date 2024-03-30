packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "debian-base" {
  vm_name = "wsc2024-base"

  iso_url = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
  iso_checksum = "sha256:013f5b44670d81280b5b1bc02455842b250df2f0c6763398feb69af1a805a14f"

  disk_size = "5G"
  format = "qcow2"
  accelerator = "kvm"
  net_device        = "virtio-net"
  disk_interface    = "virtio"

  memory = "4096"
  cpus = 2

  headless = false
  http_directory = "http"
  ssh_username = "sysop"
  ssh_password = "Skills39"
  ssh_timeout = "15m"
  boot_command = [
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<enter>",
  ]
  shutdown_command = "sudo -S /sbin/shutdown -h now"
}


build {
  sources = ["source.qemu.debian-base"]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; echo 'Skills39' | sudo -S {{ .Path }}"
    script = "./scripts/linux/debian-base-install.sh"
  }
}