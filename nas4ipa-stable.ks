# Basic setup
text
network --bootproto=dhcp --device=link --activate
# Basic partitioning
clearpart --all --initlabel --disklabel=gpt
reqpart --add-boot
part / --grow --fstype xfs

# Here's where we reference the container image to install - notice the kickstart
# has no `%packages` section!  What's being installed here is a container image.
ostreecontainer --url docker.io/dirk1980/nas4ipa:latest

firewall --disabled
services --enabled=sshd,cockpit,nfs-server

# Only inject a SSH key for root
user --name=nas4ipa --password=nas4ipa --groups=wheel
reboot
