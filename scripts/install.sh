#!/usr/bin/env bash

set -e

#if [ $# -ne 3 ]
#then
#    cat << EOF
#Usage : 
#$0 /partition/to/encrypt partition-name /path/to/boot
#EOF
#exit
#fi

ROOT_DEVICE="/dev/nvme1n1p1"
SWAP_DEVICE="/dev/nvme1n1p2"
BOOT_DEVICE="/dev/nvme1n1p3"
CONFIG="desktop-home.nix"

ROOT_NAME="nixos"
SWAP_NAME="swap"
BOOT_NAME="SYSTEM"

BY_LABEL="/dev/disk/by-label/"

ROOT=$BY_LABEL$ROOT_NAME
SWAP=$BY_LABEL$SWAP_NAME
BOOT=$BY_LABEL$BOOT_NAME

mkswap -L $SWAP_NAME $SWAP_DEVICE
mkfs.vfat -n $BOOT_NAME $BOOT_DEVICE

mount $BOOT /mnt

encrypt.sh $ROOT_DEVICE $ROOT_NAME /mnt

umount /mnt
mount $ROOT /mnt
mkdir /mnt/boot
mount $BOOT /mnt/boot
swapon $SWAP
mkdir /mnt/etc
git clone https://github.com/FaustXVI/nixos-configuration /mnt/etc/nixos

cd /mnt/etc/nixos
ln -s machines/$CONFIG configuration.nix

nixos-generate-config --root /mnt

nixos-install

./post-install.sh
