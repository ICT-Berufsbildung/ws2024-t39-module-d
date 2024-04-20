#!/bin/bash
set -euxo pipefail
IFS=$'\n\t'

# Configure sudo
cat >/etc/sudoers <<'EOF'
Defaults env_reset
Defaults mail_badpass
Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

root ALL=(ALL:ALL) ALL
%sudo ALL=(ALL:ALL) NOPASSWD: ALL
EOF

systemctl enable serial-getty@ttyS0.service
systemctl start serial-getty@ttyS0.service

# Enable graphical boot via plymouth
cat >/etc/default/grub <<'EOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR=`lsb_release -i -s 2>/dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX="console=ttyS0"
EOF
update-grub

# Install required packages unattended
export DEBIAN_FRONTEND=noninteractive
apt-get -qqy update
apt-get install -qqy \
  -o DPkg::options::="--force-confdef" \
  -o DPkg::options::="--force-confold" \
  ca-certificates \
  console-data \
  curl \
  dnsutils \
  ftp \
  netcat-openbsd \
  smbclient \
  sshpass \
  vim

cat >/etc/ssh/ssh_config.d/ios_ciphers.conf <<EOF
Host *
        HostkeyAlgorithms ssh-dss,ssh-rsa,rsa-sha2-512,rsa-sha2-256,ecdsa-sha2-nistp256,ssh-ed25519
        KexAlgorithms +diffie-hellman-group1-sha1,diffie-hellman-group14-sha1
EOF