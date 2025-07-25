const express = require('express');
const fs = require('fs');
const cors = require('cors');
const app = express();
app.use(cors());
app.use(express.json());

let jobList = []; // Lista de Job IDs
let checkedJobs = new Set(); // Job IDs ya revisados

// Cargar lista inicial desde archivo (opcional)
try {
    jobList = JSON.parse(fs.readFileSync('jobs.json'));
} catch {
    jobList = [];
}

// Ruta para que los scouts pidan un Job ID libre
app.get('/get-job', (req, res) => {
    const nextJob = jobList.find(j => !checkedJobs.has(j));
    if (nextJob) {
        checkedJobs.add(nextJob);
        res.json({ job: nextJob });
    } else {
        res.json({ job: null });
    }
});

// Ruta para agregar nuevos Job IDs (manual o automático)
app.post('/add-job', (req, res) => {
    const job = req.body.job;
    if (job && !jobList.includes(job)) {
        jobList.push(job);
        fs.writeFileSync('jobs.json', JSON.stringify(jobList, null, 2));
    }
    res.json({ status: 'ok' });
});

// Ruta para resetear el sistema (si quieres reiniciar el sistema manualmente)
app.post('/reset', (req, res) => {
    checkedJobs.clear();
    res.json({ status: 'reset done' });
});

// Ruta de ping (opcional)
app.get('/', (req, res) => {
    res.send("Brainrot Server Online");
});

app.listen(3000, () => {
    console.log("Servidor escuchando en puerto 3000");
});
