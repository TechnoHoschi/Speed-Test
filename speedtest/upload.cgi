#!/bin/sh
# Upload sink + Ping endpoint fuer OpenSpeedTest auf OpenWrt
# - POST: liest Body und verwirft ihn (Upload-Test)
# - GET:  gibt "OK" zurueck (Ping-Messung)
dd if=/dev/stdin of=/dev/null bs=4096 2>/dev/null
echo -e "Content-Type: text/plain\n\nOK"
