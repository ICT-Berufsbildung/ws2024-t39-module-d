#!/bin/bash
set -euxo pipefail
IFS=$'\n\t'

ifname=$(ip route get 8.8.8.8 | sed -n 's/.*dev \([^\ ]*\).*/\1/p')

groupadd -g 2000 wsc2024
useradd -u 2000 -g wsc2024 -d /home/wsc2024 -m -s /usr/sbin/nologin wsc2024
echo 'wsc2024:Skills39' | chpasswd

# Install required packages unattended
export DEBIAN_FRONTEND=noninteractive
apt-get -qqy update
apt-get install -qqy \
  -o DPkg::options::="--force-confdef" \
  -o DPkg::options::="--force-confold" \
  apache2 \
  apache2-doc \
  proftpd \
  proftpd-doc \
  bind9 \
  bind9-doc \
  wget

# Configure hostname and hosts
echo 'partner01' >/etc/hostname

cat >/etc/hosts <<'EOF'
127.0.0.1 localhost
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

31.22.11.32 partner01.your-partner.com partner01
2001:AB12:10::10 partner01.your-partner.com partner01
EOF


# Disable package repositories
rm -f /etc/apt/sources.list.d/*
cat >/etc/apt/sources.list <<'EOF'
# No package repositories available
EOF

# Overwrite default Apache page for compact output
echo 'Welcome to Your Partner' >/var/www/html/index.html

# Use local BIND9 as system resolver
cat >/etc/resolv.conf <<'EOF'
domain your-partner.com
nameserver 127.0.0.1
nameserver ::1
EOF

cat >>/etc/bind/named.conf.local <<'EOF'
zone "." {
    type master;
    file "db.root";
};
EOF

# Create zonefile for wsc2024.org
cat >/etc/bind/db.root <<'EOF'
$TTL 3600
@ IN SOA ns1.root. tech.root. (
  1
  604800
  86400
  2419200
  3600
)
@ IN NS ns1.root.
@ IN A 10.1.64.10
@ IN AAAA 2001:db8:cafe:200::10
ns1.root. IN A 9.9.9.9
partner01.your-partner.com. IN A 31.22.11.32 
partner01.your-partner.com. IN AAAA 2001:AB12:10::10
www.msftconnecttest.com. IN A 9.9.9.9
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
iface $ifname inet static
  address 31.22.11.32
  netmask 255.255.255.128
  gateway 31.22.11.1

iface $ifname inet6 static
  address 2001:AB12:10::10
  netmask 64
  accept_ra 1
  up ip addr add 2001:AB12:10::ef/64 dev $ifname
  down ip addr del 2001:AB12:10::ef/64 dev $ifname
EOF

wget -P /home/wsc2024 http://$PACKER_HTTP_ADDR/customers.csv
chown wsc2024:wsc2024 /home/wsc2024/customers.csv
chmod 444 /home/wsc2024/customers.csv

sed -Ei 's/#?\s*(ServerName)\s+.*$/\1 "Your Partner - Share"/g' /etc/proftpd/proftpd.conf
sed -Ei 's/#?\s*(DefaultRoot).*$/\1 ~/g' /etc/proftpd/proftpd.conf
sed -Ei 's/#?\s*(RequireValidShell).*$/\1 off/g' /etc/proftpd/proftpd.conf