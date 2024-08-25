# Installation mode
graphical

# Keyboard layouts
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
# System language
lang de_DE.UTF-8

# Use network installation
repo --cost=1 --name=fedora --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
repo --name=updates
repo --cost=0 --name=rpmfusion-free --mirrorlist=https://mirrors.rpmfusion.org/free/fedora/$releasever/$basearch
repo --cost=0 --name=rpmfusion-free-updates --mirrorlist=http://mirrors.rpmfusion.org/free/fedora/updates/$releasever/$basearch
repo --cost=0 --name=rpmfusion-nonfree --mirrorlist=http://mirrors.rpmfusion.org/nonfree/fedora/$releasever/$basearch
repo --cost=0 --name=rpmfusion-nonfree-updates --mirrorlist=http://mirrors.rpmfusion.org/nonfree/fedora/updates/$releasever/$basearch
repo --cost=0 --name=rpmfusion-nonfree-tainted --baseurl=http://download1.rpmfusion.org/nonfree/fedora/tainted/$releasever/$basearch/
repo --cost=0 --name=rpmfusion-free-tainted --baseurl=http://download1.rpmfusion.org/free/fedora/tainted/$releasever/$basearch/
repo  --name=fedora-cisco-openh264 --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-cisco-openh264-$releasever&arch=$basearch

%packages
@^server-product-environment
@admin-tools
@domain-client
@guest-agents
@headless-management
@network-server
@system-tools
NetworkManager-tui
-cockpit
mc
zsh
rpmfusion-free-appstream-data
rpmfusion-free-release
rpmfusion-free-release-tainted
rpmfusion-nonfree-appstream-data
rpmfusion-nonfree-release
rpmfusion-nonfree-release-tainted
libdvdcss
*-firmware
%end

# Firewall options
firewall --enable --service=ssh 

# Generated using Blivet version 3.7.1
# ignoredisk --only-use=vda
autopart --type=btrfs
# Partition clearing information
clearpart --none --initlabel

# Reboot automatically after installation
reboot --eject

# System timezone
timezone Europe/Berlin --utc

# Root password
rootpw --plaintext rootpass

# Load the autogenerated hostname
%include /tmp/pre-hostname

%pre
# Auto generate a more or less random hostname to avoid conflicts when joining
# a FreeIPA domain without using the --hostname option.
echo "network --hostname=`echo srv-$RANDOM$RANDOM`" > /tmp/pre-hostname
%end

%post
dnf copr enable -y neilalexander/yggdrasil-go
dnf install -y yggdrasil

# Install additional firmware packages
dnf install -y rpmfusion-nonfree-release-tainted
dnf --repo=rpmfusion-nonfree-tainted install -y "*-firmware"


# Configure yggdrasil
/usr/bin/yggdrasil -genconf -json > /etc/yggdrasil.generated.conf
jq '.Peers = ["tls://ygg.yt:443","tls://ygg.mkg20001.io:443","tls://vpn.ltha.de:443","tls://ygg-uplink.thingylabs.io:443","tls://supergay.network:443","tls://[2a03:3b40:fe:ab::1]:993","tls://37.205.14.171:993"]' /etc/yggdrasil.generated.conf > /etc/yggdrasil.conf
%end
