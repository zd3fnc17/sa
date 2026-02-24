#!/bin/bash

COOLDOWN=120
LOCKFILE="/tmp/nosleep.lock"

show_help() {
    echo "Usage:"
    echo "  ./nosleep.sh <menit>"
    echo ""
    echo "Contoh:"
    echo "  ./nosleep.sh 30"
    echo ""
    echo "Cooldown aktif $COOLDOWN detik setelah selesai."
}

# Help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Validasi input
if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "Masukkan durasi dalam menit."
    exit 1
fi

MINUTES="$1"
TOTAL_SECONDS=$((MINUTES * 60))

# Cek cooldown
if [ -f "$LOCKFILE" ]; then
    LAST_END=$(cat "$LOCKFILE")
    NOW=$(date +%s)
    DIFF=$((NOW - LAST_END))

    if [ "$DIFF" -lt "$COOLDOWN" ]; then
        REMAIN=$((COOLDOWN - DIFF))
        MIN=$((REMAIN / 60))
        SEC=$((REMAIN % 60))
        echo "Masih cooldown."
        echo "Sisa waktu: ${MIN} menit ${SEC} detik."
        exit 1
    fi
fi

echo "NoSleep berjalan selama $MINUTES menit."
echo "Setelah itu akan kembali ke power default."
echo "Tekan Ctrl+C untuk menghentikan."

cleanup() {
    echo
    echo "NoSleep dihentikan."
    date +%s > "$LOCKFILE"
    exit 0
}

trap cleanup INT

systemd-inhibit --what=idle:sleep --why="NoSleep" bash -c "
for ((i=$TOTAL_SECONDS; i>0; i--)); do
    MIN=\$((i / 60))
    SEC=\$((i % 60))
    printf '\rSisa waktu: %02d menit %02d detik ' \$MIN \$SEC
    sleep 1
done
"

echo
echo "Waktu selesai."
echo "Power kembali ke default."
date +%s > "$LOCKFILE"
echo "Cooldown aktif selama $COOLDOWN detik."
