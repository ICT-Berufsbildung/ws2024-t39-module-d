packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-proxmox
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "win11_iso_checksum" {
  type    = string
  default = "sha256:2a6e701b2b3b31f10fdc8851c07ff1a352c348a7d5711e1010f60b562e87be6e"
}

variable "win11_iso_url" {
  type    = string
}

variable "winsrv_iso_url" {
  type    = string
  default = "https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso"
}

variable "winsrv_iso_checksum" {
  type    = string
  default = "sha256:e215493d331ebd57ea294b2dc96f9f0d025bc97b801add56ef46d8868d810053"
}

source "qemu" "win11-base" {
  accelerator  = "kvm"
  machine_type = "q35"
  cpus         = 2
  memory       = 4096
  qemuargs = [
    ["-cpu", "host"],
    ["-device", "qemu-xhci"],
    ["-device", "virtio-tablet"],
    ["-device", "virtio-scsi-pci,id=scsi0"],
    ["-device", "scsi-hd,bus=scsi0.0,drive=drive0"],
    ["-vga", "qxl"],
    ["-device", "virtio-serial-pci"],
    ["-chardev", "socket,path=/tmp/{{ .Name }}-qga.sock,server,nowait,id=qga0"],
    ["-device", "virtserialport,chardev=qga0,name=org.qemu.guest_agent.0"],
    ["-chardev", "spicevmc,id=spicechannel0,name=vdagent"],
    ["-device", "virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"],
    ["-spice", "unix,addr=/tmp/{{ .Name }}-spice.socket,disable-ticketing"],
  ]
  disk_interface = "virtio-scsi"
  disk_cache     = "unsafe"
  disk_discard   = "unmap"
  disk_size      = "30720"
  floppy_files = [
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
    "scripts/win11/provision-autounattend.ps1",
    "scripts/win11/provision-openssh.ps1",
    "scripts/win11/provision-psremoting.ps1",
    "scripts/win11/provision-pwsh.ps1",
    "scripts/win11/provision-winrm.ps1",
    "scripts/win11/Autounattend.xml",
  ]
  format                   = "qcow2"
  headless                 = true
  net_device               = "e1000"
  http_directory           = "."
  iso_url                  = var.win11_iso_url
  iso_checksum             = var.win11_iso_checksum
  shutdown_command         = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  communicator             = "ssh"
  ssh_username             = "sysop"
  ssh_password             = "Skill39@Lyon"
  ssh_timeout              = "4h"
  ssh_file_transfer_method = "sftp"
}

source "qemu" "winsrv-base" {
  accelerator  = "kvm"
  machine_type = "q35"
  cpus         = 2
  memory       = 4096
  qemuargs = [
    ["-cpu", "host"],
    ["-device", "qemu-xhci"],
    ["-device", "virtio-tablet"],
    ["-device", "virtio-scsi-pci,id=scsi0"],
    ["-device", "scsi-hd,bus=scsi0.0,drive=drive0"],
    ["-vga", "qxl"],
    ["-device", "virtio-serial-pci"],
    ["-chardev", "socket,path=/tmp/{{ .Name }}-qga.sock,server,nowait,id=qga0"],
    ["-device", "virtserialport,chardev=qga0,name=org.qemu.guest_agent.0"],
    ["-chardev", "spicevmc,id=spicechannel0,name=vdagent"],
    ["-device", "virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"],
    ["-spice", "unix,addr=/tmp/{{ .Name }}-spice.socket,disable-ticketing"],
  ]
  disk_interface = "virtio-scsi"
  disk_cache     = "unsafe"
  disk_discard   = "unmap"
  disk_size      = "32G"
  floppy_files = [
    "drivers/NetKVM/2k22/amd64/*.cat",
    "drivers/NetKVM/2k22/amd64/*.inf",
    "drivers/NetKVM/2k22/amd64/*.sys",
    "drivers/qxldod/2k22/amd64/*.cat",
    "drivers/qxldod/2k22/amd64/*.inf",
    "drivers/qxldod/2k22/amd64/*.sys",
    "drivers/vioscsi/2k22/amd64/*.cat",
    "drivers/vioscsi/2k22/amd64/*.inf",
    "drivers/vioscsi/2k22/amd64/*.sys",
    "drivers/vioserial/2k22/amd64/*.cat",
    "drivers/vioserial/2k22/amd64/*.inf",
    "drivers/vioserial/2k22/amd64/*.sys",
    "drivers/viostor/2k22/amd64/*.cat",
    "drivers/viostor/2k22/amd64/*.inf",
    "drivers/viostor/2k22/amd64/*.sys",
    "scripts/win11/provision-autounattend.ps1",
    "scripts/win11/provision-openssh.ps1",
    "scripts/win11/provision-psremoting.ps1",
    "scripts/win11/provision-pwsh.ps1",
    "scripts/win11/provision-winrm.ps1",
    "scripts/winsrv/Autounattend.xml",
  ]
  format                   = "qcow2"
  headless                 = true
  net_device               = "e1000"
  http_directory           = "."
  iso_url                  = var.winsrv_iso_url
  iso_checksum             = var.winsrv_iso_checksum
  shutdown_command         = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  communicator             = "ssh"
  ssh_username             = "sysop"
  ssh_password             = "Skill39@Lyon"
  ssh_timeout              = "4h"
  ssh_file_transfer_method = "sftp"
  vnc_bind_address = "0.0.0.0"
}


build {
  sources = ["source.qemu.win11-base", "source.qemu.winsrv-base"]

  provisioner "powershell" {
    use_pwsh = true
    script   = "scripts/win11/disable-windows-updates.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "scripts/win11/disable-windows-defender.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "scripts/win11/provision-guest-tools-qemu-kvm.ps1"
  }

  provisioner "powershell" {
    only   = ["qemu.win11-base"]
    use_pwsh = true
    script   = "scripts/win11/remove-one-drive.ps1"
  }

  provisioner "powershell" {
    only   = ["qemu.win11-base"]
    use_pwsh = true
    script   = "scripts/win11/remove-apps.ps1"
  }

  provisioner "windows-restart" {
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "scripts/win11/provision.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "scripts/win11/enable-remote-desktop.ps1"
  }

}