# 🐳 Portainer Deployment Guide - Tram Departures Service

## 🎯 Schnellstart mit Portainer

### Methode 1: Git Repository Stack (Empfohlen)

1. **Portainer öffnen**: `http://your-proxmox-ip:9000`
2. **Neuen Stack erstellen**:
   - Name: `tram-departures`
   - Build method: **"Git repository"** auswählen
   
   **⚠️ Für Private Repository**:
   - Repository URL: `https://USERNAME:TOKEN@github.com/marcprojer/tram-departures-service`
   - Ersetze `USERNAME` und `TOKEN` mit deinen GitHub-Credentials
   
   **Für Public Repository**:
   - Repository URL: `https://github.com/marcprojer/tram-departures-service`
   
   - Reference: `refs/heads/main`
   - Compose path: `docker-compose.yml`

3. **Environment variables** (optional):
   ```
   DOMAIN=yourdomain.com
   NODE_ENV=production
   ```

4. **Deploy klicken** ✅

### Methode 2: Copy-Paste Stack

1. **Portainer öffnen** und **"Add stack"**
2. **Name**: `tram-departures`
3. **Web editor** auswählen
4. **Folgenden Code einfügen**:

```yaml
version: '3.8'

services:
  tram-departures:
    image: node:18-alpine
    container_name: tram-departures-app
    restart: unless-stopped
    working_dir: /app
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
    command: >
      sh -c "
        apk add --no-cache git &&
        git clone https://github.com/marcprojer/tram-departures-service.git . &&
        npm install &&
        node public/resources/js/server.js
      "
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

5. **Deploy klicken** ✅

## 🔄 Updates durchführen

### Mit Git Repository Stack:
1. **Stack auswählen** → `tram-departures`
2. **"Update this stack"** klicken
3. **"Re-pull image"** aktivieren
4. **"Prune unused images"** aktivieren  
5. **"Update"** klicken ✅

### Mit Copy-Paste Stack:
1. **Stack auswählen** → `tram-departures`
2. **"Update this stack"** klicken
3. **"Recreate"** aktivieren
4. **"Update"** klicken ✅

## 📊 Monitoring in Portainer

### Container-Status anzeigen:
- **Containers** → `tram-departures-app`
- **Quick actions**: Start, Stop, Restart, Kill
- **Stats**: CPU, Memory, Network

### Logs anzeigen:
- **Container auswählen** → **"Logs"**
- **Live-Logs**: "Auto-refresh logs" aktivieren
- **Log-Filter**: Nach Zeitraum oder Text suchen

### Health Check:
- **Container-Details** → **"Health"** Tab
- Status: Healthy/Unhealthy/Starting
- **Test-URL**: `http://your-server:3000`

## ⚙️ Portainer-spezifische Konfiguration

### Port-Mapping ändern:
1. **Stack bearbeiten**
2. **Ports-Sektion** ändern:
   ```yaml
   ports:
     - "8080:3000"  # Externer Port 8080
   ```

### Environment-Variablen:
1. **Stack bearbeiten**
2. **Environment variables** Tab
3. **Neue Variable hinzufügen**:
   - `NODE_ENV=production`
   - `CUSTOM_PORT=3000`

### Automatische Updates mit Watchtower:
1. **Neuen Stack erstellen**: `watchtower`
2. **Code einfügen**:
```yaml
version: '3.8'
services:
  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_SCHEDULE=0 0 2 * * *  # Täglich um 2 Uhr
    command: --label-enable
```

## 🔧 Erweiterte Portainer-Features

### Reverse Proxy mit Traefik:
```yaml
# In deinem Stack hinzufügen:
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.tram.rule=Host(`tram.yourdomain.com`)"
  - "traefik.http.routers.tram.tls=true"
```

### Backup-Strategie:
1. **Stacks** → **Export** (JSON-Download)
2. **Volumes** → **Browse** → **Download** (falls Daten)
3. **Settings** → **Backup** (Portainer-Konfiguration)

### Resource Limits:
```yaml
# In der Service-Definition:
deploy:
  resources:
    limits:
      memory: 512M
      cpus: '0.5'
    reservations:
      memory: 256M
```

## 🆘 Troubleshooting in Portainer

### Container startet nicht:
1. **Container-Details** → **"Logs"** Tab
2. **"Events"** Tab für System-Events
3. **"Inspect"** für detaillierte Konfiguration

### Netzwerk-Probleme:
1. **Networks** Tab → **"tram-network"** prüfen
2. **Port-Konflikte**: `docker ps` oder Container-Übersicht
3. **Firewall**: Host-System prüfen

### Performance-Überwachung:
1. **Dashboard** → **Container-Stats**
2. **Individual Container** → **"Stats"** Tab
3. **Host-Übersicht** für System-Ressourcen

## 🎉 Vorteile von Portainer

✅ **Visual Management**: Keine Kommandozeile nötig
✅ **One-Click Updates**: Einfache Stack-Updates  
✅ **Live-Monitoring**: Real-time Logs und Stats
✅ **Team-Management**: Benutzer und Rollen
✅ **Backup/Restore**: Stack-Export/Import
✅ **Template-System**: Wiederverwendbare Konfigurationen

---

**Mit Portainer wird Docker-Management zum Kinderspiel! 🚀**