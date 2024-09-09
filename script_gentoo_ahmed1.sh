#! /bin/bash

set -e

if(grep -q /dev/sda1 /proc/mounts);then umount -l /dev/sda1;fi
mkfs.vfat -F 32 /dev/sda1

if(grep -q /dev/sda2 /proc/swaps);then swapoff /dev/sda2;fi

mkswap /dev/sda2
swapon /dev/sda2

if(grep -q /dev/sda3 /proc/mounts);then umount -l /dev/sda3;fi

mkfs.xfs -f /dev/sda3

mkdir --parents /mnt/gentoo
mkdir --parents /mnt/gentoo/efi


mount /dev/sda3 /mnt/gentoo
cp -rf menuconfig_gentoo_ahmed.config /mnt/gentoo
cp -rf script_gentoo_ahmed2.sh /mnt/gentoo
cp -rf stage3-amd64-desktop-systemd-20240901T170410Z.tar.xz /mnt/gentoo
cd /mnt/gentoo/

#wget -c https://distfiles.gentoo.org/releases/amd64/autobuilds/20240901T170410Z/stage3-amd64-desktop-systemd-20240901T170410Z.tar.xz

tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
#nano /mnt/gentoo/etc/portage/make.conf
sed -i '5i COMMON_FLAGS="-march=native -O2 -pipe"' /mnt/gentoo/etc/portage/make.conf
sed -i '6d'  /mnt/gentoo/etc/portage/make.conf
sed -i '5i USE="-gtk -gnome kde dvd"' /mnt/gentoo/etc/portage/make.conf
sed -i '5i MAKEOPTS="-j12"' /mnt/gentoo/etc/portage/make.conf


cp --dereference /etc/resolv.conf /mnt/gentoo/etc/


mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run

chroot /mnt/gentoo /bin/bash
