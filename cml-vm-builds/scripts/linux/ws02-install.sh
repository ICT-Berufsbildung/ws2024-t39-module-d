#!/bin/bash
set -euxo pipefail
IFS=$'\n\t'

ifname=$(ip route get 8.8.8.8 | sed -n 's/.*dev \([^\ ]*\).*/\1/p')


groupadd -g 2000 peter
useradd -u 2000 -g peter -d /home/peter -m -s /bin/bash peter
echo 'peter:Skills39' | chpasswd

# Install required packages unattended
export DEBIAN_FRONTEND=noninteractive
apt-get -qqy update
apt-get install -qqy \
  -o DPkg::options::="--force-confdef" \
  -o DPkg::options::="--force-confold" \
  xfce4 \
  xfce4-terminal \
  firefox-esr \
  mousepad

# Enable auto-login on tty1
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat >/etc/systemd/system/getty@tty1.service.d/override.conf <<'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --autologin peter --noclear %I $TERM
EOF

cat >/home/peter/.bash_profile <<'EOF'
startxfce4
EOF
chown peter:peter /home/peter/.bash_profile
chmod +x /home/peter/.bash_profile

# Use multi-user target by default
systemctl set-default multi-user.target

# Configure hostname and hosts
echo 'ws02' >/etc/hostname

cat >/etc/hosts <<'EOF'
127.0.0.1 localhost
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

10.1.64.11 ws02.wsc2024.local ws02
2001:db8:cafe:200::11 ws02.wsc2024.local ws02
EOF

# Disable package repositories
rm -f /etc/apt/sources.list.d/*
cat >/etc/apt/sources.list <<'EOF'
# No package repositories available
EOF

# Use local BIND9 as system resolver
cat >/etc/resolv.conf <<'EOF'
domain wsc2024.local
nameserver 10.1.64.20
nameserver 2001:db8:cafe:200::20
EOF

# Disable delay after incorrect PAM authentication
sed -i '/pam_unix.so/ s/$/ nodelay/g' /etc/pam.d/common-auth

# Deploy network interface configuration
cat >/etc/network/interfaces <<EOF
# Loopback
auto lo
iface lo inet loopback

# Primary
auto $ifname
iface $ifname inet dhcp

iface $ifname inet6 auto
EOF
