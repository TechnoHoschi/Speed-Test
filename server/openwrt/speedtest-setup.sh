#!/bin/sh
# speedtest-setup.sh
# Manuelles Setup-Script fuer OpenSpeedTest auf OpenWrt.
# Legt Testdateien in /tmp an und erstellt Symlinks im Webroot.
# Aufruf: sh speedtest-setup.sh

DL_FILE="/tmp/downloading"
UL_FILE="/tmp/upload"
DL_SIZE_MB=50
WWW_DIR="/www"

echo "[*] Erzeuge ${DL_SIZE_MB}MB Download-Testdatei in ${DL_FILE} ..."
dd if=/dev/urandom of="$DL_FILE" bs=1048576 count=$DL_SIZE_MB
echo "[+] ${DL_FILE} angelegt: $(du -sh $DL_FILE | cut -f1)"

echo "[*] Erzeuge leere Upload-Sink-Datei ${UL_FILE} ..."
: > "$UL_FILE"
echo "[+] ${UL_FILE} angelegt."

echo "[*] Erstelle Symlinks in ${WWW_DIR} ..."
ln -sf "$DL_FILE" "${WWW_DIR}/downloading"
ln -sf "$UL_FILE" "${WWW_DIR}/upload"
echo "[+] Symlinks:"
ls -la "${WWW_DIR}/downloading" "${WWW_DIR}/upload"

echo ""
echo "[*] Pruefe uhttpd follow_symlinks ..."
VAL=$(uci get uhttpd.main.follow_symlinks 2>/dev/null)
if [ "$VAL" = "1" ]; then
    echo "[+] follow_symlinks ist bereits aktiv."
else
    echo "[!] follow_symlinks ist NICHT gesetzt - wird jetzt aktiviert ..."
    uci set uhttpd.main.follow_symlinks=1
    uci commit uhttpd
    /etc/init.d/uhttpd restart
    echo "[+] uhttpd neu gestartet."
fi

echo ""
echo "================================================"
echo " Fertig! Speedtest erreichbar unter:"
ROUTER_IP=$(ip route get 1 2>/dev/null | awk '{print $NF; exit}' || echo "<router-ip>")
echo " http://${ROUTER_IP}/speedtest/"
echo "================================================"
