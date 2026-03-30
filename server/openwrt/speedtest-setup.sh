#!/bin/sh
# speedtest-setup.sh - OpenSpeedTest Setup fuer OpenWrt
# Alles self-contained unter /www/speedtest/ - kein Eingriff in LuCI-Webroot
# Aufruf: sh speedtest-setup.sh

DL_SIZE_MB=50
SPEEDTEST_DIR="/www/speedtest"

# Sicherstellen dass /www/speedtest existiert
if [ ! -d "$SPEEDTEST_DIR" ]; then
    echo "[!] ${SPEEDTEST_DIR} existiert nicht - bitte zuerst Frontend-Dateien deployen!"
    echo "    scp -r assets index.html root@<router-ip>:/www/speedtest/"
    exit 1
fi

# Download: 50MB aus /dev/urandom nach /tmp (RAM)
echo "[*] Erzeuge ${DL_SIZE_MB}MB Download-Testdatei ..."
dd if=/dev/urandom of=/tmp/downloading bs=1048576 count=$DL_SIZE_MB
echo "[+] /tmp/downloading: $(du -sh /tmp/downloading | cut -f1)"

# Ping/Upload-Sink: winzige 3-Byte Datei fuer saubere RTT-Messung
# Upload-POST landet hier ebenfalls - Inhalt wird einfach ignoriert/ueberschrieben
echo "OK" > /tmp/ping

# Symlinks self-contained in /www/speedtest/
echo "[*] Erstelle Symlinks in ${SPEEDTEST_DIR} ..."
ln -sf /tmp/downloading "${SPEEDTEST_DIR}/downloading"
ln -sf /tmp/ping        "${SPEEDTEST_DIR}/upload"
echo "[+] Symlinks:"
ls -la "${SPEEDTEST_DIR}/downloading" "${SPEEDTEST_DIR}/upload"

# uhttpd follow_symlinks sicherstellen
echo ""
echo "[*] Pruefe uhttpd follow_symlinks ..."
if [ "$(uci get uhttpd.main.follow_symlinks 2>/dev/null)" = "1" ]; then
    echo "[+] follow_symlinks bereits aktiv."
else
    echo "[!] Aktiviere follow_symlinks ..."
    uci set uhttpd.main.follow_symlinks=1
    uci commit uhttpd
    /etc/init.d/uhttpd restart
    echo "[+] uhttpd neu gestartet."
fi

ROUTER_IP=$(ip route get 1 2>/dev/null | awk '{print $NF; exit}' || echo "<router-ip>")
echo ""
echo "================================================"
echo " Fertig! Browser aufmachen:"
echo " http://${ROUTER_IP}/speedtest/"
echo "================================================"
