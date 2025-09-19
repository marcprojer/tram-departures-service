# 🚋 Tram Departures Service - Docker Deployment Guide

## 📋 Übersicht

Diese Anleitung beschreibt, wie du die Tram Departures Service Anwendung mit Docker auf deinem Proxmox Server deployest - sowohl über die Kommandozeile als auch über **Portainer** (empfohlen für einfache Verwaltung).

## 🛠 Voraussetzungen

### Auf deinem Proxmox Server:
- Ubuntu/Debian LXC Container oder VM
- Docker und Docker Compose installiert
- Git installiert
- Mindestens 1GB RAM und 10GB Speicher
- Port 3000 verfügbar (oder anderen gewünschten Port)

## � Deployment mit Portainer (Empfohlen)

### 1. Portainer Stack erstellen

1. **Öffne Portainer** in deinem Browser (z.B. `http://your-proxmox-ip:9000`)
2. **Gehe zu "Stacks"** im linken Menü
3. **Klicke auf "Add stack"**
4. **Name eingeben**: `tram-departures`
5. **Repository auswählen**: "Git repository"

### 2. Stack-Konfiguration

**⚠️ Für private Repositories benötigst du Authentifizierung!**

**Repository URL**: `https://github.com/marcprojer/tram-departures-service.git`
**Reference**: `refs/heads/main`
**Compose path**: `docker-compose.yml`
**Authentication**: Siehe "Private Repository Setup" unten

**Environment variables** (optional):
```
NODE_ENV=production
PORT=3000
```

### 3. Stack deployen

1. **Klicke auf "Deploy the stack"**
2. **Warte bis Status "Running" angezeigt wird**
3. **Teste unter**: `http://your-server-ip:3000`

### 4. Updates mit Portainer

**Super einfach - nur 3 Klicks!**
1. **Gehe zu deinem Stack** "tram-departures"
2. **Klicke auf "Update this stack"**
3. **Aktiviere "Re-pull image"** und **"Prune unused images"**
4. **Klicke "Update"**

Das war's! Portainer pullt automatisch die neueste Version vom Git und deployed sie.

## 🔐 Private Repository Setup

Da dein GitHub-Repository privat ist, benötigst du Authentifizierung. Hier sind die Optionen:

### Option 1: Personal Access Token (Empfohlen für Portainer)

1. **GitHub Personal Access Token erstellen**:
   - Gehe zu GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - "Generate new token" → **Repository access** auf dein Repository beschränken
   - **Permissions**: `Contents: Read`, `Metadata: Read`
   - Token kopieren (wird nur einmal angezeigt!)

2. **In Portainer verwenden**:
   - Repository URL: `https://USERNAME:TOKEN@github.com/marcprojer/tram-departures-service.git`
   - Ersetze `USERNAME` mit deinem GitHub-Username
   - Ersetze `TOKEN` mit dem Personal Access Token

### Option 2: SSH Key (Sicherer, aber komplexer)

1. **SSH Key auf dem Server erstellen**:
   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/tram-deployment
   ```

2. **Public Key zu GitHub hinzufügen**:
   - Kopiere: `cat ~/.ssh/tram-deployment.pub`
   - GitHub → Settings → SSH and GPG keys → New SSH key
   - Füge den Public Key ein

3. **In Portainer**:
   - Repository URL: `git@github.com:marcprojer/tram-departures-service.git`
   - SSH Key hinzufügen in Portainer

### Option 3: Repository öffentlich machen

**Einfachste Lösung**: Repository auf "Public" setzen
- GitHub → Repository Settings → Danger Zone → Change visibility → Make public

### Option 4: Lokaler Git Clone (Fallback)

Falls Portainer-Git nicht funktioniert:

```bash
# Auf dem Server:
git clone https://github.com/marcprojer/tram-departures-service.git /opt/tram-departures
cd /opt/tram-departures

# Authentifizierung einrichten (einmalig):
git config credential.helper store
git pull  # Username und Token eingeben

# Dann normale Portainer-Stack mit lokaler docker-compose.yml
```

---

## 🚀 Alternative: Kommandozeilen-Installation

### 1. Docker Installation (falls noch nicht installiert)

```bash
# Docker installieren
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker

# User zu docker Gruppe hinzufügen
sudo usermod -aG docker $USER
# Logout und Login erforderlich!
```

### 2. Repository klonen

```bash
# Arbeitsverzeichnis erstellen
sudo mkdir -p /opt/tram-departures
sudo chown $USER:$USER /opt/tram-departures
cd /opt/tram-departures

# Repository klonen
git clone https://github.com/marcprojer/tram-departures-service.git .
```

### 3. Environment konfigurieren

```bash
# Environment-Datei erstellen
cp .env.example .env

