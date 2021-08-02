#------------------------------------------------------------------------------
# Personal installation script of Arch Linux distribution with my preferences.
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
## English (QWERTY)
#loadkeys us

# Network
if [ !$(ping -4 -c 1 archlinux.org) ] ; then
    echo "Network should be set before launching this script."
    exit 1
fi

# Update system clock
timedatectl set-ntp true

# Partitions the disks
## Put all in 1 partition
if [ test -e /sys/firmware/efi/efivars ] ; then
    # UEFI/efi
    #parted /dev/sda
    #mklabel dos
    #mkpart primary ext4 250Mib
    #set 1 boot on
    #mkpart primary ext4 16 100%
    #mkfs.ext4 /dev/sda1
    #mkfs.ext4 /dev/sda2
    #mount /dev/sda2 /mnt
elif [ test -ne /sys/firmware/efi/efivars ] ; then
    # BIOS

    ## parted
    #parted /dev/sda
    #mklabel dos
    #set 1 boot on
    #mkpart primary ext4 16 100%
    #mkfs.ext4 /dev/sda1
    #mount /dev/sda1 /mnt

    ## fdisk
    fdisk /dev/sda <<EOF
o
n
p
1


EOF
    mkfs.ext4 /dev/sda1
    mount /dev/sda1 /mnt
else
    echo "Boot mode not recognized"
    exit 1
fi

# Install base packages
KERNEL_PACKAGE_LIST="base linux linux-firmware"
pacstrap -i /mnt ${KERNEL_PACKAGE_LIST}

# Generate an fstab
genfstab -U /mnt > /mnt/etc/fstab

# Change root
arch-chroot /mnt

# Set the time zone
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc --utc

# locale
echo "# ADDED with installation scipt" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/local.gen
locale-gen
echo "LANGAGE=en_US.UTF-8" >> /etc/locale.conf
echo "LC_ALL=" >> /etc/locale.conf
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=fr-latin1" >> /etc/vconsole.conf

# hostname
HOSTNAME=sholde
echo "${HOSTNAME}" >> /etc/hostname
cat <<EOF >> /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    ${HOSTNAME}.localadmin ${HOSTNAME}
EOF

# Init Mirror list
COUNTRY="Germany Belgium United_Kingdom France"
TIMEOUT=3
pacman-mirrors --country ${COUNTRY} --timeout ${TIMEOUT}
pacman -Syyu --noconfirm

# Install others package via pacman
CPU_COMPANY="intel" # expected intel or amd
UCODE=""
if [ ${CPU_COMPANY} != "" ] ; then
    UCODE="${CPU_COMPANY}-ucode"
fi
PACKAGE_LIST="dialog
              gcc gdb
              clang llvm
              emacs vim nano
              openmp openmpi
              grub os-prober ${UCODE}
              firefox discord
              i3-wm i3status i3blocks i3lock"
pacman -S ${PACKAGE_LIST} --noconfirm

# grub
grub-install --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# root password
passwd

# Exit root
exit
unmout -R /mnt

# Create a user
USER=sholde
useradd -m -G wheel,audio,video,optical -s /bin/bash ${USER}
passwd ${USER}

# End installation
echo "Remove the installation medium and reboot the computer."
exit 0
