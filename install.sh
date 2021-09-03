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
echo "fdisk"
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
echo "pacstrap"
KERNEL_PACKAGE_LIST="base linux linux-firmware"
pacstrap -i /mnt ${KERNEL_PACKAGE_LIST} <<EOF


EOF

# Generate an fstab
echo "genfstab"
genfstab -U /mnt > /mnt/etc/fstab

# Change root
echo "arch-chroot"
cp postchroot.sh /mnt/root
chmod 755 /mnt/root/postchroot.sh
arch-chroot /mnt /root/postchroot.sh
rm /mnt/root/postchroot.sh

# umount
echo "umount"
umount -R /mnt

# End installation
echo "You can reboot the computer"
exit 0
