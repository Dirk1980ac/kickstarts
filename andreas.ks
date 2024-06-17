# Installation mode
graphical
        
# Keyboard layouts
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'

# System language
lang de_DE.UTF-8

# Network installation repos
repo --cost=1 --name=fedora --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
## repo --name=updates
repo --cost=0 --name=rpmfusion-free --mirrorlist=https://mirrors.rpmfusion.org/free/fedora/$releasever/$basearch
## repo --cost=0 --name=rpmfusion-free-updates --mirrorlist=http://mirrors.rpmfusion.org/free/fedora/updates/$releasever/$basearch
repo --cost=0 --name=rpmfusion-nonfree --mirrorlist=http://mirrors.rpmfusion.org/nonfree/fedora/$releasever/$basearch
## repo --cost=0 --name=rpmfusion-nonfree-updates --mirrorlist=http://mirrors.rpmfusion.org/nonfree/fedora/updates/$releasever/$basearch
repo --cost=0 --name=rpmfusion-nonfree-tainted --baseurl=http://download1.rpmfusion.org/nonfree/fedora/tainted/$releasever/$basearch/
repo --cost=0 --name=rpmfusion-free-tainted --baseurl=http://download1.rpmfusion.org/free/fedora/tainted/$releasever/$basearch/
repo  --name=fedora-cisco-openh264 --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-cisco-openh264-$releasever&arch=$basearch
repo --cost=0 --name=copr-beilalexander-yggdrasil-go --baseurl=https://download.copr.fedorainfracloud.org/results/neilalexander/yggdrasil-go/fedora-$releasever-$basearch/

# Run the Setup Agent on first boot?
firstboot --disable

# Hard disk partitioning scheme
autopart --type=btrfs

# Do not delete existing partitions
clearpart --none --initlabel

# Set a bit more meaningful hostname
network --hostname=andreas-nb

# Reboot automatically after installation
reboot --eject

# Disable root user
rootpw --lock

# System timezone
timezone Europe/Berlin --utc

# Firewall settings
firewall --enable --service=ssh --service=dhcpv6-client --service=mdns

# Enable services
services --enabled=sshd,fail2ban,yggdrasil,dnf-automatic-install.timer

# Configure User
user --name=andreas --gecos="Andreas Mittmann" --groups=wheel,audio,video,libvirt --iscrypted --password=$6$jGuZ7fveE9/eP3S.$byWeX/rz75Yi6Af/Ica9vTp/V1ar6PWUKfN3PJf7uSjUMj.8BT8PUTxWnxJiLChY6gYLij3LsQ78nUuXuFyp1.
sshkey --username=andreas "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIAokmKhXPt5UBkmgc55RmcvhCVpo8B9FgMaDhgOlQvzbAAAAD3NzaDpkZ290dHNjaGFsaw=="

%packages
# Mandatory packages
@^workstation-product-environment
glibc-all-langpacks
initscripts
-kernel-*debug
kernel
kernel-modules
kernel-modules-extra
*-firmware
# RPMFusion repos
rpmfusion-free-release
rpmfusion-nonfree-release
rpmfusion-free-release-tainted
rpmfusion-nonfree-release-tainted
# Godfathers wishlist
cockpit
mc
NetworkManager-tui
waypipe
# fail2ban
dnf-automatic
htop
yggdrasil
zsh
# Andreas wishlist
gnome-tweaks
gnome-extensions-app
foliate
vlc
ffmpeg
libdvdcss
gnucash
virt-manager
calibre
filezilla
video-downloader
telegram-desktop
digikam
smplayer
virt-manager
%end

%post 
# Set AMD specific packages for Multimedia
dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld

# Configure yggdrasil
/usr/bin/yggdrasil -genconf -json > /etc/yggdrasil.generated.conf
jq '.Peers = ["tls://ygg.yt:443","tls://ygg.mkg20001.io:443","tls://vpn.ltha.de:443","tls://ygg-uplink.thingylabs.io:443","tls://supergay.network:443","tls://[2a03:3b40:fe:ab::1]:993","tls://37.205.14.171:993"]' /etc/yggdrasil.generated.conf > /etc/yggdrasil.conf

# Add a firewall zone for the yggdrasil network and only allow ssh for this
# zone what is unfortunately not possible with the kickstart 'firewall' directive
firewall-offline-cmd --permanent --new-zone=yggdrasil
firewall-offline-cmd --permanent --zone=yggdrasil --add-interface=tun0
firewall-offline-cmd --permanent --zone=yggdrasil --add-service=ssh

# Configure Fail2Ban to protect against ssh brute force attacks.
cat << EOF > /etc/fail2ban/jail.d/10-sshd.conf
[sshd]
enabled = true
port = 22
filter = sshd
maxretry = 5
EOF

# Local DNS configuration overrides
mkdir -p /etc/systemd/resolved.conf.d
cat << EOF > /etc/systemd/resolved.conf.d/zzz-local.conf
[Resolve]
DNS=222:9b9a:73de:5323:1074:29b:e210:1a11 21f:221c:f061:7992:90c:db90:e2bc:d0bc
FallbackDNS=8.8.8.8#dns.google 8.8.4.4#dns.google 2001:4860:4860::8888#dns.google 2001:4860:4860::8844#dns.google 1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com
EOF

# Change default network options
cat <<EOF > /etc/NetworkManager/conf.d/00-privacy.conf
[main]
hostname-mode=none

[device]
wifi.scan-rand-mac-address=yes
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=permanent

[ipv4]
dhcp-send-hostname=false
ignore-auto-dns=true

[ipv6]
dhcp-send-hostname=false
addr-gen-mode=stable-privacy
ignore-auto-dns=true
ip6-privacy=2
EOF
%end
