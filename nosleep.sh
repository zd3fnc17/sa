#!/bin/bash

COOLDOWN=120   # cooldown dalam detik (120 = 2 menit)
LOCKFILE="/tmp/nosleep.lock"

# Cek cooldown
if [ -f "$LOCKFILE" ]; then
    LAST_RUN=$(cat "$LOCKFILE")
    NOW=$(date +%s)
    DIFF=$((NOW - LAST_RUN))

    if [ "$DIFF" -lt "$COOLDOWN" ]; then
        REMAIN=$((COOLDOWN - DIFF))
        echo "Masih cooldown. Tunggu $REMAIN detik lagi."
        exit 1
    fi
fi

read -p "Masukkan durasi (menit): " MINUTES

if ! [[ "$MINUTES" =~ ^[0-9]+$ ]]; then
    echo "Input harus angka."
    exit 1
fi

SECONDS_TOTAL=$((MINUTES * 60))

echo "Menjalankan nosleep selama $MINUTES menit..."
date +%s > "$LOCKFILE"

# Trap supaya kalau Ctrl+C tetap bersih
cleanup() {
    echo ""
    echo "Dihentikan manual."
    rm -f "$LOCKFILE"
    exit 0
}

trap cleanup SIGINT

systemd-inhibit --what=idle:sleep --why="Manual NoSleep" sleep "$SECONDS_TOTAL"

rm -f "$LOCKFILE"
echo "Selesai."
