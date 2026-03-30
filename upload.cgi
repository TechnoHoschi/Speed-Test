#!/bin/sh
# Upload-Test + Ping Endpoint fuer OpenSpeedTest auf OpenWrt
# POST: liest Body und verwirft ihn (kein Schreiben, kein IO)
# GET:  gibt "OK" zurueck (Ping-Messung, sauberer RTT)
dd if=/dev/stdin of=/dev/null bs=4096 2>/dev/null
printf 'Content-Type: text/plain\r\n'
printf '\r\n'
printf 'OK'
