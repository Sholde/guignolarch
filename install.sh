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
fdisk /dev/sda <<EOF
o
n
p
1


w
EOF
mkfs.ext4 /dev/sda1
mount /dev/sda1 /mnt

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
cat >> /etc/locale.gen <<EOF
# ADDED with installation script
en_US.UTF-8 UTF-8
EOF

locale-gen
cat >> /etc/locale.conf <<EOF
LANGAGE=en_US.UTF-8
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
EOF
echo "KEYMAP=fr-latin1" >> /etc/vconsole.conf

# hostname
HOSTNAME=sholde
echo "${HOSTNAME}" >> /etc/hostname
cat >> /etc/hosts <<EOF
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
PACKAGE_LIST="dialog sudo doas
              gcc gdb git
              clang llvm
              emacs vim nano
              openmp openmpi
              grub os-prober ${UCODE}
              firefox discord evince
              xorg xorg-xinit i3 dmenu
              networkmanager bind nmap geoip geoip-database geoip-database-extra metasploit"
pacman -S ${PACKAGE_LIST} --needed --noconfirm

# Enable NetworkManager
systemctl enable NetworkManager

# root password
passwd

# Create a user
USER=sholde
useradd -m -G wheel,audio,video,optical -s /bin/bash ${USER}
passwd ${USER}

# Init xorg
xorg_file=/home/${USER}/.xinitrc
cp /etc/X11/xinit/xinitrc $xorg_file
for i in {1..5} ; do sed -i '$d' $xorg_file ; done
cat >> $xorg_file <<EOF
setxkbmap -model pc105 -layout fr -variant latin9

exec i3
EOF

# Init bash
bash_profile_file=/home/${USER}/.bash_profile
cat >> $bash_profile_file <<EOF

[[ $(fgconsole 2> /dev/null) == 1 ]] && exec startx -- vt1
EOF

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
