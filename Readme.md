# WorldSkills Competition 2024 - Module D Troubleshooting
This repository contains all the necessary artifacts to build the module D troubleshooting test project for the WorldSkills competition 2024 in Lyon.

## Build VM image
### Prequisites
* Packer
* KVM host

### Build
1. Create new file named `wsc2024.pkrvars.hcl` and specify the file path of the ISOs
```
win11_iso_url = "/path/to/ISOs/windows11-enterprise.iso"
winsrv_iso_url = "/path/to/ISOs/en-us_windows_server_2022_updated_july_2023_x64_dvd_541692c3.iso"
```
2. Build images
```shell
cd cml-vm-builds
wget -P drivers.tmp https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.240-1/virtio-win-0.1.240.iso
7z x -odrivers.tmp drivers.tmp/virtio-win-*.iso
mv drivers.tmp drivers

packer init debian-base.pkr.hcl
# Build Debian base image
packer build debian-base.pkr.hcl
# Build all debian VMs in parallel
packer build debian-boxes.pkr.hcl
# Build all base Windows images
packer build -var-file=wsc2024.pkrvars.hcl windows-base.pkr.hcl
# Build all Windows images in parallel
packer build windows-boxes.pkr.hcl
```
3. The VMs will be stored as qcow2 format and are in separate folder with the prefix `output-`
