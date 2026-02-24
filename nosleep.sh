#!/bin/bash

COOLDOWN=120
LOCKFILE="/tmp/nosleep.lock"
PIDFILE="/tmp/nosleep.pid"
ENDFILE="/tmp/nosleep.end"

show_help() {
    echo "NoSleep - Cegah auto sleep sementara"
    echo ""
    echo "Usage:"
    echo "  ./nosleep.sh <menit>    Jalankan nosleep selama X menit"
    echo "  ./nosleep.sh stop       Hentikan nosleep yang sedang aktif"
    echo "  ./nosleep.sh status     Lihat status dan sisa waktu"
    echo "  ./nosleep.sh -h         Tampilkan bantuan ini"
    echo ""
    echo "Keterangan:"
    echo "  - Tetap aktif walau terminal ditutup."
    echo "  - Hanya bisa dihentikan dengan perintah stop."
    echo "  - Setelah selesai atau stop, cooldown berlaku $COOLDOWN detik."
    echo ""
}

# HELP
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# STOP
if [[ "$1" == "stop" ]]; then
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE")
        if kill -0 "$PID" 2>/dev/null; then
            kill -TERM "$PID" 2>/dev/null
            sleep 1
            kill -KILL "$PID" 2>/dev/null
            echo "NoSleep dihentikan."
        else
            echo "Proses tidak ditemukan."
        fi
        rm -f "$PIDFILE" "$ENDFILE"
        date +%s > "$LOCKFILE"
    else
        echo "NoSleep tidak sedang aktif."
    fi
    exit 0
fi

# STATUS
if [[ "$1" == "status" ]]; then
    if [ -f "$PIDFILE" ] && kill -0 "$(cat $PIDFILE)" 2>/dev/null; then
        END=$(cat "$ENDFILE" 2>/dev/null)
        NOW=$(date +%s)
        REMAIN=$((END - NOW))
        if [ "$REMAIN" -gt 0 ]; then
            MIN=$((REMAIN / 60))
            SEC=$((REMAIN % 60))
            echo "NoSleep aktif."
            echo "Sisa waktu: ${MIN} menit ${SEC} detik."
        else
            echo "NoSleep aktif (akan segera selesai)."
        fi
    else
        echo "NoSleep tidak aktif."
    fi
    exit 0
fi

# VALIDASI ANGKA
if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "Masukkan durasi dalam menit."
    exit 1
fi

MINUTES="$1"
TOTAL_SECONDS=$((MINUTES * 60))
NOW=$(date +%s)
END_TIME=$((NOW + TOTAL_SECONDS))

# CEK COOLDOWN
if [ -f "$LOCKFILE" ]; then
    LAST_END=$(cat "$LOCKFILE")
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

echo "NoSleep aktif selama $MINUTES menit."
echo "Gunakan './nosleep.sh stop' untuk menghentikan."

echo "$END_TIME" > "$ENDFILE"

# Jalankan benar-benar terlepas dari terminal
nohup setsid bash -c "
    systemd-inhibit --what=idle:sleep --why='NoSleep $MINUTES menit' sleep $TOTAL_SECONDS
    date +%s > '$LOCKFILE'
    rm -f '$PIDFILE' '$ENDFILE'
" >/dev/null 2>&1 &

echo $! > "$PIDFILE"
