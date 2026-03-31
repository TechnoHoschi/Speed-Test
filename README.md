# OpenSpeedTest – OpenWrt / uhttpd CGI Fork

> **TL;DR:** OpenSpeedTest ohne NGINX, ohne Docker, ohne statische Download-Dateien – läuft direkt auf OpenWrt via uhttpd und drei Shell-CGIs. Weil manchmal muss es einfach der Router selbst richten.

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
opkg update && opkg install uhttpd git git-http
```

> `cgi_prefix=/cgi-bin` ist OpenWrt-Default – da muss nichts verbogen werden. LuCI bleibt unangetastet.

### Sicherstellen dass `/www/cgi-bin` existiert

```sh
[ -d /www/cgi-bin ] || { echo "ERROR: /www/cgi-bin nicht gefunden. uhttpd korrekt konfiguriert?"; exit 1; }
```

Wenn dieser Check fehlschlägt: nicht einfach den Ordner anlegen. Erst prüfen ob uhttpd läuft und `cgi_prefix` gesetzt ist (`uci get uhttpd.main.cgi_prefix`).

### Repo klonen

Der einfachste Weg – holt alles auf einmal inkl. `assets/` (CSS, JS, Fonts, Images):

```sh
cd /www
git clone https://github.com/TechnoHoschi/Speed-Test.git speedtest
```

### CGIs an Ort und Stelle bringen

```sh
cp /www/speedtest/downloading.cgi /www/cgi-bin/
cp /www/speedtest/upload.cgi /www/cgi-bin/
cp /www/speedtest/ping.cgi /www/cgi-bin/

# Nur unsere eigenen CGIs executable machen - LuCI nicht anfassen!
chmod +x /www/cgi-bin/downloading.cgi /www/cgi-bin/upload.cgi /www/cgi-bin/ping.cgi
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

```sh
cd /www/speedtest && git pull
cp downloading.cgi upload.cgi ping.cgi /www/cgi-bin/
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
