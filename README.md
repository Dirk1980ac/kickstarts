# Kickstart files for Fedora Linux automated network installations  

This repository contains the kickstart files I use for my PXE (Bios/UEFI) boot server for automated installs of Fedora Linux.  

These files are derived from these reesident in the fedora-kickstarts and the spin-kickstarts packages of Fedora Linux, actually from Fedora 38.  

## General features

These kickstart installation have the following features:  

- The entire installation runs, at least for now, using the online resources of fedora.
- The update repositories are included so thje newest package version available will be installed.
- The RPMFusion repositories are installed during post installation scripts.
- For server variants the root password is set to, of course you shoult change it right after installation. (Password: rootpass)
- Workstation variants or other variants with GUI come up with the setup-assistant as usual.
- Yggdrasil is installed.
- The FreeIPA client package is installed. (It is used in my Networks.)

## The kickstart files (more will be coming soon)

- ipa-srv.ks: Fedora Server with FreeIPA-Server installed
- webserver.ks: Fedora Server with mariadb and httpd (apache) installed and enabled
- workstation.ks: Fedora Workstation default installation
- develiper-ws.ks: Installs Fedora Workstation with developer Libraries ind VScode.
- seclab.ks: Installs Fedora Security Lab.

## Localization

You might want to change the language, timezone and keyboard layout  to fit yout needs since I set them to german/germany because that is where I live.

## Installation process

The installation will start in graphical mode. No question will be asked since everything is pre-configured.  

You must have enough unpartitioned space on one of your harddisks. Existing partitions will be left untouched for security reasons.If you do not have enough unpartitoned edisk space youi will have di change your partitions manually in the installer and the installation would not continue automatically.  

- For Workstation variants: The installer will download the metadata of the repositories. If you click on any of the displayed options while this is happening the automatic installation will be stopped and you have to click the install button manually. If you just let the download of the metadata happen without interruption the installer will right after that continue to download and install the software which is selected in the kickstart file.

- For Server variants: The whole installation is done in text mode. Remember to change the root password!

## License

These project is release under the CC0 license. You are free to use, modify and share these files without any limitations.
