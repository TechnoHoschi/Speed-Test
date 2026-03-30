#!/bin/sh
# Ping-Test Endpoint fuer OpenSpeedTest auf OpenWrt
# Pingt den Client ($REMOTE_ADDR) via ICMP und gibt die avg RTT zurueck
printf 'Content-Type: text/plain\r\n'
printf 'Access-Control-Allow-Origin: *\r\n'
printf '\r\n'
RESULT=$(ping -c 4 -W 1 "$REMOTE_ADDR" 2>/dev/null | tail -1 | awk -F'/' '{printf "%.1f", $5}')
if [ -z "$RESULT" ]; then
    printf 'N/A'
else
    printf '%s' "$RESULT"
fi
