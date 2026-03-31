# OpenSpeedTest – OpenWrt / uhttpd CGI Fork

> **TL;DR:** OpenSpeedTest ohne NGINX, ohne Docker, ohne statische Download-Dateien – läuft direkt auf OpenWrt via uhttpd und zwei Shell-CGIs. Weil manchmal muss es einfach der Router selbst richten.

Dieses Repository ist ein Fork von [OpenSpeedTest™](https://openspeedtest.com) und wurde für den Betrieb auf **OpenWrt mit uhttpd** angepasst. Das Original setzt NGINX oder Docker voraus. Beides ist auf einem Router-SoC entweder nicht verfügbar oder eine schlechte Idee.

Die eigentliche Arbeit hat größtenteils eine KI erledigt. Der Mensch hat primär auf den "Deploy"-Button gedrückt, Kaffee getrunken und gelegentlich den Browser-Tab neu geladen. Klassisches Vibecoding – aber es funktioniert.

---

## Was wurde geändert?

| Original | Dieser Fork |
|---|---|
| Benötigt NGINX/Docker | Läuft auf uhttpd (OpenWrt built-in) |
| Statische Download-Dateien | `downloading.cgi` streamt aus `/dev/zero` (kein Flash-Verschleiß) |
| Upload via Static-File-POST | `upload.cgi` verwirft Body via `dd` nach exakt `CONTENT_LENGTH` Bytes |
| Kein ICMP-Ping | `ping.cgi` pingt den Client via `$REMOTE_ADDR` und gibt echte RTT zurück |
| CGIs in `/cgi-bin/` | CGIs in `/www/cgi-bin/` mit `cgi_prefix=/cgi-bin` |
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

```sh
opkg update
opkg install uhttpd uhttpd-mod-ucode
```

### CGIs deployen

```sh
mkdir -p /www/speedtest /www/cgi-bin

# Frontend
wget -O /www/speedtest/index.html https://raw.githubusercontent.com/TechnoHoschi/Speed-Test/main/index.html

# CGIs
wget -O /www/cgi-bin/downloading.cgi https://raw.githubusercontent.com/TechnoHoschi/Speed-Test/main/downloading.cgi
wget -O /www/cgi-bin/upload.cgi https://raw.githubusercontent.com/TechnoHoschi/Speed-Test/main/upload.cgi
wget -O /www/cgi-bin/ping.cgi https://raw.githubusercontent.com/TechnoHoschi/Speed-Test/main/ping.cgi
chmod +x /www/cgi-bin/*.cgi
```

### Assets deployen

```sh
# assets/ Verzeichnis aus dem Repo ins Frontend kopieren
# (per scp, wget oder git clone)
```

### uhttpd konfigurieren

```sh
uci set uhttpd.main.cgi_prefix='/cgi-bin'
uci set uhttpd.main.network_timeout='120'
uci set uhttpd.main.script_timeout='120'
uci set uhttpd.main.max_requests='20'
uci commit uhttpd
service uhttpd restart
```

### Aufrufen

```
http://<router-ip>/speedtest/index.html
```

---

## Bekannte Eigenheiten

- **Ping-Anzeige im Framework (~60ms):** Das OpenSpeedTest-JS misst Ping via XHR-Roundtrip, nicht via ICMP. Der Browser-Stack addiert ~55ms Overhead. Der echte LAN-Ping (unten rechts als ICMP-Overlay) ist deutlich realistischer.
- **NS_BINDING_ABORTED im Browser-Log:** Normal. Das JS bricht Download/Upload-Requests nach Ablauf der Messdauer absichtlich ab.
- **LuCI läuft parallel:** Solange `uhttpd-mod-ucode` installiert ist, verträgt sich `cgi_prefix=/cgi-bin` problemlos mit LuCI. Falls nicht – `opkg install uhttpd-mod-ucode` rettet den Tag.

---

## Lizenz

MIT License – Copyright (c) 2013–2024 OpenSpeedTest™

Dieser Fork übernimmt die MIT-Lizenz des Originals. Siehe [License.md](License.md).
