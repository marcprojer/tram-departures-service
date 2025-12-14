# Dockerfile für VBZ Tram Departures Service
FROM node:18-alpine

# Arbeitsverzeichnis erstellen
WORKDIR /app

# Package-Dateien kopieren und Dependencies installieren
COPY package*.json ./
RUN npm ci --only=production

# App-Code kopieren
COPY public ./public

# Port freigeben
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/abfahrten', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# App starten
CMD ["node", "public/resources/js/server.js"]
