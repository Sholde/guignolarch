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
loadkeys fr-latin1

# Network
if [ !$(ping -4 -c 1 archlinux.org) ] ; then
    echo "Network should be set before launching this script."
    exit 1
fi

# Update system clock
timedatectl set-ntp true

# Partitions the disks
## fdisk
## UEFI/efi
fdisk /dev/sda <<EOF
g
n
1

+550M
n
2


w
EOF
mkfs.fat -F32 /dev/sda1
mkdir /boot/EFI
mkfs.ext4 /dev/sda2
mount /dev/sda2 /mnt

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
echo "# ADDED with installation script" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
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
PACKAGE_LIST="dialog sudo
              gcc gdb git
              clang llvm
              emacs vim nano
              openmp openmpi
              grub os-prober ${UCODE}
              firefox discord evince
              xorg xorg-xinit i3 dmenu"
pacman -S ${PACKAGE_LIST} --noconfirm

# root password
passwd

# Create a user
USER=sholde
useradd -m -G wheel,audio,video,optical -s /bin/bash ${USER}
passwd ${USER}

# Init xorg
cp /etc/X11/xinit/xinitrc /home/${USER}/.xinitrc
for i in {1..5} ; do sed -i '$d' /home/${USER}/.xinitrc ; done
echo "setxkbmap -model pc105 -layout fr -variant latin9" >> /home/${USER}/.xinitrc
echo "" >> /home/${USER}/.xinitrc
echo "exec i3" >> /home/${USER}/.xinitrc

# Init bash
echo "" >> /home/${USER}/.bash_profile
echo "[[ $(fgconsole 2> /dev/null) == 1 ]] && exec startx -- vt1" >> /home/${USER}/.bash_profile

# Edit sudoers file
EDITOR=emacs visudo

# grub
grub-install --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# Exit root
exit
umout -R /mnt

# End installation
echo "You can reboot the computer."
exit 0
