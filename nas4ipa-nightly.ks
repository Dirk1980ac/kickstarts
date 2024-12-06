ostreecontainer --url=docker.io/dirk1980/nas4ipa:nightly
user --name nas4ipa --password $6$cv9TtOpm2ziBgigV$/twX.spZBQRCNDJSOKLnobURIYknvSN2tZPzzp3yY8QenMa3dGogoh36q99V4yTl0/5BU3zN/2AmQyhlHwX/f. --iscrypted --groups wheel
rootpw --lock
lang en_US.UTF-8
keyboard us
timezone UTC
clearpart --all
network --device=link --bootproto=dhcp --onboot=on --activate

reqpart --add-boot

part swap --fstype=swap --size=1024
part / --fstype=ext4 --grow

reboot --eject
%post
bootc switch --mutate-in-place --transport registry docker.io/dirk1980/nas4ipa:nightly

# used during automatic image testing as finished marker
if [ -c /dev/ttyS0 ]; then
    echo "Install finished" > /dev/ttyS0
fi
%end
