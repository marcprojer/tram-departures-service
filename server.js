const express = require('express');
const axios = require('axios');
const cors = require('cors');

const STATION_KEY = 'Escher-Wyss-Platz'; // Beispiel: Zürich, Escher-Wyss-Platz
const PORT = 3000;
let cachedData = { trams: [], buses: [] };

async function fetchDepartures() {
    try {
        const res = await axios.get(
            `https://transport.opendata.ch/v1/stationboard?limit=30&station=${encodeURIComponent(STATION_KEY)}`
        );
        function toIsoWithTimezone(str) {
            if (!str) return null;
            if (str.endsWith('Z') || str.match(/:\d\d[+-]\d\d:\d\d$/)) return str;
            let iso = str.replace(' ', 'T');
            iso = iso.replace(/([+-]\d{2})(\d{2})$/, '$1:$2');
            return iso;
        }
        const all = res.data.stationboard.map(dep => ({
            linie: dep.number,
            richtung: dep.to,
            name: dep.name,
            category: dep.category,
            abfahrt_geplant: toIsoWithTimezone(dep.stop.departure),
            abfahrt_live: dep.stop.prognosis ? toIsoWithTimezone(dep.stop.prognosis.departure) : null
        }));
        cachedData.trams = all.filter(d => d.category && d.category.toLowerCase() === 't')
            .sort((a, b) => {
                const aTime = a.abfahrt_live ? new Date(a.abfahrt_live) : new Date(a.abfahrt_geplant);
                const bTime = b.abfahrt_live ? new Date(b.abfahrt_live) : new Date(b.abfahrt_geplant);
                return aTime - bTime;
            })
            .slice(0, 15);
        cachedData.buses = all.filter(d => d.category && d.category.toLowerCase() === 'b')
            .sort((a, b) => {
                const aTime = a.abfahrt_live ? new Date(a.abfahrt_live) : new Date(a.abfahrt_geplant);
                const bTime = b.abfahrt_live ? new Date(b.abfahrt_live) : new Date(b.abfahrt_geplant);
                return aTime - bTime;
            })
            .slice(0, 15);
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