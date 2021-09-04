#!/bin/bash

# Personal Arch Linux Installation (guignolarch)
# --------------------------------
# author    : Sholde
#             https://github.com/Sholde
#
# project   : https://github.com/Sholde/guignolarch
#
# license   : GPL-3.0 (http://opensource.org/licenses/GPL-3.0)

# Interrupt the script when error occurs
set -e

# Download
URL=https://raw.githubusercontent.com/Sholde/guignolarch/master
curl ${URL}/install.sh > install.sh
curl ${URL}/postchroot.sh > postchroot.sh

# Exit
echo "Run install.sh script to install Arch Linux"
exit
