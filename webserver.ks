# Use graphical install?
graphical

# Keyboard layouts
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
# System language
lang de_DE.UTF-8

# Use network installation
url --url="https://download.fedoraproject.org/pub/fedora/linux/releases/$releasever/Everything/$basearch/os"
repo --name=updates
repo --name=rpmfusion-free --baseurl=http://mirrors.rpmfusion.org/free/fedora/$releasever/$basearch
repo --name=rpmfusion-free-updates --baseurl=http://mirrors.rpmfusion.org/free/fedora/updates/$releasever/$basearch
repo --name=rpmfusion-nonfree --baseurl=http://mirrors.rpmfusion.org/nonfree/fedora/$releasever/$basearch
repo --name=rpmfusion-nonfree-updates --baseurl=http://mirrors.rpmfusion.org/nonfree/fedora/updates/$releasever/$basearch


# Run the Setup Agent on first boot
firstboot --enable

# Generated using Blivet version 3.7.1
# ignoredisk --only-use=vda
autopart --type=btrfs
# Partition clearing information
clearpart --none --initlabel

# System timezone
timezone Europe/Berlin --utc

# Root password
rootpw --iscrypted $6$hqJqmmDJAWWaF5oe$21hb0VS7bmspBD68l1RlzDN8vWSkwDxEGuVrf1aYf76Df6QuNFEyLc0x6tT9i0TCnBy7FqcjUFJ/1CpWHRaKH0

%packages --ignoremissing
@^server-product-environment
@admin-tools
@domain-client
@guest-agents
@headless-management
@network-server
@system-tools
httpd
mariadb-server
mc
%end

%post
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf groupupdate core -y
systemctl enable httpd mariadb

# install yggdrasil
dnf copr enable -y neilalexander/yggdrasil-go
dnf install -y yggdrasil
%end
