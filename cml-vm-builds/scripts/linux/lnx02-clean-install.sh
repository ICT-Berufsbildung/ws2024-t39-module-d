#!/bin/bash
set -euxo pipefail
IFS=$'\n\t'

ifname=$(ip route get 8.8.8.8 | sed -n 's/.*dev \([^\ ]*\).*/\1/p')

# Configure hostname and hosts
echo 'lnx02' >/etc/hostname

cat >/etc/hosts <<'EOF'
127.0.0.1 localhost
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

10.1.64.11 lnx02.wsc2024.org lnx02
2001:db8:cafe:200::11 lnx02.wsc2024.org lnx02
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

# Increase boot timeout
sed -Ei 's/#?\s*(GRUB_TIMEOUT).*$/\1=60/g' /etc/default/grub
update-grub

# Deploy network interface configuration
cat >/etc/network/interfaces <<EOF
# Loopback
auto lo
iface lo inet loopback

# Primary
auto $ifname
iface $ifname inet static
  address 10.1.64.11
  netmask 255.255.255.0
  gateway 10.1.64.1

iface $ifname inet6 static
  address 2001:db8:cafe:200::11
  netmask 64
  accept_ra 1
EOF