ostreecontainer --url=docker.io/dirk1980/mediajunkie:latest
user --name mjunkie --password mjunkie --groups wheel
rootpw --lock
lang de_DE.UTF-8
keyboard de-nodeadkeys
timezone Europe/Berlin
clearpart --none --initlabel
network --device=link --bootproto=dhcp --onboot=on --activate

reqpart --add-boot
part / --fstype=ext4 --grow

reboot --eject

%post
bootc switch --mutate-in-place --transport registry docker.io/dirk1980/mediajunkie:latest

# used during automatic image testing as finished marker
if [ -c /dev/ttyS0 ]; then
    echo "Install finished" > /dev/ttyS0
fi
%end
