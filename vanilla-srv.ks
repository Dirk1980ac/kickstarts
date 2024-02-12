# Use graphical install ?
graphical

# Keyboard layouts
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
# System language
lang de_DE.UTF-8

# Use network installation
url --url="https://download.fedoraproject.org/pub/fedora/linux/releases/$releasever/Everything/$basearch/os"
repo --name=updates
repo --cost=2 --name=rpmfusion-free --mirrorlist=https://mirrors.rpmfusion.org/free/fedora/$releasever/$basearch
repo --cost=2 --name=rpmfusion-free-updates --mirrorlist=http://mirrors.rpmfusion.org/free/fedora/updates/$releasever/$basearch
repo --cost=2 --name=rpmfusion-nonfree --mirrorlist=http://mirrors.rpmfusion.org/nonfree/fedora/$releasever/$basearch
repo --cost=2 --name=rpmfusion-nonfree-updates --mirrorlist=http://mirrors.rpmfusion.org/nonfree/fedora/updates/$releasever/$basearch

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
rootpw --iscrypted $6$hqJqmmDJAWWaF5oe$21hb0VS7bmspBD68l1RlzDN8vWSkwDxEGuVrf1aYf76Df6QuNFEyLc0x6tT9i0TCnBy7FqcjUFJ/1CpWHRaKH0

# Enable services
services --enabled=cockpit.socket

%post
dnf copr enable -y neilalexander/yggdrasil-go
dnf install -y yggdrasil

# Install additional firmware packages
dnf install -y rpmfusion-nonfree-release-tainted
dnf --repo=rpmfusion-nonfree-tainted install -y "*-firmware"

# Configure yggdrasil
/usr/bin/yggdrasil --genconf > /etc/yggdrasil.conf

# Insert some public peers
sed -ibak 's/\[\]/\[\ntls:\/\/vpn.ltha.de:443?key=0000006149970f245e6cec43664bce203f2514b60a153e194f31e2b229a1339d\ntls://ygg.yt:443\ntls://ygg.mkg20001.io:443\ntls://ygg-uplink.thingylabs.io:443\ntls://cowboy.supergay.network:443\n    tls://supergay.network:443\n    tls://corn.chowder.land:443    \ntls://[2a03:3b40:fe:ab::1]:993\ntls://37.205.14.171:993\ntls://102.223.180.74:993\nquic://193.93.119.42:1443\n\]/' /etc/yggdrasil.conf
%end
