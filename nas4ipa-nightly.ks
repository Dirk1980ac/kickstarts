# Basic setup
text
network --bootproto=dhcp --device=link --activate

# System timezone
timezone Europe/Berlin --utc

# Basic partitioning
clearpart --all --initlabel --disklabel=gpt
reqpart --add-boot
part / --grow --fstype xfs

# Keyboard layouts
keyboard --vckeymap=de-nodeadkeys --xlayouts='de (nodeadkeys)'
# System language
lang de_DE.UTF-8

# Here's where we reference the container image to install - notice the kickstart
# has no `%packages` section!  What's being installed here is a container image.
ostreecontainer --url docker.io/dirk1980/nas4ipa:nightly

# Create initial administrative user
user --name=nas4ipa --password=nas4ipa --groups=wheel

# Reboot after install
reboot
