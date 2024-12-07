ostreecontainer --url docker.io/dirk1980/workstation:test
user --name gatekeeper --password testuser --groups wheel
rootpw --lock
lang de_DE.UTF-8
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
timezone Europe/Berlin --utc
clearpart --all
network --device=link --bootproto=dhcp --onboot=on --activate

reqpart --add-boot

part swap --fstype=swap --size=1024
part / --fstype=ext4 --grow

reboot --eject
%post
bootc switch --mutate-in-place --transport registry docker.io/dirk1980/workstation:test

# used during automatic image testing as finished marker
if [ -c /dev/ttyS0 ]; then
    echo "Install finished" > /dev/ttyS0
fi
%end
