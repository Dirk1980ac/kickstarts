# Installation mode
graphical

# Keyboard layouts
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
# System language
lang de_DE.UTF-8

# Network installation repos
repo --name=fedora --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
repo --name=updates

%packages
@^server-product-environment
@admin-tools
@domain-client
@freeipa-server
@guest-agents
@headless-management
@network-server
@system-tools
cockpit
NetworkManager-tui
freeipa-server-dns
mc
zsh
%end

# Firewall options
firewall --enable --service=freeipa-4 --service=freeipa-replication --service=ssh

# Generated using Blivet version 3.7.1
# ignoredisk --only-use=vda
autopart
# Partition clearing information
clearpart --none --initlabel

# Reboot automatically after installation
reboot --eject

# System timezone
timezone Europe/Berlin --utc

# Root password
rootpw --plaintext rootpass

# Load the autogenerated hostname
%include /tmp/pre-hostname

%pre
# Auto generate a more or less random hostname to avoid conflicts when joining
# a FreeIPA domain without using the --hostname option.
echo "network --hostname=`echo ipasrv-$RANDOM`" > /tmp/pre-hostname
%end

%post 

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
EOF
%end