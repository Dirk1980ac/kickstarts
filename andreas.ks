# Installation mode
graphical

# Keyboard layouts
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
# System language
lang de_DE.UTF-8

# Network installation repos
repo --cost=1 --name=fedora --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
repo --name=updates
repo --cost=0 --name=rpmfusion-free --mirrorlist=https://mirrors.rpmfusion.org/free/fedora/$releasever/$basearch
repo --cost=0 --name=rpmfusion-free-updates --mirrorlist=http://mirrors.rpmfusion.org/free/fedora/updates/$releasever/$basearch
repo --cost=0 --name=rpmfusion-nonfree --mirrorlist=http://mirrors.rpmfusion.org/nonfree/fedora/$releasever/$basearch
repo --cost=0 --name=rpmfusion-nonfree-updates --mirrorlist=http://mirrors.rpmfusion.org/nonfree/fedora/updates/$releasever/$basearch
repo --cost=0 --name=rpmfusion-nonfree-tainted --baseurl=http://download1.rpmfusion.org/nonfree/fedora/tainted/$releasever/$basearch/
repo --cost=0 --name=rpmfusion-free-tainted --baseurl=http://download1.rpmfusion.org/free/fedora/tainted/$releasever/$basearch/
repo  --name=fedora-cisco-openh264 --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-cisco-openh264-$releasever&arch=$basearch

# Run the Setup Agent on first boot
firstboot --enable

# Hard disk partitioning scheme
autopart --type=btrfs
# Do not delete existing partitions
clearpart --all --initlabel

# Set a bit more meaningful hostname
network --hostname=andreas-nb

# Reboot automatically after installation
reboot --eject

# Disable root user
rootpw --lock

# System timezone
timezone Europe/Berlin --utc

# Firewall settings
firewall --enable --service=ssh --service=dhcpv6-client --service=mdns

# Enable services
services --enabled=sshd,fail2ban

%packages
# Mandatory packages
@^workstation-product-environment
@anaconda-tools
aajohan-comfortaa-fonts
glibc-all-langpacks
initscripts
kernel
kernel-modules
kernel-modules-extra
# Do not install 'kernel-debug' package
-kernel-*debug
# Avoid errors when using cockpit-client for remote access
# so do not install a local cockpit server
-cockpit
# For easier remote file browsing
mc
# Fail2Ban for ssh
fail2ban
# Add DVD support
libdvdcss
# Andreas wishlist
foliate
vlc
gnucash
virt-manager
calibre
gnome-tweaks
filezilla
video-downloader
telegram-desktop
digikam
smplayer
%end

%post 
# Install RPMFusion repo packages for later use
dnf install -y rpmfusion-free-release
dnf install -y rpmfusion-nonfree-release
dnf install -y rpmfusion-free-release-tainted
dnf install -y repo=rpmfusion-nonfree-tainted

# Install non-free firmwares
dnf --repo=rpmfusion-nonfree-tainted install -y "*-firmware"

# Install configure and enable yggdrasil
dnf copr enable -y neilalexander/yggdrasil-go
dnf install -y yggdrasil


# Configure yggdrasil
/usr/bin/yggdrasil -genconf -json > /etc/yggdrasil.generated.conf
jq '.Peers = ["tls://ygg.yt:443","tls://ygg.mkg20001.io:443","tls://vpn.ltha.de:443","tls://ygg-uplink.thingylabs.io:443","tls://supergay.network:443","tls://[2a03:3b40:fe:ab::1]:993","tls://37.205.14.171:993"]' /etc/yggdrasil.generated.conf > /etc/yggdrasil.conf
systemctl enable --now yggdrasil

# Add a firewall zone for the yggdrasil network and only
# allow ssh for this zone.
# This is not possible with the kickstart 'firewall' directive
firewall-cmd --permanent --new-zone=yggdrasil
firewall-cmd --permanent --zone=yggdrasil --add-interface=tun0
firewall-cmd --permanent --zone=yggdrasil --add-service=ssh

# Configure Fail2Ban to protect against ssh brute force attacks.
cat << EOF > /etc/fail2ban/jail.d/10-sshd.conf
[sshd]
enabled = true
port = 22
filter = sshd
maxretry = 5
EOF

# Local DNS configuration overrides
mkdir -p /etc/systemd/resolved.conf.d
cat << EOF > /etc/systemd/resolved.conf.d/zzz-local.conf
[Resolve]
DNS=222:9b9a:73de:5323:1074:29b:e210:1a11
FallbackDNS=8.8.8.8#dns.google 8.8.4.4#dns.google 2001:4860:4860::8888#dns.google 2001:4860:4860::8844#dns.google 1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com
EOF

cat <<EOF > /etc/NetworkManager/conf.d/00-privacy.conf
[main]
hostname-mode=none

[device]
wifi.scan-rand-mac-address=yes
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random

[ipv4]
dhcp-send-hostname=false
ignore-auto-dns=true

[ipv6]
dhcp-send-hostname=false
addr-gen-mode=stable-privacy
ignore-auto-dns=true
ip6-privacy=2
EOF

# Disable auto dns for existing connection enp3s0
nmcli connection modify enp3s0 ipv4.ignore-auto-dns true
nmcli connection modify enp3s0 ipv6.ignore-auto-dns true

%end
