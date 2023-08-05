# Use graphical install ?
graphical

# Keyboard layouts
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
# System language
lang de_DE.UTF-8

# Lock root password so anaconda does not ask to set it
rootpw --lock

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
#Install RPMFusion Repositories
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf groupupdate core -y
dnf install -y rpmfusion-nonfree-release-tainted
dnf groupupdate multimedia -y --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
dnf groupupdate -y sound-and-video

# Install non-free firmware drivers
dnf --repo=rpmfusion-nonfree-tainted install -y "*-firmware"

# Install repository for Visual Studioo Code Community Edition
rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat > /etc/yum.repos.d/vscode.repo <<EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

# Install VScode
dnf install -y code

# Set polkit rules for domain clients 
cat > /etc/polkit-1/rules.d/40-freeipa.rules  <<EOF
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
%end
