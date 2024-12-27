ostreecontainer --url docker.io/dirk1980/gatekeeper-os:nightly
user --name gatekeeper --password $6$Nis9RrnHcKEhcvPn$bIyh/7mgL92wNSPFTsMh3sHcX9SIGt.nG0xfKb6uc.lgBYe52QBS6Wy8d581R/gtGTyxyewHxhOL6U5pkI8tj. --iscrypted --groups wheel
rootpw --lock
lang de_DE.UTF-8
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
timezone Europe/Berlin --utc
clearpart --none --initlabel
network --device=link --bootproto=dhcp --onboot=on --activate

reqpart --add-boot
part / --fstype=ext4 --grow

reboot --eject
%post
bootc switch --mutate-in-place --transport registry docker.io/dirk1980/gatekeeper-os:nightly

# used during automatic image testing as finished marker
if [ -c /dev/ttyS0 ]; then
    echo "Install finished" > /dev/ttyS0
fi
%end
