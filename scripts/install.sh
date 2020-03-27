#!/usr/bin/env bash

set -e

if [ $# -ne 3 ]
then
    cat << EOF
Usage : 
$0 /boot/partition /root/partition /swap/partition
EOF
exit
fi

BOOT_DEVICE="$1"
ROOT_DEVICE="$2"
SWAP_DEVICE="$3"

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
select CONFIG in $(ls machines) "New machine"; do
    case $CONFIG in
        "New machine")
            echo "Not linking to an existing configuration"
            ;;
        *)
            ln -s machines/$CONFIG configuration.nix
            ;;
    esac
    break
done

nixos-generate-config --root /mnt

nixos-install

./post-install.sh
