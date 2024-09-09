#! /bin/bash

set -e

source /etc/profile
#export PS1="(chroot) ${PS1}"
export PS1="[chroot] $PS1"

mkdir /efi/
mount /dev/sda1 /efi/

emerge-webrsync

emerge --verbose --oneshot app-portage/mirrorselect
mirrorselect -s4 -b10 -D -o >> /etc/portage/make.conf

emerge --sync
eselect profile list
eselect profile set default/linux/amd64/23.0/desktop/plasma/systemd
getuto
systemd-machine-id-setup

emerge --oneshot app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags

mkdir /etc/portage/package.license
echo "*/* *" >> /etc/portage/package.license/custom

sed -i '11i VIDEO_CARDS="intel"' /etc/portage/make.conf
#portageq envvar ACCEPT_LICENSE @FREE
sed -i '11i ACCEPT_LICENSE="*"' /etc/portage/make.conf
emerge --verbose --update --deep --newuse @world
emerge --depclean
emerge --config sys-libs/timezone-data

ln -sf ../usr/share/zoneinfo/Africa/Algiers /etc/localtime

#env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
env-update && source /etc/profile && export PS1="[chroot] $PS1"

emerge sys-kernel/linux-firmware
emerge sys-firmware/sof-firmware

echo "quiet splash" >> /etc/kernel/cmdline

echo "sys-kernel/installkernel" > /etc/portage/package.accept_keywords/installkernel
echo "sys-boot/uefi-mkconfig" >> /etc/portage/package.accept_keywords/installkernel
echo "app-emulation/virt-firmware" >> /etc/portage/package.accept_keywords/installkernel

#echo "sys-kernel/installkernel efistub" >> /etc/portage/package.use/installkernel


mkdir -p /efi/EFI/Gentoo

echo "sys-kernel/installkernel dracut grub" > /etc/portage/package.use/installkernel
emerge sys-kernel/installkernel

#emerge sys-kernel/gentoo-kernel

emerge sys-apps/pciutils
emerge sys-apps/usbutils
emerge sys-kernel/gentoo-sources

eselect kernel set 1
cd /usr/src/linux
make mrproper
#make localmodconfig
#make menuconfig
cp -rf /menuconfig_gentoo_ahmed.config /usr/src/linux/.config
#openssl req -new -nodes -utf8 -sha256 -x509 -outform PEM -out kernel_key.pem -keyout kernel_key.pem

#chown root:root kernel_key.pem
#chmod 400 kernel_key.pem

#sed -i '11i USE="modules-sign"' /etc/portage/make.conf
#emerge app-crypt/sbsigntools
#sbsign /usr/src/linux-x.y.z/path/to/kernel-image --cert /path/to/kernel_key.pem --key /path/to/kernel_key.pem --out /usr/src/linux-x.y.z/path/to/kernel-image
#make menuconfig

make && make modules_install
make install
cat > /etc/fstab << "EOF"
# Adjust for any formatting differences and/or additional partitions created from the "Preparing the disks" step
/dev/sda1   /efi        vfat    umask=0077     0 2
/dev/sda2   none         swap    sw                   0 0
/dev/sda3   /            xfs    defaults,noatime              0 1
EOF
#hostnamectl hostname ahmed
echo ahmed > /etc/hostname


emerge --noreplace sys-kernel/dracut
emerge net-misc/dhcpcd
systemctl enable dhcpcd


systemd-firstboot --prompt
emerge sys-apps/mlocate
emerge sys-block/io-scheduler-udev-rules

#emerge net-wireless/iw net-wireless/wpa_supplicant

emerge net-wireless/iw
emerge net-wireless/iwd
emerge net-wireless/wireless-tools

echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
echo 'GRUB_CMDLINE_LINUX="init=/usr/lib/systemd/systemd"' >> /etc/default/grub
emerge sys-boot/grub
grub-install --efi-directory=/efi
grub-mkconfig -o /boot/grub/grub.cfg

passwd root
useradd -m -G users,wheel,audio,cdrom,video,portage -s /bin/bash ahmed
timedatectl set-timezone Africa/Algiers
passwd ahmed
exit
reboot
