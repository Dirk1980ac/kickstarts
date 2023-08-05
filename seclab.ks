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

# Configure yggdrasil
/usr/bin/yggdrasil --genconf > /etc/yggdrasil.conf

# Insert somme public peers
sed -ibak 's/\[\]/\  [\n    tls:\/\/ygg.mkg20001.io:443\n    tls:\/\/vpn.ltha.de:443?key=0000006149970f245e6cec43664bce203f2514b60a153e194f31e2b229a1339d\n  \]/' /etc/yggdrasil.conf



# Set polkit rules for domain clients 
# Domain admins can administer this machine
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


%end
