#!/bin/bash
set -euxo pipefail
IFS=$'\n\t'

ifname=$(ip route get 8.8.8.8 | sed -n 's/.*dev \([^\ ]*\).*/\1/p')

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

# Configure user accounts
groupadd -g 2000 john
useradd -u 2000 -g john -d /home/john -m -s /bin/bash john
groupadd -g 2001 lisa
useradd -u 2001 -g lisa -d /home/lisa -m -s /bin/bash lisa
echo 'john:Skills39' | chpasswd
echo 'lisa:Skills39' | chpasswd

# Install required packages unattended
export DEBIAN_FRONTEND=noninteractive
apt-get -qqy update
apt-get install -qqy \
  -o DPkg::options::="--force-confdef" \
  -o DPkg::options::="--force-confold" \
  apache2 \
  apache2-doc \
  bind9 \
  bind9-doc \
  dnsutils \
  isc-dhcp-server

# Configure hostname and hosts
echo 'lnx01' >/etc/hostname

cat >/etc/hosts <<'EOF'
127.0.0.1 localhost
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

10.1.64.10 lnx01.wsc2024.org lnx01
2001:db8:cafe:200::10 lnx01.wsc2024.org lnx01
2001:AB12:10::10 partner01.your-partner.com
31.22.11.32 partner01.your-partner.com
EOF


# Disable package repositories
rm -f /etc/apt/sources.list.d/*
cat >/etc/apt/sources.list <<'EOF'
# No package repositories available
EOF

# Overwrite default Apache page for compact output
echo 'Welcome to WSC2024.org' >/var/www/html/index.html

# Use local BIND9 as system resolver
cat >/etc/resolv.conf <<'EOF'
domain wsc2024.org
nameserver 127.0.0.1
nameserver ::1
EOF

# Disable delay after incorrect PAM authentication
sed -i '/pam_unix.so/ s/$/ nodelay/g' /etc/pam.d/common-auth

# Create zonefile for wsc2024.org
cat >/etc/bind/db.wsc2024.org <<'EOF'
$TTL 3600
@ IN SOA ns1.wsc2024.org. tech.wsc2024.org. (
  1
  604800
  86400
  2419200
  3600
)
@ IN NS ns1.wsc2024.org.
@ IN A 10.1.64.10
@ IN AAAA 2001:db8:cafe:200::10
ns1 IN A 10.1.64.10
ns1 IN AAAA 2001:db8:cafe:200::10
www IN CNAME @
EOF

# Create dhcp server config
cat >/etc/dhcp/dhcpd.conf <<'EOF'
default-lease-time 600;
max-lease-time 7200;
authorative;
subnet 10.1.64.0 netmask 255.255.255.0 {}

subnet 10.1.0.0 netmask 255.255.254.0 {
 range 10.1.0.100 10.1.1.200;
 option routers 10.1.0.1;
 option domain-name-servers 10.1.64.20;
 option domain-name "wsc2024.local";
}
EOF

cat >/etc/default/isc-dhcp-server <<EOF
INTERFACESv4="$ifname"
EOF

# FTP sync
mkdir /opt/customers-sync
mkdir /data
cat >/opt/customers-sync/sync.sh <<EOF
#!/bin/bash
wget -P /data ftp://wsc2024:Skills39@partner01.your-partner.com/customers.csv
EOF

chmod +x /opt/customers-sync/sync.sh

cat >/etc/systemd/system/partner-sync.service <<EOF
[Unit]
Description=Your-Partner.com Sync job

[Service]
Type=oneshot
ExecStart=/bin/bash /opt/customers-sync/sync.sh
EOF

cat >/etc/systemd/system/partner-sync.timer <<EOF
[Unit]
Description=Your-Partner.com Sync job timer

[Timer]
OnCalendar=*:0/15

[Install]
WantedBy=timers.target
EOF

systemctl enable partner-sync.timer

# Deploy network interface configuration
cat >/etc/network/interfaces <<EOF
# Loopback
auto lo
iface lo inet loopback

# Primary
auto $ifname
iface $ifname inet static
  address 10.1.64.10
  netmask 255.255.255.0
  gateway 10.1.64.1

iface $ifname inet6 static
  address 2001:db8:cafe:200::10
  netmask 64
  accept_ra 1
EOF
