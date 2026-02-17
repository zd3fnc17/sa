#!/bin/bash

# Jika bukan root, jalankan ulang pakai sudo
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

for dev in $(lsblk -lnpo NAME,TRAN | awk '$2=="usb"{print $1}'); do

    for part in $(lsblk -lnpo NAME $dev | tail -n +2); do

        # Skip jika sudah mount
        if findmnt -n "$part" > /dev/null; then
            continue
        fi

        # Ambil label
        label=$(lsblk -no LABEL "$part")

        # Kalau tidak ada label, pakai nama device
        if [ -z "$label" ]; then
            label=$(basename "$part")
        fi

        mount_point="/mnt/$label"

        mkdir -p "$mount_point"

        fstype=$(lsblk -no FSTYPE "$part")

        if [ "$fstype" = "ntfs" ]; then
            mount -t ntfs-3g "$part" "$mount_point" -o uid=1000,gid=1000
        elif [ "$fstype" = "exfat" ]; then
            mount -t exfat "$part" "$mount_point" -o uid=1000,gid=1000
        else
            mount "$part" "$mount_point"
        fi

        echo "Mounted $part to $mount_point"

    done
done
