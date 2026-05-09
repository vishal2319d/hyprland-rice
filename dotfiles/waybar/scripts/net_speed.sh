#!/bin/bash

INTERFACE=$(ip route | awk '/default/ {print $5; exit}')
STATE_FILE="/tmp/net_speed_${INTERFACE}"

curr_rx=$(< /sys/class/net/$INTERFACE/statistics/rx_bytes)
curr_time=$(date +%s)

# first run
if [ ! -f "$STATE_FILE" ]; then
    echo "$curr_rx $curr_time" > "$STATE_FILE"
    echo " 0KB/s"
    exit 0
fi

read prev_rx prev_time < "$STATE_FILE"

dt=$((curr_time - prev_time))
[ "$dt" -eq 0 ] && dt=1

rate=$(( (curr_rx - prev_rx) / dt / 1024 ))

# simple smoothing using last value
prev_rate_file="${STATE_FILE}_rate"

if [ -f "$prev_rate_file" ]; then
    prev_rate=$(< "$prev_rate_file")
    rate=$(( (rate + prev_rate) / 2 ))
fi

echo "$rate" > "$prev_rate_file"
echo "$curr_rx $curr_time" > "$STATE_FILE"

if [ "$rate" -ge 1024 ]; then
    echo " $((rate / 1024))MB/s"
else
    echo " ${rate}KB/s"
fi
