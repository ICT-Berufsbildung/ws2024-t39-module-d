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

source "qemu" "win11-base" {
  cpus             = "4"
  memory            = "8192"
  efi_boot = true
  efi_config {
    efi_storage_pool = "local-lvm"
  }
  vga {
    type   = "qxl"
    memory = 32
  }
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }
  scsi_controller = "virtio-scsi-single"
  disks {
    format        = "raw"
    type         = "scsi"
    io_thread    = true
    ssd          = true
    discard      = true
    disk_size    = "61440M"
    storage_pool = "local-lvm"
  }
  unmount_iso      = true
  additional_iso_files {
    device           = "ide0"
    unmount          = true
    iso_storage_pool = "local"
    cd_label         = "PROVISION"
    cd_files = [
      "./scripts/Autounattend.xml", 
      "drivers/NetKVM/w11/amd64/*.cat",
      "drivers/NetKVM/w11/amd64/*.inf",
      "drivers/NetKVM/w11/amd64/*.sys",
      "drivers/qxldod/w11/amd64/*.cat",
      "drivers/qxldod/w11/amd64/*.inf",
      "drivers/qxldod/w11/amd64/*.sys",
      "drivers/vioscsi/w11/amd64/*.cat",
      "drivers/vioscsi/w11/amd64/*.inf",
      "drivers/vioscsi/w11/amd64/*.sys",
      "drivers/vioserial/w11/amd64/*.cat",
      "drivers/vioserial/w11/amd64/*.inf",
      "drivers/vioserial/w11/amd64/*.sys",
      "drivers/viostor/w11/amd64/*.cat",
      "drivers/viostor/w11/amd64/*.inf",
      "drivers/viostor/w11/amd64/*.sys",
      "drivers/virtio-win-guest-tools.exe",
      "scripts/provision-autounattend.ps1",
      "scripts/provision-guest-tools-qemu-kvm.ps1",
      "scripts/provision-openssh.ps1",
      "scripts/provision-psremoting.ps1",
      "scripts/provision-pwsh.ps1",
      "scripts/provision-winrm.ps1",
    ]
  }
  os     = "win11"
  http_directory    = "httpdir"
  iso_checksum      = "${var.iso_checksum}"
  iso_file           = "${var.iso_url}"
  ssh_password = "Go4Regio24"
  ssh_timeout  = "1h"
  ssh_username = "regio"
  boot_wait         = "1s"
  boot_command   = ["<up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait><up><wait>"]
}

build {
  sources = ["source.qemu.debian-base"]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; echo 'Skills39' | sudo -S {{ .Path }}"
    script = "./scripts/linux/debian-base-install.sh"
  }
}