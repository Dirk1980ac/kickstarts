# Use graphical install ?
graphical

# Keyboard layouts
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
# System language
lang de_DE.UTF-8

# Network installation repos
url --url="https://download.fedoraproject.org/pub/fedora/linux/releases/$releasever/Everything/$basearch/os"
repo --name=updates
repo --cost=2 --name=rpmfusion-free --mirrorlist=https://mirrors.rpmfusion.org/free/fedora/$releasever/$basearch
repo --cost=2 --name=rpmfusion-free-updates --mirrorlist=http://mirrors.rpmfusion.org/free/fedora/updates/$releasever/$basearch
repo --cost=2 --name=rpmfusion-nonfree --mirrorlist=http://mirrors.rpmfusion.org/nonfree/fedora/$releasever/$basearch
repo --cost=2 --name=rpmfusion-nonfree-updates --mirrorlist=http://mirrors.rpmfusion.org/nonfree/fedora/updates/$releasever/$basearch
repo --cost=2 --name=rpmfusion-nonfree-tainted --baseurl=http://download1.rpmfusion.org/nonfree/fedora/tainted/$releasever/$basearch/
repo --cost=2 --name=rpmfusion-ree-tainted --baseurl=http://download1.rpmfusion.org/free/fedora/tainted/$releasever/$basearch/
repo  --name=fedora-cisco-openh264 --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-cisco-openh264-$releasever&arch=$basearch

# Run the Setup Agent on first boot
firstboot --enable

# Generated using Blivet version 3.4.3
# ignoredisk --only-use=nvme0n1
autopart --type=btrfs
# Partition clearing information
clearpart --none --initlabel

# Reboot automatically after installation
reboot --eject

# Disable root user
rootpw --lock

# System timezone
timezone Europe/Berlin --utc

%packages
@^workstation-product-environment
@anaconda-tools
@domain-client
@guest-agents
-cockpit
aajohan-comfortaa-fonts
anaconda
anaconda-install-env-deps
anaconda-live
dracut-live
glibc-all-langpacks
initscripts
freeipa-client
mc
hexchat
mumble
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

%post 
# Enable USB FIDO2 token to be used with sssd.
setsebool -P sssd_use_usb 1

dnf groupupdate -y multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
dnf groupupdate -y sound-and-video

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

// Allow any user in the 'libvirt' , 'vmadmins' and the 'admins' group to
// connect to system libvirtd without entering a password.
polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.manage" &&
        subject.isInGroup("libvirt") ||
        subject.isInGroup("admins") ||
        subject.isInGroup("vmadmins")) {
        return polkit.Result.YES;
    }
});

polkit.addRule(function(action, subject) {
	if ((action.id == "org.freedesktop.locale1.set-locale" ||
	     action.id == "org.freedesktop.locale1.set-keyboard" ||
	     action.id == "org.freedesktop.ModemManager1.Device.Control" ||
	     action.id == "org.freedesktop.hostname1.set-static-hostname" ||
	     action.id == "org.freedesktop.hostname1.set-hostname" ||
	     action.id == "org.gnome.controlcenter.datetime.configure") &&
	    subject.active &&
	    subject.isInGroup ("admins")) {
		    return polkit.Result.YES;
	    }
});

// firewalld authorizations/policy for the admins group.
//
// Allow users in the admins group to use firewalld without being 
// interrupted by a password dialog
polkit.addRule(function(action, subject) {
    if ((action.id == "org.fedoraproject.FirewallD1.config" ||
        action.id == "org.fedoraproject.FirewallD1.direct" ||
        action.id == "org.fedoraproject.FirewallD1.ipset" ||
        action.id == "org.fedoraproject.FirewallD1.policy" ||
        action.id == "org.fedoraproject.FirewallD1.zone") &&
        subject.active == true && subject.isInGroup("admins")) {
            return polkit.Result.YES;
        }
    }
);

polkit.addRule(function(action, subject) {
    if ((action.id === "org.freedesktop.bolt.enroll" ||
        action.id === "org.freedesktop.bolt.authorize" ||
        action.id === "org.freedesktop.bolt.manage") &&
         subject.local &&
        subject.active === true &&
        subject.isInGroup("admins")) {
            return polkit.Result.YES;
    }
});

polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.Flatpak.app-install" ||
        action.id == "org.freedesktop.Flatpak.runtime-install"||
        action.id == "org.freedesktop.Flatpak.app-uninstall" ||
        action.id == "org.freedesktop.Flatpak.runtime-uninstall" ||
        action.id == "org.freedesktop.Flatpak.modify-repo") &&
        subject.active == true && subject.isInGroup("admins")) {
            return polkit.Result.YES;
    }

    return polkit.Result.NOT_HANDLED;
});

polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.Flatpak.override-parental-controls") {
        return polkit.Result.AUTH_ADMIN;
    }
    return polkit.Result.NOT_HANDLED;
});

polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.fwupd.update-internal" &&
        subject.active == true && subject.isInGroup("admins")) {
            return polkit.Result.YES;
    }
});

polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.packagekit.package-install" ||
         action.id == "org.freedesktop.packagekit.package-remove") &&
          subject.local && subject.active == true &&
          subject.isInGroup("admins")) {
            return polkit.Result.YES;
    }
});

// Allows users belonging to privileged group to start gvfsd-admin without
// authorization. This prevents redundant password prompt when starting
// gvfsd-admin. The gvfsd-admin causes another password prompt to be shown
// for each client process using the different action id and for the subject
// based on the client process.
polkit.addRule(function(action, subject) {
        if ((action.id == "org.gtk.vfs.file-operations-helper") &&
            subject.local &&
            subject.active &&
            subject.isInGroup ("admins") || subject.isInGroup ("wheel")) {
            return polkit.Result.YES;
        }
});

// Allow NetworkNabager-Settings for the admins group of FreeIPA
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.checkpoint-rollback" ||
        action.id == "org.freedesktop.NetworkManager.enable-disable-connectivity-check" ||
        action.id == "org.freedesktop.NetworkManager.enable-disable-network" ||
        action.id == "org.freedesktop.NetworkManager.enable-disable-statistics" ||
        action.id == "org.freedesktop.NetworkManager.enable-disable-wifi" ||
        action.id == "org.freedesktop.NetworkManager.enable-disable-wimax" ||
        action.id == "org.freedesktop.NetworkManager.enable-disable-wwan" ||
        action.id == "org.freedesktop.NetworkManager.network-control" ||
        action.id == "org.freedesktop.NetworkManager.reload" ||
        action.id == "org.freedesktop.NetworkManager.settings.modify.global-dns" ||
        action.id == "org.freedesktop.NetworkManager.settings.modify.hostname" ||
        action.id == "org.freedesktop.NetworkManager.settings.modify.own" ||
        action.id == "org.freedesktop.NetworkManager.settings.modify.system" ||
        action.id == "org.freedesktop.NetworkManager.sleep-wake" ||
        action.id == "org.freedesktop.NetworkManager.wifi.scan" ||
        action.id == "org.freedesktop.NetworkManager.wifi.share.open" ||
        action.id == "org.freedesktop.NetworkManager.wifi.share.protected" &&
        subject.isInGroup("admin")) {
            return polkit.Result.YES;
        }
});
EOF

# install yggdrasil
dnf copr enable -y neilalexander/yggdrasil-go
dnf install -y yggdrasil

# Configure yggdrasil
/usr/bin/yggdrasil --genconf > /etc/yggdrasil.conf
sed -ibak 's/\[\]/\[\ntls:\/\/vpn.ltha.de:443?key=0000006149970f245e6cec43664bce203f2514b60a153e194f31e2b229a1339d\ntls://ygg.yt:443\ntls://ygg.mkg20001.io:443\ntls://ygg-uplink.thingylabs.io:443\ntls://cowboy.supergay.network:443\n    tls://supergay.network:443\n    tls://corn.chowder.land:443    \ntls://[2a03:3b40:fe:ab::1]:993\ntls://37.205.14.171:993\ntls://102.223.180.74:993\nquic://193.93.119.42:1443\n\]/' /etc/yggdrasil.conf

# Lock screen on yubikey removal
# Comment out this block if you don't want this behaviour
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
cat << EOF > /etc/udev/rules.d/20-yubikey.rules
ACTION=="remove", ENV{ID_BUS}=="usb", ENV{ID_MODEL_ID}=="0407", ENV{ID_VENDOR_ID}=="1050", RUN+="/usr/local/bin/lockscreen.sh"
EOF
%end
