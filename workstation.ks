# Use graphical install ?
text

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

# Run the Setup Agent on first boot
firstboot --enable

# Generated using Blivet version 3.4.3
# ignoredisk --only-use=nvme0n1
autopart --type=btrfs
# Partition clearing information
clearpart --none --initlabel


# System timezone
timezone Europe/Berlin
timesource --ntp-server=kobayashi-maru.sg-intranet.lan

%packages --ignoremissing
@^workstation-product-environment
@anaconda-tools
@domain-client
aajohan-comfortaa-fonts
anaconda
anaconda-install-env-deps
anaconda-live
chkconfig
dracut-live
glibc-all-langpacks
initscripts
kernel
kernel-modules
kernel-modules-extra
freeipa-client
-@dial-up
-@input-methods
-@standard
-device-mapper-multipath
-fcoe-utils
-gfs2-utils
-reiserfs-utils
mc

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
