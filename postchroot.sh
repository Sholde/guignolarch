#!/bin/bash

#------------------------------------------------------------------------------
# Personal installation script of Arch Linux distribution with my preferences.
#------------------------------------------------------------------------------
# NOTE: This file is not supposed to be run directly.
#------------------------------------------------------------------------------
#

# Interrupt the script when error occurs
set -e

# Check input
if [ $# != 2 ] ; then
    echo "Needed 2 arguments: hostname, username"
    exit 1
fi

HOSTNAME=$1
USERNAME=$2

# Set the time zone
echo "Setting timezone..."
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc --utc

# locale
echo "Setting locale..."
sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
sed -i 's/#fr_FR ISO/fr_FR ISO/g' /etc/locale.gen

locale-gen
cat >> /etc/locale.conf <<EOF
LANGAGE=en_US.UTF-8
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
LC_ADDRESS=en_US.UTF-8
LC_IDENTIFICATION=en_US.UTF-8
LC_MEASUREMENT=en_US.UTF-8
LC_MONETARY=en_US.UTF-8
LC_NAME=en_US.UTF-8
LC_NUMERIC=en_US.UTF-8
LC_PAPER=en_US.UTF-8
LC_TELEPHONE=en_US.UTF-8
LC_TIME=en_US.UTF-8
EOF
echo "KEYMAP=fr-latin1" >> /etc/vconsole.conf

# hostname
echo "Setting hostname..."
echo "${HOSTNAME}" >> /etc/hostname
cat >> /etc/hosts <<EOF
127.0.0.1    localhost
::1          localhost
127.0.1.1    ${HOSTNAME}.localadmin ${HOSTNAME}
EOF

# Refresh pacman keys
echo "Refreshing pacman keys..."
pacman-key --refresh-keys

# Init Mirror list with reflector
echo "Initialising mirror list..."
pacman -S reflector --needed --noconfirm
COUNTRY="Germany,Belgium,United_Kingdom,Sweden"
reflector --country ${COUNTRY} --protocol https --latest 50 --save /etc/pacman.d/mirrorlist
pacman -Syyu --noconfirm

# Install others package via pacman
echo "Installing packages..."
CPU_COMPANY="intel" # expected intel or amd
UCODE=""
if [ ${CPU_COMPANY} != "" ] ; then
    UCODE="${CPU_COMPANY}-ucode"
fi
PACKAGE_LIST="xfce4-terminal
              dialog sudo doas make htop
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
echo "Enabling NetworkManager..."
systemctl enable NetworkManager

# root password
echo "Setting root password..."
passwd

# Create a user
echo "Creating user..."
useradd -m -G wheel,audio,video,optical -s /bin/bash ${USERNAME}
passwd ${USERNAME}

# Init xorg
echo "Initialising xorg..."
xorg_file=/home/${USERNAME}/.xinitrc
cp /etc/X11/xinit/xinitrc $xorg_file
for i in {1..5} ; do sed -i '$d' $xorg_file ; done
cat >> $xorg_file <<EOF
setxkbmap -model pc105 -layout fr -variant latin9

exec i3
EOF

# Init bash
echo "Initialising bash..."
bash_profile_file=/home/${USERNAME}/.bash_profile
cat >> $bash_profile_file <<EOF

[[ $(fgconsole 2> /dev/null) == 1 ]] && exec startx -- vt1
EOF

# Edit sudoers file
echo "Editing visudo..."
EDITOR=emacs visudo

# grub
echo "Installing grub..."
grub-install --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# Exit root
echo "Exiting /mnt"
exit
