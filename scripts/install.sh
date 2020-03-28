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

INSTALL_ROOT="/mnt"
CONFIG_PATH="$INSTALL_ROOT/home/xadet/.config"
GITHUB_HTTP="http://github.com/FaustXVI"
GITHUB_SSH="git@github.com:FaustXVI"

clone() {
    git clone $GITHUB_HTTP/$1 $CONFIG_PATH/$2
    cd $CONFIG_PATH/$2
    git remote set-url origin $GITHUB_SSH/$1.git
    cd -
}

cd /etc/nixos
git remote set-url origin $GITHUB_SSH/nixos-configuration.git
cd -

mkdir -p $CONFIG_PATH
clone nixos-xadet-configuration nixpkgs
clone omf-config omf
nixos-enter --root $INSTALL_ROOT -c 'mv /etc/nixos /home/xadet/nixos-configuration'
nixos-enter --root $INSTALL_ROOT -c 'ln -s /home/xadet/nixos-configuration /etc/nixos'
chown --reference=/mnt/home/xadet -R /mnt/home/xadet

mount -o bind,ro /etc/resolv.conf $INSTALL_ROOT/etc/resolv.conf
nixos-enter --root $INSTALL_ROOT -c 'su xadet -l -c "curl -L https://get.oh-my.fish | fish"'
nixos-enter --root $INSTALL_ROOT -c 'su xadet -l -c "nix-channel --add https://github.com/rycee/home-manager/archive/release-19.09.tar.gz home-manager"'
nixos-enter --root $INSTALL_ROOT -c 'su xadet -l -c "nix-shell https://github.com/rycee/home-manager/archive/release-19.09.tar.gz home-manager -A install"'
nixos-enter --root $INSTALL_ROOT -c 'su xadet -l -c "home-manager switch"'

