# OpenWrt Setup – /tmp-based Test Files

Dieses Setup legt die Speedtest-Dateien beim Router-Start automatisch in `/tmp` (RAM) an.
Kein Flash-Speicher wird für Testdaten belegt. `/tmp` ist auf OpenWrt immer tmpfs (RAM).

## Funktionsweise

| Datei | Pfad | Quelle |
|---|---|---|
| Download-Testdatei | `/tmp/downloading` | 50 MB aus `/dev/urandom` |
| Upload-Sink | `/tmp/upload` | leere Datei, wird überschrieben |
| Webroot-Symlink Download | `/www/downloading` → `/tmp/downloading` | automatisch |
| Webroot-Symlink Upload | `/www/upload` → `/tmp/upload` | automatisch |

`/dev/urandom` statt `/dev/zero`: Viele Browser/Proxies komprimieren HTTP-Traffic.
Mit echten Zufallsdaten wird Kompression verhindert und das Ergebnis ist realistischer.

## Installation

```sh
# 1. Frontend-Dateien auf den Router kopieren
scp -r assets index.html hosted.html root@192.168.1.1:/www/speedtest/

# 2. Init-Script installieren
scp server/openwrt/speedtest-init root@192.168.1.1:/etc/init.d/speedtest-init
ssh root@192.168.1.1 'chmod +x /etc/init.d/speedtest-init'

# 3. Autostart aktivieren und sofort starten (erzeugt /tmp/dateien + Symlinks)
ssh root@192.168.1.1 'service speedtest-init enable && service speedtest-init start'
```

## uhttpd – Symlinks erlauben

Standardmäßig folgt uhttpd auf OpenWrt keinen Symlinks außerhalb des Webroots.
Einmalig in `/etc/config/uhttpd` folgende Option setzen:

```
config httpd 'main'
    option follow_symlinks '1'
```

Dann:
```sh
/etc/init.d/uhttpd restart
```

## Benutzung

Browser öffnen: `http://<router-ip>/speedtest/`

Der Test läuft komplett zwischen Client und Router, kein Internet erforderlich.

## RAM-Bedarf

- 50 MB für `/tmp/downloading` (aus `/dev/urandom`)
- Upload überschreibt `/tmp/upload` – max. so groß wie `ulDataSize` in `index.html` (Standard: 30 MB)
- Gesamt worst-case: ~80 MB RAM für Testdaten

Beim BE450 mit ausreichend RAM kein Problem. Bei knappem RAM `DL_SIZE_MB` im Init-Script reduzieren.

## Reboot-Verhalten

`/tmp` wird bei jedem Reboot geleert. Das Init-Script (START=99) regeneriert die Dateien
automatisch beim nächsten Boot. Symlinks im Webroot werden ebenfalls neu angelegt.
