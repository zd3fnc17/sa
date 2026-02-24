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

# HELP
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# VALIDASI INPUT
if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "Masukkan durasi dalam menit."
    exit 1
fi

MINUTES="$1"
TOTAL_SECONDS=$((MINUTES * 60))

# CEK COOLDOWN
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

# Jalankan inhibit
systemd-inhibit --what=idle:sleep --why="NoSleep" sleep "$TOTAL_SECONDS" &
INHIBIT_PID=$!

echo
echo "Waktu selesai."
echo "Power kembali ke default."
date +%s > "$LOCKFILE"
echo "Cooldown aktif selama $COOLDOWN detik."

# Tangkap Ctrl+C dan SIGTERM
trap cleanup INT TERM

# Countdown realtime
for ((i=$TOTAL_SECONDS; i>0; i--)); do
    if ! kill -0 "$INHIBIT_PID" 2>/dev/null; then
        break
    fi
    MIN=$((i / 60))
    SEC=$((i % 60))
    printf '\rSisa waktu: %02d menit %02d detik ' "$MIN" "$SEC"
    sleep 1
done

wait "$INHIBIT_PID" 2>/dev/null

echo
echo "Waktu selesai."
echo "Power kembali ke default."
date +%s > "$LOCKFILE"
echo "Cooldown aktif selama $COOLDOWN detik."
