#!/bin/sh
# speedtest-setup.sh - OpenSpeedTest Setup fuer OpenWrt
# Upload/Ping: wird per CGI (upload.cgi) erledigt - kein Symlink noetig
# Nur noch: Download-Testdatei in RAM erzeugen + Symlink setzen
# Aufruf: sh speedtest-setup.sh

DL_SIZE_MB=50
SPEEDTEST_DIR="/www/speedtest"

if [ ! -d "$SPEEDTEST_DIR" ]; then
    echo "[!] ${SPEEDTEST_DIR} nicht gefunden."
    echo "    Erst Frontend deployen: scp -r assets index.html speedtest/upload.cgi root@<ip>:/www/speedtest/"
    exit 1
fi

# Download-Testdatei in RAM erzeugen
echo "[*] Erzeuge ${DL_SIZE_MB}MB Download-Testdatei in /tmp ..."
dd if=/dev/urandom of=/tmp/downloading bs=1048576 count=$DL_SIZE_MB
echo "[+] /tmp/downloading: $(du -sh /tmp/downloading | cut -f1)"

# Symlink im Speedtest-Verzeichnis
ln -sf /tmp/downloading "${SPEEDTEST_DIR}/downloading"
echo "[+] Symlink: ${SPEEDTEST_DIR}/downloading -> /tmp/downloading"

# upload.cgi ausfuehrbar machen falls noetig
chmod +x "${SPEEDTEST_DIR}/upload.cgi"

# uhttpd: follow_symlinks + cgi_prefix
echo ""
echo "[*] Konfiguriere uhttpd ..."
CHANGED=0
if [ "$(uci get uhttpd.main.follow_symlinks 2>/dev/null)" != "1" ]; then
    uci set uhttpd.main.follow_symlinks=1
    CHANGED=1
fi
if [ "$(uci get uhttpd.main.cgi_prefix 2>/dev/null)" != "/speedtest" ]; then
    uci set uhttpd.main.cgi_prefix=/speedtest
    CHANGED=1
fi
if [ "$CHANGED" = "1" ]; then
    uci commit uhttpd
    /etc/init.d/uhttpd restart
    echo "[+] uhttpd neu gestartet."
else
    echo "[+] uhttpd bereits korrekt konfiguriert."
fi

# Schnelltest
echo ""
echo "[*] Schnelltest ..."
DL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/speedtest/downloading -r 0-100)
UL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://127.0.0.1/speedtest/upload.cgi --data "test")
echo "    GET /speedtest/downloading : HTTP ${DL_STATUS}"
echo "    POST /speedtest/upload.cgi : HTTP ${UL_STATUS}"

ROUTER_IP=$(ip route get 1 2>/dev/null | awk '{print $NF; exit}' || echo "<router-ip>")
echo ""
echo "================================================"
echo " Fertig! Browser aufmachen:"
echo " http://${ROUTER_IP}/speedtest/"
echo "================================================"
