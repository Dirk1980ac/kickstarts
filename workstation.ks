# Use graphical install ?
graphical

# Keyboard layouts
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
# System language
lang de_DE.UTF-8

# Network installation repos
url --url="https://download.fedoraproject.org/pub/fedora/linux/releases/$releasever/Everything/$basearch/os"
repo --name=updates
repo --name=rpmfusion-free --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-%releasever&arch=$basearch
repo --name=rpmfusion-free-updates --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-$releasever&arch=$basearch
repo --name=rpmfusion-nonfree --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-$releasever&arch=$basearch
repo --name=rpmfusion-nonfree-updates --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-updates-released-$releasever&arch=$basearch
repo --name=rpmfusion-free-tainted --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-tainted-$releasever&arch=$basearch
repo --name=rpmfusion-nonfree-tainted --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-tainted-$releasever&arch=$basearch

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
aajohan-comfortaa-fonts
anaconda
anaconda-install-env-deps
anaconda-live
chkconfig
dracut-live
glibc-all-langpacks
initscripts
freeipa-client
mc
hexchat
mumble
zsh
%end

%post 
#Install RPMFusion Repositories
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf groupupdate core -y  --allowerasing
dnf install -y rpmfusion-nonfree-release-tainted
dnf groupupdate multimedia -y --setop="install_weak_deps=False" --allowerasing
dnf groupupdate -y sound-and-video  --allowerasing

# Install non-free firmware drivers
dnf --repo=rpmfusion-nonfree-tainted install -y "*-firmware"

# Install libdvdcss to play DVDs
dnf install -y rpmfusion-free-release-tainted
dnf install -y libdvdcss  --allowerasing

# Install mulimedia software
dnf install -y kodi kodi-pvr-iptvsimple vlc  --allowerasing

# Set polkit rules for domain clients 
cat << EOF > /etc/polkit-1/rules.d/40-freeipa.rules[code]
// Domain admins are also machine admins
polkit.addAdminRule(function(action, subject) {
    return ["unix-group:admins", "unix-group:wheel"];
});

// Allow any user in the 'libvirt' and the 'admins' group to connect to system
// libvirtd without entering a password.
polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.manage" &&
        subject.isInGroup("libvirt") ||
        subject.isInGroup("admins")) {
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

// firewalld authorizations/policy for the wheel group.
//
// Allow users in the wheel group to use firewalld without being 
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
EOF

# install yggdrasil
dnf copr enable -y neilalexander/yggdrasil-go
dnf install -y yggdrasil

# Configure yggdrasil
/usr/bin/yggdrasil --genconf > /etc/yggdrasil.conf

# Insert somme public peers for yggdrasil
sed -ibak 's/\[\]/\  [\n    tls:\/\/ygg.mkg20001.io:443\n    tls:\/\/vpn.ltha.de:443?key=0000006149970f245e6cec43664bce203f2514b60a153e194f31e2b229a1339d\n  \]/' /etc/yggdrasil.conf

%end
