#!/bin/sh
# Download-Test Endpoint fuer OpenSpeedTest auf OpenWrt
# Streamt 30MB direkt aus /dev/zero (RAM) - keine Datei, kein Flash, kein Setup
SIZE=$((30 * 1048576))
printf 'Content-Type: application/octet-stream\r\n'
printf 'Content-Length: %d\r\n' $SIZE
printf 'Cache-Control: no-store\r\n'
printf '\r\n'
dd if=/dev/zero bs=1048576 count=30 2>/dev/null
