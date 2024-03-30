# WorldSkills Competition 2024 - Module D Troubleshooting
This repository contains all the necessary artifacts to build the module D troubleshooting test project for the WorldSkills competition 2024 in Lyon.

## Build VM image
### Prequisites
* Packer
* KVM host

### Build
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
```