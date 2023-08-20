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

# Run the Setup Agent on first boot
firstboot --enable

# Generated using Blivet version 3.4.3
# ignoredisk --only-use=nvme0n1
autopart --type=btrfs
# Partition clearing information
clearpart --none --initlabel

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
mc
hexchat
mumble
zsh
%end

%post --erroronfail
#Install RPMFusion Repositories
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
[ $? -ne 0 ] && return 1;
dnf groupupdate core -y
[ $? -ne 0 ] && return 1;
dnf install -y rpmfusion-nonfree-release-tainted
[ $? -ne 0 ] && return 1;
dnf groupupdate multimedia -y --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
[ $? -ne 0 ] && return 1;
dnf groupupdate -y sound-and-video
[ $? -ne 0 ] && return 1;

# Install non-free firmware drivers
dnf --repo=rpmfusion-nonfree-tainted install -y "*-firmware"
[ $? -ne 0 ] && return 1;

# Install repository for Visual Studio Code Community Edition
rpm --import https://packages.microsoft.com/keys/microsoft.asc
[ $? -ne 0 ] && return 1;
cat << EOF > /etc/yum.repos.d/vscode.repo
[vscode]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
[ $? -ne 0 ] && return 1;

# Install VScode
dnf install -y code
[ $? -ne 0 ] && return 1;

# Install libdvdcss to play DVDs
dnf install -y rpmfusion-free-release-tainted
[ $? -ne 0 ] && return 1;
dnf install -y libdvdcss
[ $? -ne 0 ] && return 1;

# Install mulimedia software
dnf install -y kodi kodi-pvr-iptvsimple vlc
[ $? -ne 0 ] && return 1;

# Check and install apropiate hardware codecs at least for AMD/ATI GPU
lsmod | grep amdgpu
[ $? -eq 0 ] && \
    dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld && \
    dnf swap -< mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
[ $? -ne 0 ] && return 1;

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
[ $? -ne 0 ] && return 1;

# install yggdrasil
dnf copr enable -y neilalexander/yggdrasil-go
[ $? -ne 0 ] && return 1;
dnf install -y yggdrasil
[ $? -ne 0 ] && return 1;

# Configure yggdrasil
/usr/bin/yggdrasil --genconf > /etc/yggdrasil.conf
[ $? -ne 0 ] && return 1;

# Insert somme public peers
sed -ibak 's/\[\]/\  [\n    tls:\/\/ygg.mkg20001.io:443\n    tls:\/\/vpn.ltha.de:443?key=0000006149970f245e6cec43664bce203f2514b60a153e194f31e2b229a1339d\n  \]/' /etc/yggdrasil.conf
[ $? -ne 0 ] && return 1;
%end
