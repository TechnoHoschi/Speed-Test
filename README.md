# OpenSpeedTest – OpenWrt / uhttpd CGI Fork

> **TL;DR:** OpenSpeedTest ohne NGINX, ohne Docker, ohne statische Download-Dateien – läuft direkt auf OpenWrt via uhttpd und drei Shell-CGIs. Weil manchmal muss es einfach der Router selbst richten.

Dieses Repository ist ein Fork von [OpenSpeedTest™](https://openspeedtest.com) und wurde für den Betrieb auf **OpenWrt mit uhttpd** angepasst. Das Original setzt NGINX oder Docker voraus. Beides ist auf einem Router-SoC entweder nicht verfügbar oder eine schlechte Idee.

Die eigentliche Arbeit hat größtenteils eine KI erledigt. Der Mensch hat primär auf den "Deploy"-Button gedrückt, Kaffee getrunken und gelegentlich den Browser-Tab neu geladen. Klassisches Vibecoding – aber es funktioniert.

---

## Was wird hier eigentlich gemessen?

> ⚠️ **Wichtig:** Dieser Speedtest misst die Geschwindigkeit zwischen dem Client (Browser) und der **LAN-Schnittstelle des Routers** – **nicht** die Internetgeschwindigkeit.

Das ist kein Bug, sondern der Sinn der Sache. Du misst damit:
- Die Leistung deines LAN/WLAN-Links zum Router
- Den Durchsatz des Router-SoC beim Streamen/Empfangen
- Ob dein Switch, dein Patchkabel oder deine WLAN-Verbindung der Flaschenhals ist

Für einen WAN-Speedtest (Internet) nimm [fast.com](https://fast.com) oder [speedtest.net](https://speedtest.net).

---

## Was wurde geändert?

| Original | Dieser Fork |
|---|---|
| Benötigt NGINX/Docker | Läuft auf uhttpd (OpenWrt built-in) |
| Statische Download-Dateien | `downloading.cgi` streamt aus `/dev/zero` (kein Flash-Verschleiß) |
| Upload via Static-File-POST | `upload.cgi` verwirft Body via `dd` nach exakt `CONTENT_LENGTH` Bytes |
| Kein ICMP-Ping | `ping.cgi` pingt den Client via `$REMOTE_ADDR` und gibt echte RTT zurück |
| Frontend in docroot | Frontend in `/www/speedtest/`, Endpoints absolut via `/cgi-bin/` referenziert |

---

## Hardware-Anforderungen

Das läuft nicht auf jedem OpenWrt-Router. Ein GL.iNet AR300M mit 64MB RAM und MIPS-SoC aus 2017 wird an 10 parallelen CGI-Threads und `/dev/zero`-Streaming herzlich wenig Freude haben.

**Getestet auf:** TP-Link BE450 (WiFi 7, ARM-SoC, ausreichend RAM) – funktioniert problemlos.

**Sollte ebenfalls funktionieren:**
- Banana Pi R3 / R4 (MediaTek Filogic, ernstzunehmende Hardware)
- ASUS BT-8 (ähnliche Liga)
- Generell: alles mit ARM64-SoC, ≥256MB RAM und GbE

**Wird wahrscheinlich leiden:** Alles mit MIPS, <128MB RAM oder einem SoC der hauptsächlich als Briefbeschwerer taugt.

---

## Installation

### Voraussetzungen

`wget` und `tar` sind auf OpenWrt standardmäßig verfügbar – keine zusätzlichen Pakete nötig.

> `cgi_prefix=/cgi-bin` ist OpenWrt-Default – da muss nichts verbogen werden. LuCI bleibt unangetastet.

### Sicherstellen dass `/www/cgi-bin` existiert

```sh
[ -d /www/cgi-bin ] || { echo "ERROR: /www/cgi-bin nicht gefunden. uhttpd korrekt konfiguriert?"; exit 1; }
```

### Deployen

```sh
cd /tmp
wget -O openspeedtest.tar.gz https://github.com/TechnoHoschi/openspeedtest-openwrt/archive/refs/heads/main.tar.gz
tar -xzf openspeedtest.tar.gz
mv openspeedtest-openwrt-main /www/speedtest

# CGIs ins richtige Verzeichnis
cp /www/speedtest/downloading.cgi /www/cgi-bin/
cp /www/speedtest/upload.cgi      /www/cgi-bin/
cp /www/speedtest/ping.cgi        /www/cgi-bin/
chmod +x /www/cgi-bin/downloading.cgi /www/cgi-bin/upload.cgi /www/cgi-bin/ping.cgi

# Aufräumen
rm /tmp/openspeedtest.tar.gz
```

### uhttpd Timeouts anpassen

```sh
uci set uhttpd.main.network_timeout='120'
uci set uhttpd.main.script_timeout='120'
uci set uhttpd.main.max_requests='20'
uci commit uhttpd
service uhttpd restart
```

### Aufrufen

```
http://<router-ip>/speedtest/
```

### Updates

Installation wiederholen – bestehende `/www/speedtest` vorher löschen:

```sh
rm -rf /www/speedtest
```

---

## Bekannte Eigenheiten

- **Ping-Anzeige im Framework (~60ms):** Das OpenSpeedTest-JS misst Ping via XHR-Roundtrip, nicht via ICMP. Der Browser-Stack addiert ~55ms Overhead. Der echte LAN-Ping (unten rechts als ICMP-Overlay) ist deutlich realistischer.
- **NS_BINDING_ABORTED im Browser-Log:** Normal. Das JS bricht Download/Upload-Requests nach Ablauf der Messdauer absichtlich ab.
- **LuCI läuft parallel:** Solange `cgi_prefix=/cgi-bin` der Default bleibt und wir keine fremden Dateien anpacken, koexistieren LuCI und der Speedtest ohne Probleme.

---

## Lizenz

MIT License – Copyright (c) 2013–2024 OpenSpeedTest™

Dieser Fork übernimmt die MIT-Lizenz des Originals. Siehe [License.md](License.md).
