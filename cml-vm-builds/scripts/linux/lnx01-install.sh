#!/bin/bash
set -euxo pipefail
IFS=$'\n\t'

ifname=$(ip route get 8.8.8.8 | sed -n 's/.*dev \([^\ ]*\).*/\1/p')

# Configure user accounts
groupadd -g 2000 john
useradd -u 2000 -g john -d /home/john -m -s /bin/false john
groupadd -g 2001 lisa
useradd -u 2001 -g lisa -d /home/lisa -m -s /bin/bash lisa
groupadd -g 2002 remoteworkers
usermod -a -G remoteworkers lisa
usermod -a -G remoteworkers sysop
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
EOF


# Disable package repositories
rm -f /etc/apt/sources.list.d/*
cat >/etc/apt/sources.list <<'EOF'
# No package repositories available
EOF

# Overwrite default Apache page for compact output
echo 'Welcome to WSC2024.org' >/var/www/html/index.html
mkdir -p /var/www/secret
echo 'Welcome to Secret app at WSC2024.org' > /var/www/secret/index.html

cat >/etc/apache2/sites-available/secret.conf <<'EOF'
<VirtualHost *:8080>
    ServerName www.wsc2024.org
    DocumentRoot /var/www/secret/

    <Directory /var/www/secret>
        Options -Indexes +FollowSymLinks
        AllowOverride All
    </Directory>
</VirtualHost>
EOF
a2ensite secret

# Use local BIND9 as system resolver
cat >/etc/resolv.conf <<'EOF'
domain wsc2024.org
nameserver 127.0.0.1
nameserver ::1
EOF

# Disable delay after incorrect PAM authentication
sed -i '/pam_unix.so/ s/$/ nodelay/g' /etc/pam.d/common-auth

cat >>/etc/bind/named.conf.local <<'EOF'
zone "wsc2024.org" {
    type master;
    file "/etc/bind/db.wsc2024.org";
};
EOF

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
@ IN A 10.1.64.9
@ IN AAAA 2001:db8:cafe:200::9
ns1 IN A 10.1.64.10
ns1 IN AAAA 2001:db8:cafe:200::10
www IN CNAME @
app IN A 10.1.64.10
app IN AAAA 2001:db8:cafe:200::10
maintenance IN CNAME app
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
cat >/opt/customers-sync/sync.sh <<'EOF'
#!/bin/bash
wget -O /data/customers.csv ftp://wsc2024:Skills39@partner01.your-partner.com/customers.csv
EOF

chmod +x /opt/customers-sync/sync.sh

cat >/etc/systemd/system/partner-sync.service <<'EOF'
[Unit]
Description=Your-Partner.com Sync job

[Service]
Type=oneshot
ExecStart=/bin/bash /opt/customers-sync/sync.sh
EOF

cat >/etc/systemd/system/partner-sync.timer <<'EOF'
[Unit]
Description=Your-Partner.com Sync job timer

[Timer]
OnCalendar=hourly

[Install]
WantedBy=timers.target
EOF

systemctl enable partner-sync.timer

# Create firewall rule directory
mkdir -p /etc/firewall/rules

# Enable IP forwarding
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sed -i 's/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf
sysctl -p

cat >/etc/nftables.conf <<EOF
#!/usr/sbin/nft -f

flush ruleset

include "/etc/firewall/rules/*"

table inet filter {
        chain input {
                type filter hook input priority filter;
        }
        chain forward {
                type filter hook forward priority filter;
        }
        chain output {
                type filter hook output priority filter;
                ip6 daddr 2001:ab12:10::10 drop
        }
}
EOF

cat >/etc/firewall/rules/common.conf <<EOF
table inet filter {
        chain prerouting {
                type nat hook prerouting priority -100;
                iif $ifname tcp dport { 8080 } counter redirect to 80
        }
}
EOF
systemctl enable nftables
systemctl start nftables

# Backup access.conf
cp /etc/security/access.conf /etc/security/access.conf.orig
# Block john from accessing the server
cat >/etc/security/access.conf <<EOF
+:john:LOCAL

-:john:ALL

+:ALL:ALL
EOF

# Enable pam_access module
sed -i 's/# account  required     pam_access.so/account  required     pam_access.so/g' /etc/pam.d/sshd


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
  accept_ra 2
EOF
