#!/usr/bin/env bash
set -x
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
if ! command -v wget &> /dev/null
then
    apt install -y wget
fi
if ! command -v bsdtar &> /dev/null
then
    apt install -y libarchive-tools
fi
if ! command -v xorriso &> /dev/null
then
    apt install -y xorriso
fi
if ! command -v cloud-init &> /dev/null
then
    apt install -y cloud-init
fi
if ! command -v dd &> /dev/null
then
    apt install -y coreutils
fi
# dlurl="https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-live/current/jammy-live-server-amd64.iso"
# shasumurl="https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-live/current/SHA256SUMS"
# dlurl="https://releases.ubuntu.com/mantic/ubuntu-23.10-live-server-amd64.iso"
# shasumurl="https://releases.ubuntu.com/mantic/SHA256SUMS"
dlurl="https://cdimage.ubuntu.com/ubuntu-server/noble/daily-live/current/noble-live-server-amd64.iso"
shasumurl="https://cdimage.ubuntu.com/ubuntu-server/noble/daily-live/current/SHA256SUMS"
# dlurl="https://mirror.pilotfiber.com/ubuntu-iso/releases/noble/ubuntu-24.04.1-live-server-amd64.iso"
# shasumurl="https://mirror.pilotfiber.com/ubuntu-iso/releases/noble/SHA256SUMS"
fn="ubuntu-server.iso"
shasumfn="SHA256SUMS"
ago=`date --date "7 day ago" +%s`
curl -s -I --write-out '%{http_code}' $dlurl | grep "HTTP/1.1 200 OK"
if [[ $? -gt 0 ]]
then
    dlurl=$(echo $dlurl | sed 's/current/pending/g')
    shasumurl=$(echo $shasumurl | sed 's/current/pending/g')
fi
if [[ ! -f $fn ]]
then
    wget -c -O $fn $dlurl
    wget -O $shasumfn $shasumurl
    sha256sum $fn | awk '{print $1}' | xargs -I{} grep {} $shasumfn
    ret=$?
    if [[ $ret -gt 0 ]]
    then
        echo "sha256sum failed, removing cached files and exiting"
        rm $fn
        rm $shasumfn
        exit 1
    fi
else
    filets=`stat -c %Y $fn`
    if [[ ! -f $shasumfn ]]
    then 
        wget -O $shasumfn $shasumurl
    fi
    sha256sum $fn | awk '{print $1}' | xargs -I{} grep {} $shasumfn
    ret=$?
    if [[ $ago -gt $filets ]] || [[ $ret -gt 0 ]]
    then
        echo "Cached file too old, downloading."
        wget -O $fn $dlurl
        wget -O $shasumfn $shasumurl
        sha256sum $fn | awk '{print $1}' | xargs -I{} grep {} $shasumfn
        if [[ $? -gt 0 ]]
        then
            echo "sha256sum failed, removing cached files and exiting"
            rm $fn
            rm $shasumfn
            exit 1
        fi
    fi
fi
cloud-init schema -c server/user-data  --annotate
if [[ $? -gt 0 ]]
then
    echo "Invalid user-data, exiting."
    exit 1
fi
mkdir -p tmp && bsdtar -C tmp -xf $fn
dd if=$fn bs=1 count=432 of=tmp/boot/mbr.img
efistart=$(fdisk -l $fn | grep "EFI System" | grep "iso2" | awk '{print $2}')
efisectors=$(fdisk -l $fn | grep "EFI System" | grep "iso2" | awk '{print $4}')
dd if=$fn bs=512 skip=$efistart count=$efisectors of=tmp/boot/efi.img
sed -i -re 's/(set timeout=)30/\13/g' tmp/boot/grub/grub.cfg
sed -i '0,/^menuentry.*/s//menuentry "autoinstall" \{\n\tset gfxpayload=keep\n\tlinux  \/casper\/vmlinuz quiet autoinstall ds=nocloud\\\;s=\/cdrom\/server\/ ---\n\tinitrd \/casper\/initrd\n\}\ \n&/' tmp/boot/grub/grub.cfg
echo -n > "tmp/md5sum.txt"
mkdir -p tmp/server
cp server/meta-data tmp/server/meta-data
cp server/user-data tmp/server/user-data
cd tmp
xorriso -as mkisofs \
    -quiet -D -r \
    -V "ubuntu-server-autoinstall" \
    -cache-inodes -J -l -joliet-long \
    --grub2-mbr 'boot/mbr.img' \
    -partition_offset 16 \
    --mbr-force-bootable \
    -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b 'boot/efi.img' \
    -appended_part_as_gpt \
    -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
    -b 'boot/grub/i386-pc/eltorito.img' \
    -c 'boot.catalog' \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --grub2-boot-info \
    -eltorito-alt-boot \
    -e '--interval:appended_partition_2:::' \
    -no-emul-boot \
    -o  ../ubuntu-server-autoinstall.iso .
cat boot/efi.img >> ../ubuntu-server-autoinstall.iso
cd -
rm -rf tmp
# rm $fn
