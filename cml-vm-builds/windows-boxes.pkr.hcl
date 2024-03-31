packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-proxmox
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}


source "qemu" "dc01" {
  vm_name = "wsc2024-mod-d-dc01.qcow2"
  accelerator  = "kvm"
  machine_type = "q35"
  cpus         = 4
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
  format                   = "qcow2"
  headless                 = false
  net_device               = "e1000"
  http_directory           = "http"
  iso_url                  = "output-winsrv-base/packer-winsrv-base"
  iso_checksum             = "none"
  disk_image = true

  shutdown_command         = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  communicator             = "ssh"
  ssh_username             = "sysop"
  ssh_password             = "Skills39"
  ssh_timeout              = "4h"
  ssh_file_transfer_method = "sftp"
}

source "qemu" "ws01" {
  vm_name = "wsc2024-mod-d-ws01.qcow2"
  accelerator  = "kvm"
  machine_type = "q35"
  cpus         = 4
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
  format                   = "qcow2"
  headless                 = false
  net_device               = "e1000"
  http_directory           = "http"
  iso_url                  = "output-win11-base/packer-win11-base"
  iso_checksum             = "none"
  disk_image = true

  shutdown_command         = "shutdown /s /t 0 /f /d p:4:1 /c \"Packer Shutdown\""
  communicator             = "ssh"
  ssh_username             = "sysop"
  ssh_password             = "Skills39"
  ssh_timeout              = "4h"
  ssh_file_transfer_method = "sftp"
}

build {
  sources = ["source.qemu.dc01", "source.qemu.ws01"]

  provisioner "powershell" {
    only   = ["qemu.dc01"]
    use_pwsh = true
    inline = ["Rename-Computer -NewName dc01"]
  }

  provisioner "windows-restart" {
    only   = ["qemu.dc01"]
  }

  provisioner "powershell" {
    only   = ["qemu.dc01"]
    use_pwsh = true
    script   = "scripts/winsrv/install-roles-dc01.ps1"
  }

  provisioner "windows-restart" {
    only   = ["qemu.dc01"]
  }


  provisioner "powershell" {
    only   = ["qemu.dc01"]
    use_pwsh = true
    script   = "scripts/winsrv/provision-dc01.ps1"
  }

  provisioner "powershell" {
    only   = ["qemu.dc01"]
    script   = "scripts/winsrv/provision-static-ip.ps1"
  }

  provisioner "powershell" {
    only   = ["qemu.ws01"]
    script   = "scripts/win11/provision-ws01.ps1"
  }

}