# Use graphical install ?
graphical

# Keyboard layouts
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
# System language
lang de_DE.UTF-8

# Use network installation
url --url="https://download.fedoraproject.org/pub/fedora/linux/releases/$releasever/Everything/$basearch/os"
repo --name=updates
repo --cost=2 --name=rpmfusion-free --mirrorlist=https://mirrors.rpmfusion.org/free/fedora/$releasever/$basearch
repo --cost=2 --name=rpmfusion-free-updates --mirrorlist=http://mirrors.rpmfusion.org/free/fedora/updates/$releasever/$basearch
repo --cost=2 --name=rpmfusion-nonfree --mirrorlist=http://mirrors.rpmfusion.org/nonfree/fedora/$releasever/$basearch
repo --cost=2 --name=rpmfusion-nonfree-updates --mirrorlist=http://mirrors.rpmfusion.org/nonfree/fedora/updates/$releasever/$basearch
repo --cost=2 --name=rpmfusion-nonfree-tainted --baseurl=http://download1.rpmfusion.org/nonfree/fedora/tainted/$releasever/$basearch/
repo --cost=2 --name=rpmfusion-ree-tainted --baseurl=http://download1.rpmfusion.org/free/fedora/tainted/$releasever/$basearch/
repo  --name=fedora-cisco-openh264 --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-cisco-openh264-$releasever&arch=$basearch

# Generated using Blivet version 3.7.1
# ignoredisk --only-use=vda
autopart --type=btrfs
# Partition clearing information
clearpart --none --initlabel

# System timezone
timezone Europe/Berlin --utc

# Reboot automatically after installation
reboot --eject

# Root password
rootpw --iscrypted $6$hqJqmmDJAWWaF5oe$21hb0VS7bmspBD68l1RlzDN8vWSkwDxEGuVrf1aYf76Df6QuNFEyLc0x6tT9i0TCnBy7FqcjUFJ/1CpWHRaKH0

%packages
@^server-product-environment
@admin-tools
@domain-client
@guest-agents
@headless-management
@network-server
@system-tools
-cockpit
phpmyadmin
httpd
mariadb-server
mc
NetworkManager-tui
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

# Enable services
services --enabled=httpd,mariadb,cockpit.socket

# Firewall settings
firewall --enable --service=http --service=https

%post 
dnf copr enable -y neilalexander/yggdrasil-go
dnf install -y yggdrasil

# Configure yggdrasil
/usr/bin/yggdrasil --genconf > /etc/yggdrasil.conf

# Insert some public peers
sed -ibak 's/\[\]/\ [\ntls:\/\/vpn.ltha.de:443?key=0000006149970f245e6cec43664bce203f2514b60a153e194f31e2b229a1339d\ntls://ygg.yt:443\ntls://ygg.mkg20001.io:443\ntls://ygg-uplink.thingylabs.io:443\ntls://cowboy.supergay.network:443\n    tls://supergay.network:443\n    tls://corn.chowder.land:443    \ntls://[2a03:3b40:fe:ab::1]:993\ntls://37.205.14.171:993\ntls://102.223.180.74:993\nquic://193.93.119.42:1443\n\]/' /etc/yggdrasil.conf

# Install additional firmware packages
dnf install -y rpmfusion-nonfree-release-tainted
dnf --repo=rpmfusion-nonfree-tainted install -y "*-firmware"

# Enable USB FIDO2 token to be used with sssd.
setsebool -P sssd_use_usb 1

# Set SSHd config hardening overrides
cat << EOF > /etc/ssh/sshd_config.d/00-0local.conf
PasswordAuthentication no
AllowAgentForwarding yes
GSSAPICleanupCredentials yes
EOF

# Set polkit rules for domain server
cat <<EOF > /etc/polkit-1/rules.d/40-freeipa.rules
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
%end