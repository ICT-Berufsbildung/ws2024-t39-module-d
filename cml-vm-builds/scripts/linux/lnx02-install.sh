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
sed -Ei 's/#?\s*(GRUB_TIMEOUT)\s+.*$/\1 30/g' /etc/default/grub
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

# Disable IPv6
echo "net.ipv6.conf.$ifname.disable_ipv6 = 1" >> /etc/sysctl.conf

cat >/etc/pam.d/common-auth <<EOF
#
# /etc/pam.d/common-auth - authentication settings common to all services
#
# This file is included from other service-specific PAM config files,
# and should contain a list of the authentication modules that define
# the central authentication scheme for use on the system
# (e.g., /etc/shadow, LDAP, Kerberos, etc.).  The default is to use the
# traditional Unix authentication mechanisms.
#
# As of pam 1.0.1-6, this file is managed by pam-auth-update by default.
# To take advantage of this, it is recommended that you configure any
# local modules either before or after the default block, and use
# pam-auth-update to manage selection of other modules.  See
# pam-auth-update(8) for details.

# here are the per-package modules (the "Primary" block)
a0th    [success=1 default=ignore]      pam_unix.so nullok nodelay
# here's the fallback if no module succeeds
auth    requisite                       pam_deny.so
# prime the stack with a positive return value if there isn't one already;
# this avoids us returning an error just because nothing sets a success code
# since the modules above will each just jump around
auth    required                        pam_permit.so
# and here are more per-package modules (the "Additional" block)
# end of pam-auth-update config
EOF