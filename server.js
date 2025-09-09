const express = require('express');
const axios = require('axios');
const cors = require('cors');

const STATION_ID = '8580522'; // Beispiel: Zürich, Hardplatz
const PORT = 3000;
let cachedData = [];

async function fetchDepartures() {
    try {
        const res = await axios.get(
            `https://transport.opendata.ch/v1/stationboard?limit=5&transportations=tram&id=${STATION_ID}`
        );
        cachedData = res.data.stationboard.map(dep => ({
            linie: dep.number,
            richtung: dep.to,
            abfahrt_geplant: dep.stop.departure,
            abfahrt_live: dep.stop.prognosis ? dep.stop.prognosis.departure : null
        }));
    } catch (err) {
        console.error("Fehler beim Abrufen der Daten:", err.message);
    }
}

// Initial & alle 90 Sekunden aktualisieren
fetchDepartures();
setInterval(fetchDepartures, 90 * 1000);

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