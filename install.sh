#------------------------------------------------------------------------------
# Personal installation script with different mode which are commented. Feel
# free to decomment them to enable your preferernce.
#------------------------------------------------------------------------------
# NOTE: Network should be set before launching this script.
#------------------------------------------------------------------------------
# Usage: ./install.sh
#

# Interrupt the script when error occurs
set -e

# Keyboard
## French (AZERTY)
loadkeys fr-latin1

# Network
if [ !$(ping -4 -c 1 archlinux.org) ] ; then
    echo "Network should be set before launching this script."
    exit 1
fi

# Update system clock
timedatectl set-ntp true

# Partitions the disks
if [ test -e /sys/firmware/efi/efivars ] ; then
    # UEFI/efi
    parted /dev/sda
    mklabel dos
    mkpart primary ext4 250Mib
    set 1 boot on
    mkpart primary ext4 16 100%
    mkfs.ext4 /dev/sda1
    mkfs.ext4 /dev/sda2
    mount /dev/sda2 /mnt
elif [ test -ne /sys/firmware/efi/efivars ] ; then
    # BIOS
    parted /dev/sda
    mklabel dos
    set 1 boot on
    mkpart primary ext4 16 100%
    mkfs.ext4 /dev/sda1
    mount /dev/sda1 /mnt
else
    echo "Boot mode not recognized"
    exit 1
fi

# Install base packages
PACKAGE_LIST="base linux linux-firmware"
pacstrap -i /mnt ${PACKAGE_LIST}

# Generate an fstab
genfstab -U /mnt > /mnt/etc/fstab

# Change root
arch-chroot /mnt

# Set the time zone
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwlock --systohc --utc

# locale
echo "# ADDED with installation scipt" /etc/local.gen
echo "en_US.UTF-8 UTF-8" /etc/local.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/local.conf
echo "KEYMAP=fr-latin1" /etc/vconsole.conf

# hostname
HOSTNAME=test
echo "${HOSTNAME}" /etc/hostname
cat <<EOF >> /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    ${HOSTNAME}
EOF

#
mkinitcpio -p linux

# Install others package via pacman
CPU_COMPANY="intel" # expected intel or amd
PACKAGE_LIST="dialog
              gcc gdb
              clang llvm
              emacs vim nano
              openmp openmpi
              grub os-prober ${CPU_COMPANY}-ucode
              firefox discord
              i3-wm i3status i3blocks i3lock"

pacman -S ${PACKAGE_LIST}

# grub
grub-install --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# root password
passwd

#
exit
unmout -R /mnt

# Create a user
USER=sholde
useradd -m -G wheel -s /bin/bash ${USER}
passwd ${USER}

# End
echo "Remove the installation medium and reboot the computer."
exit 0
