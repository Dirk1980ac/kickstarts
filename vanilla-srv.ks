# Use graphical install ?
text

# Keyboard layouts
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
# System language
lang de_DE.UTF-8

# Use network installation
url --url="https://download.fedoraproject.org/pub/fedora/linux/releases/$releasever/Everything/$basearch/os"
repo --name=updates
repo --install --name=rpmfusion-free --mirrorlist=https://mirrors.rpmfusion.org/free/fedora/$releasever/$basearch
repo --install --name=rpmfusion-free-updates --mirrorlist=http://mirrors.rpmfusion.org/free/fedora/updates/$releasever/$basearch
repo --install --name=rpmfusion-nonfree --mirrorlist=http://mirrors.rpmfusion.org/nonfree/fedora/$releasever/$basearch
repo --install --name=rpmfusion-nonfree-updates --mirrorlist=http://mirrors.rpmfusion.org/nonfree/fedora/updates/$releasever/$basearch

%packages
@^server-product-environment
@admin-tools
@domain-client
@guest-agents
@headless-management
@network-server
@system-tools
NetworkManager-tui
mc
zsh
%end

# Firewall options
firewall --enable --service=cockpit --service=ssh --port=4321/Tcp

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
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

dnf copr enable -y neilalexander/yggdrasil-go
dnf install -y yggdrasil

# Install additional firmware packages
dnf install -y rpmfusion-nonfree-release-tainted
dnf --repo=rpmfusion-nonfree-tainted install -y "*-firmware"

# Configure yggdrasil
/usr/bin/yggdrasil --genconf > /etc/yggdrasil.conf

# Insert some public peers
sed -ibak 's/\[\]/\  [\n    tls:\/\/ygg.mkg20001.io:443\n    tls:\/\/vpn.ltha.de:443\n    tls://ygg.yt:443\n  \]/' /etc/yggdrasil.conf
%end