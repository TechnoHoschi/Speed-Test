#!/bin/sh
# speedtest-setup.sh
# OpenSpeedTest Setup fuer OpenWrt
# Erzeugt Testdatei in /tmp (RAM) und setzt Symlinks im Webroot.
# Aufruf: sh speedtest-setup.sh

DL_SIZE_MB=50
WWW_DIR="/www"

# --- Download: 50MB aus /dev/urandom in /tmp ---
echo "[*] Erzeuge ${DL_SIZE_MB}MB Download-Testdatei ..."
dd if=/dev/urandom of=/tmp/downloading bs=1048576 count=$DL_SIZE_MB
echo "[+] /tmp/downloading: $(du -sh /tmp/downloading | cut -f1)"

# --- Upload: /dev/null als Sink (kein IO, kein Write-Contention) ---
# Kein echter File noetig - Browser sendet Daten, Router verwirft sie sofort
echo "[*] Setze Upload-Sink auf /dev/null ..."

# --- Symlinks in Webroot ---
echo "[*] Erstelle Symlinks ..."
ln -sf /tmp/downloading "${WWW_DIR}/downloading"
ln -sf /dev/null        "${WWW_DIR}/upload"
ls -la "${WWW_DIR}/downloading" "${WWW_DIR}/upload"

# --- uhttpd: follow_symlinks sicherstellen ---
echo ""
echo "[*] Pruefe uhttpd follow_symlinks ..."
if [ "$(uci get uhttpd.main.follow_symlinks 2>/dev/null)" = "1" ]; then
    echo "[+] follow_symlinks bereits aktiv."
else
    echo "[!] Aktiviere follow_symlinks und starte uhttpd neu ..."
    uci set uhttpd.main.follow_symlinks=1
    uci commit uhttpd
    /etc/init.d/uhttpd restart
    echo "[+] uhttpd neu gestartet."
fi

# --- Ergebnis ---
ROUTER_IP=$(ip route get 1 2>/dev/null | awk '{print $NF; exit}' || echo "<router-ip>")
echo ""
echo "================================================"
echo " Fertig! Browser aufmachen:"
echo " http://${ROUTER_IP}/speedtest/"
echo "================================================"
