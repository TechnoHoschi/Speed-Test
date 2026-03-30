#!/bin/sh
# Upload-Test + Ping Endpoint fuer OpenSpeedTest auf OpenWrt
# POST: liest exakt CONTENT_LENGTH Bytes und verwirft sie
# GET:  gibt "OK" zurueck (Ping-Messung, sauberer RTT)
if [ "$REQUEST_METHOD" = "POST" ] && [ -n "$CONTENT_LENGTH" ] && [ "$CONTENT_LENGTH" -gt 0 ]; then
    dd if=/dev/stdin of=/dev/null bs=4096 count=$(( (CONTENT_LENGTH + 4095) / 4096 )) 2>/dev/null
fi
printf 'Content-Type: text/plain\r\n'
printf '\r\n'
printf 'OK'
