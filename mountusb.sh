#!/bin/bash

# Jika bukan root, jalankan ulang pakai sudo
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

MIN_SIZE=$((10 * 1024 * 1024 * 1024))  # 10GB dalam bytes

for dev in $(lsblk -lnpo NAME,TRAN | awk '$2=="usb"{print $1}'); do

    for part in $(lsblk -lnpo NAME $dev | tail -n +2); do

        # Skip jika sudah mount
        if findmnt -n "$part" > /dev/null; then
            continue
        fi

        # Ambil ukuran partisi (bytes)
        size=$(lsblk -bnpo SIZE "$part")

        # Skip kalau kurang dari 10GB
        if [ "$size" -lt "$MIN_SIZE" ]; then
            continue
        fi

        # Ambil filesystem, skip kalau kosong
        fstype=$(lsblk -no FSTYPE "$part")
        if [ -z "$fstype" ]; then
            continue
        fi

        # Ambil label
        label=$(lsblk -no LABEL "$part")
        if [ -z "$label" ]; then
            label=$(basename "$part")
        fi

        mount_point="/mnt/$label"
        mkdir -p "$mount_point"

        if mount "$part" "$mount_point"; then
            echo "Mounted $part ($fstype) to $mount_point"
        else
            echo "Failed to mount $part"
            rmdir "$mount_point"
        fi

    done
done
