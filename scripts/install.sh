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

export NIXPKGS_ALLOW_UNFREE=1

NIXOS_VERSION="20.03"

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

INSTALL_ROOT="/mnt"
INSTALL_BOOT="$INSTALL_ROOT/boot"
CONFIG_PATH="$INSTALL_ROOT/home/xadet/.config"
GITHUB_HTTP="http://github.com/FaustXVI"
GITHUB_SSH="git@github.com:FaustXVI"

mkswap -L $SWAP_NAME $SWAP_DEVICE
mkfs.vfat -n $BOOT_NAME $BOOT_DEVICE

mount $BOOT $INSTALL_ROOT

encrypt.sh $ROOT_DEVICE $ROOT_NAME $INSTALL_ROOT

umount $INSTALL_ROOT
echo "waiting a bit to be sure we can mount"
sleep 5
mount $ROOT $INSTALL_ROOT
mkdir $INSTALL_BOOT
mount $BOOT $INSTALL_BOOT
swapon $SWAP
mkdir $INSTALL_ROOT/etc
git clone $GITHUB_HTTP/nixos-configuration $INSTALL_ROOT/etc/nixos
cd $INSTALL_ROOT/etc/nixos
git remote set-url origin $GITHUB_SSH/nixos-configuration.git
cd -

cd $INSTALL_ROOT/etc/nixos
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

nixos-generate-config --root $INSTALL_ROOT

nix-channel --add https://github.com/rycee/home-manager/archive/release-${NIXOS_VERSION}.tar.gz home-manager
nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
nix-channel --update

nixos-install

clone() {
    git clone $GITHUB_HTTP/$1 $CONFIG_PATH/$2
    cd $CONFIG_PATH/$2
    git remote set-url origin $GITHUB_SSH/$1.git
    cd -
}


mkdir -p $CONFIG_PATH
clone nixos-xadet-configuration nixpkgs
clone omf-config omf
nixos-enter --root $INSTALL_ROOT -c 'mv /etc/nixos /home/xadet/nixos-configuration'
nixos-enter --root $INSTALL_ROOT -c 'ln -s /home/xadet/nixos-configuration /etc/nixos'
chown --reference=/mnt/home/xadet -R /mnt/home/xadet

mkdir $INSTALL_ROOT/tmp
mount -B /tmp $INSTALL_ROOT/tmp
cp /etc/resolv.conf $INSTALL_ROOT/etc/resolv.conf
curl -L https://get.oh-my.fish > $INSTALL_ROOT/tmp/install-omf
nixos-enter --root $INSTALL_ROOT -c 'su xadet -l -c "fish /tmp/install-omf --noninteractive"'
umount $INSTALL_ROOT/tmp
rm $INSTALL_ROOT/etc/resolv.conf

echo "Everything is ok, you can reboot"
