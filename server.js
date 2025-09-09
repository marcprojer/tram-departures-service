const express = require('express');
const axios = require('axios');
const cors = require('cors');

const STATION_KEY = 'Escher-Wyss-Platz'; // Beispiel: Zürich, Escher-Wyss-Platz
const PORT = 3000;
let cachedData = [];

async function fetchDepartures() {
    try {
        const res = await axios.get(
            `https://transport.opendata.ch/v1/stationboard?limit=10&transportations=tram&station=${encodeURIComponent(STATION_KEY)}`
        );
        cachedData = res.data.stationboard.map(dep => {
            // Hilfsfunktion für ISO-Format mit Zeitzone
            function toIsoWithTimezone(str) {
                if (!str) return null;
                // Falls schon ISO, einfach zurückgeben
                if (str.endsWith('Z') || str.match(/:\d\d[+-]\d\d:\d\d$/)) return str;
                // Wandelt z.B. 2025-09-09T12:34:56+0200 oder 2025-09-09 12:34:56+0200 in 2025-09-09T12:34:56+02:00
                // 1. Ersetze Leerzeichen durch T
                let iso = str.replace(' ', 'T');
                // 2. Füge Doppelpunkt in der Zeitzone ein
                iso = iso.replace(/([+-]\d{2})(\d{2})$/, '$1:$2');
                return iso;
            }
            return {
                linie: dep.number,
                richtung: dep.to,
                name: dep.name,
                abfahrt_geplant: toIsoWithTimezone(dep.stop.departure),
                abfahrt_live: dep.stop.prognosis ? toIsoWithTimezone(dep.stop.prognosis.departure) : null
            };
        });
    } catch (err) {
        console.error("Fehler beim Abrufen der Daten:", err.message);
    }
}

// Initial & alle 15 Sekunden aktualisieren
fetchDepartures();
setInterval(fetchDepartures, 15 * 1000);

const app = express();
app.use(cors());

app.get('/api/abfahrten', (req, res) => {
    res.json(cachedData);
});

// Optional: Web-Frontend
app.use(express.static('public'));

app.listen(PORT, () => {
    console.log(`Service läuft auf http://localhost:${PORT}`);
});