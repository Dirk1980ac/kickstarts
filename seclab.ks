# Use graphical install ?
graphical

# Keyboard layouts
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
# System language
lang de_DE.UTF-8

# Network installation repos
url --url="https://download.fedoraproject.org/pub/fedora/linux/releases/$releasever/Everything/$basearch/os"
repo --name=updates
repo --name=rpmfusion-free --baseurl=http://mirrors.rpmfusion.org/free/fedora/$releasever/$basearch
repo --name=rpmfusion-free-updates --baseurl=http://mirrors.rpmfusion.org/free/fedora/updates/$releasever/$basearch
repo --name=rpmfusion-nonfree --baseurl=http://mirrors.rpmfusion.org/nonfree/fedora/$releasever/$basearch
repo --name=rpmfusion-nonfree-updates --baseurl=http://mirrors.rpmfusion.org/nonfree/fedora/updates/$releasever/$basearch
repo --name=VScode --baseurl=https://packages.microsoft.com/yumrepos/vscode

# Run the Setup Agent on first boot
firstboot --enable

# Generated using Blivet version 3.4.3
# ignoredisk --only-use=nvme0n1
autopart --type=btrfs
# Partition clearing information
clearpart --none --initlabel


# System timezone
timezone Europe/Berlin --utc
%packages
@domain-client
@admin-tools
@guest-agents
@headless-management
@network-server
@system-tools

# install env-group to resolve RhBug:1891500
@^xfce-desktop-environment

@xfce-apps

# Security tools
@security-lab
security-menus

# unlock default keyring. FIXME: Should probably be done in comps
gnome-keyring-pam
%end

%post
#Install RPMFusion
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf groupupdate core -y
dnf groupupdate multimedia -y --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
dnf groupupdate -y sound-and-video
dnf install -y rpmfusion-nonfree-release-tainted
dnf --repo=rpmfusion-nonfree-tainted install -y "*-firmware"

# install yggdrasil
dnf copr enable -y neilalexander/yggdrasil-go
dnf install -y yggdrasil
%end
