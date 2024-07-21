#!/bin/bash
set -euxo pipefail
IFS=$'\n\t'

ifname=$(ip route get 8.8.8.8 | sed -n 's/.*dev \([^\ ]*\).*/\1/p')

# Configure hostname and hosts
echo 'lnx03' >/etc/hostname

# Install required packages unattended
export DEBIAN_FRONTEND=noninteractive
apt-get -qqy update
apt-get install -qqy \
  -o DPkg::options::="--force-confdef" \
  -o DPkg::options::="--force-confold" \
  apache2 \
  apache2-doc \
  squid

cat >/etc/hosts <<'EOF'
127.0.0.1 localhost
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

10.1.64.12 lnx03.wsc2024.org lnx03 app.wsc2024.org
2001:db8:cafe:200::12 lnx03.wsc2024.org lnx03 app.wsc2024.org
EOF

cat >/etc/squid/conf.d/wsc2024.conf <<'EOF'
# WSC2024 local networks
acl localnet src 10.0.0.0/16
acl localnet src 2001:db8:cafe::/48
# Allow WSC2024 local networks
http_access allow localnet
EOF

systemctl enable squid
systemctl start squid

# Disable package repositories
rm -f /etc/apt/sources.list.d/*
cat >/etc/apt/sources.list <<'EOF'
# No package repositories available
EOF

# Overwrite default Apache page for compact output
cp -r /tmp/wwwroot/assets /var/www/html/
cp -r /tmp/wwwroot/images /var/www/html/
cp /tmp/wwwroot/lnx03.html /var/www/html/index.html

# Disable delay after incorrect PAM authentication
sed -i '/pam_unix.so/ s/$/ nodelay/g' /etc/pam.d/common-auth

# Use local BIND9 as system resolver
cat >/etc/resolv.conf <<'EOF'
domain wsc2024.local
nameserver 10.1.64.20
nameserver 2001:db8:cafe:200::20
EOF

# Deploy network interface configuration
cat >/etc/network/interfaces <<EOF
# Loopback
auto lo
iface lo inet loopback

# Primary
auto $ifname
iface $ifname inet static
  address 10.1.64.12
  netmask 255.255.255.0
  gateway 10.1.64.1

iface $ifname inet6 static
  address 2001:db8:cafe:200::12
  netmask 64
  accept_ra 1
EOF
