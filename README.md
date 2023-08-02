# Kickstart files for Fedora Linux automated network installations  

This repository contains the kickstart files I use for my PXE (Bios/UEFI) boot server for automated installs of Fedora Linux.  

These files are derived from these reesident in the fedora-kickstarts and the spin-kickstarts packages of Fedora Linux, actually from Fedora 38.  

## General features

These kickstart installation have the following features:  

- The entire installation runs, at least for now, using the online resources of fedora.
- Tge update repositories are included so thje newest package version available will be installed.
- The RPMFusion repositories are installed during post installation scripts.
- For server variants the root password is set to, of course you shoult change it right after installation. (Password: rootpass)
- Workstation variants or other variants with GUI come up with the setup-assistant as usual.
- Yggdrasil is installed.
- The FreeIPA client package is installed. (It is used in my Networks.)
- The kickstart installatio runs entirely in text mode to avoid some irritating behaviour in graphical mode while it is fetching the repository metadata.

## The files (more will be coming soon)

- ipa-srv.ks: Fedora Server with FreeIPA-Server installed
- webserver.ks: Fedora Server with mariadb and httpd (apache) installed and enabled
- workstation.ks: Fedora Workstation default installation
- develiper-ws.ks: Installs Fedora Workstation with developer Libraries ind VScode.

## License

These project is release under the CC0 license. You are free to use, modify and share these files without any limitations.