# Optional: Konfiguration anpassen
nano .env
```

### 4. Erste Deployment

```bash
# Deployment starten
./deploy.sh deploy

# Logs anzeigen
./deploy.sh logs
```

Die Anwendung ist nun unter `http://YOUR-SERVER-IP:3000` verfügbar!

## 🔄 Updates deployen

### Einfacher Update-Prozess:

```bash
# In das Deployment-Verzeichnis wechseln
cd /opt/tram-departures

# Update ausführen
./deploy.sh deploy
```

Das war's! Das Script:
1. ✅ Pullt automatisch die neueste Version vom Git
2. ✅ Baut ein neues Docker Image
3. ✅ Stoppt den alten Container
4. ✅ Startet den neuen Container
5. ✅ Überprüft die Gesundheit der Anwendung
6. ✅ Räumt alte Images auf

### Weitere Deployment-Befehle:

```bash
./deploy.sh status      # Container-Status anzeigen
./deploy.sh logs        # Live-Logs anzeigen
./deploy.sh restart     # Anwendung neustarten
./deploy.sh stop        # Anwendung stoppen
./deploy.sh start       # Anwendung starten
```

## 🔧 Konfiguration

### Port ändern:
Bearbeite `docker-compose.yml`:
```yaml
ports:
  - "8080:3000"  # Externer Port 8080, interner Port 3000
```

### Reverse Proxy (Traefik/Nginx):
Die `docker-compose.yml` enthält bereits Traefik-Labels. Für Nginx:

```nginx
server {
    listen 80;
    server_name tram.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 📊 Monitoring

### Container-Status prüfen:
```bash
# Container-Status
docker ps | grep tram-departures

# Ressourcen-Verbrauch
docker stats tram-departures-app

# Logs der letzten 100 Zeilen
docker logs --tail 100 tram-departures-app
```

### Health Check:
```bash
# Automatischer Health Check
curl http://localhost:3000/api/health

# Oder über das Script
./deploy.sh status
```

## 🆘 Troubleshooting

### Container startet nicht:
```bash
# Logs anzeigen
./deploy.sh logs

# Container-Details
docker inspect tram-departures-app

# Port-Konflikte prüfen
sudo netstat -tulpn | grep 3000
```

### Speicherplatz aufräumen:
```bash
# Ungenutzte Images löschen
docker image prune -a

# Ungenutzte Container löschen
docker container prune

# Alles auf einmal (Vorsicht!)
docker system prune -a
```

### Rollback bei Problemen:
```bash
# Zum vorherigen Image zurück
docker run -d --name tram-departures-app -p 3000:3000 tram-departures:previous

# Oder manuell eine ältere Version deployen
git checkout <commit-hash>
./deploy.sh deploy
```

## 🔐 Sicherheit

### Firewall konfigurieren:
```bash
# Nur Port 3000 für Docker öffnen
sudo ufw allow 3000/tcp

# Oder für Reverse Proxy nur 80/443
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### Automatische Updates:
```bash
# Cron-Job für automatische Updates (täglich um 2 Uhr)
echo "0 2 * * * cd /opt/tram-departures && ./deploy.sh deploy >> /var/log/tram-deployment.log 2>&1" | crontab -
```

## 📁 Dateistruktur

```
/opt/tram-departures/
├── Dockerfile              # Container-Definition
├── docker-compose.yml      # Orchestrierung
├── deploy.sh               # Deployment-Script
├── .env                    # Environment-Variablen
├── .dockerignore          # Docker-Ignore-Datei
├── package.json           # Node.js Dependencies
├── public/                # Frontend-Dateien
│   ├── homeassistant.html
│   └── resources/
└── README.md              # Diese Anleitung
```

## 🎯 Best Practices

1. **Regelmäßige Backups**: Sichere `/opt/tram-departures` und deine `.env` Datei
2. **Log-Rotation**: Konfiguriere Docker-Log-Rotation in `/etc/docker/daemon.json`
3. **Monitoring**: Nutze `docker stats` oder Tools wie Portainer für Überwachung
4. **Updates**: Teste Updates zuerst in einer Entwicklungsumgebung
5. **Sicherheit**: Halte Docker und das Host-System aktuell

## 📞 Support

Bei Problemen:
1. Prüfe die Logs: `./deploy.sh logs`
2. Prüfe den Container-Status: `./deploy.sh status`
3. Prüfe die GitHub Issues des Repositories
4. Erstelle ein neues Issue mit Log-Ausgaben

---

**Viel Erfolg mit deinem Tram Departures Service! 🚋✨**