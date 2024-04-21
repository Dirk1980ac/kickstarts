# Installation mode
graphical

# Keyboard layouts
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
# System language
lang de_DE.UTF-8

# Lock root password so anaconda does not ask to set it
rootpw --lock

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

autopart --type=btrfs

# Partition clearing?
clearpart --none --initlabel

# Load the autogenerated hostname
%include /tmp/pre-hostname

# Reboot automatically after installation
reboot --eject

# System timezone
timezone Europe/Berlin --utc

%packages
@^workstation-product-environment
@anaconda-tools
@domain-client
@C Development Tools and Libraries
@Development Tools
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
libevent-devel
glib2-devel
pcsc-lite-devel
gtk4-devel
gpgme-devel
kernel-devel
autoconf
autoconf-archive
git
git2cl
pre-commit
gitg
-cockpit
mc
hexchat
mumble
zsh
code
kodi
kodi-pvr-iptvsimple
vlc
rpmfusion-free-appstream-data
rpmfusion-free-release
rpmfusion-free-release-tainted
rpmfusion-nonfree-appstream-data
rpmfusion-nonfree-release
rpmfusion-nonfree-release-tainted
libdvdcss
*-firmware
waypipe
%end

%pre
# Auto generate a more or less random hostname to avoid conflicts when joining
# a FreeIPA domain without using the --hostname option.
echo "network --hostname=`echo dev-ws-$RANDOM`" > /tmp/pre-hostname
%end

%post
# Enable USB FIDO2 token to be used with sssd.
setsebool -P sssd_use_usb 1

# Install non-free firmwares
dnf install -y rpmfusion-free-release
dnf install -y rpmfusion-nonfree-release
dnf install -y rpmfusion-free-release-tainted
dnf install -y repo=rpmfusion-nonfree-tainted
dnf --repo=rpmfusion-nonfree-tainted install -y "*-firmware"
dnf install -y libdvdcss

# Set SSHd config hardening overrides
cat << EOF > /etc/ssh/sshd_config.d/00-0local.conf
PasswordAuthentication no
AllowAgentForwarding yes
GSSAPICleanupCredentials yes
EOF

# Set polkit rules for domain clients.
cat << EOF > /etc/polkit-1/rules.d/40-freeipa.rules
// Domain admins are also machine admins
polkit.addAdminRule(function(action, subject) {
    return ["unix-group:admins", "unix-group:wheel"];
});
EOF

# install yggdrasil
dnf copr enable -y neilalexander/yggdrasil-go
dnf install -y yggdrasil

# Configure yggdrasil
/usr/bin/yggdrasil -genconf -json > /etc/yggdrasil.generated.conf
jq '.Peers = ["tls://ygg.yt:443","tls://ygg.mkg20001.io:443","tls://vpn.ltha.de:443","tls://ygg-uplink.thingylabs.io:443","tls://supergay.network:443","tls://[2a03:3b40:fe:ab::1]:993","tls://37.205.14.171:993"]' /etc/yggdrasil.generated.conf > /etc/yggdrasil.conf

# Screen locking script
cat << EOF > /usr/local/bin/lockscreen.sh
#!/bin/sh
#Author: https://gist.github.com/jhass/070207e9d22b314d9992

for bus in /run/user/*/bus; do
    uid=$(basename $(dirname $bus))
    if [ $uid -ge 1000 ]; then
	user=$(id -un $uid)
	export DBUS_SESSION_BUS_ADDRESS=unix:path=$bus
	if su -c 'dbus-send --session --dest=org.freedesktop.DBus --type=method_call --print-reply  /org/freedesktop/DBus org.freedesktop.DBus.ListNames' $user | grep org.gnome.ScreenSaver; then
	    su -c 'dbus-send --session --type=method_call --dest=org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock' $user
	fi
    fi
done
EOF

# UDEV rules to trigger the screen locking script
# Uncomment the rule in the file created below to enable screen locking on
# yubikey removal. 
cat << EOF > /etc/udev/rules.d/20-yubikey.rules
#ACTION=="remove", ENV{ID_BUS}=="usb", ENV{ID_MODEL_ID}=="0407", ENV{ID_VENDOR_ID}=="1050", RUN+="/usr/local/bin/lockscreen.sh"
EOF
%end
