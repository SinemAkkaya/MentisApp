// Mentis Backend — Express server entry point.
// Tüm route'lar buradan yüklenir. Render.com'da bu dosya çalıştırılır (npm start).

require('dotenv').config();

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const authRoutes = require('./routes/auth');
const clientRoutes = require('./routes/clients');
const journalRoutes = require('./routes/journals');
const appointmentRoutes = require('./routes/appointments');
const insightRoutes = require('./routes/insight');
const sessionLinksRoutes = require('./routes/session-links');

const app = express();

// Middleware
app.use(cors({ origin: '*' })); // mobil app her yerden bağlanabilsin
app.use(express.json({ limit: '1mb' }));
app.use(morgan(process.env.NODE_ENV === 'development' ? 'dev' : 'combined'));

// Health check (Render bunu kullanır)
app.get('/', (req, res) => {
  res.json({
    name: 'Mentis Backend',
    version: '1.0.0',
    status: 'ok',
    timestamp: new Date().toISOString(),
  });
});

app.get('/health', (req, res) => res.json({ status: 'healthy' }));

// Mount routes
app.use('/auth', authRoutes);
app.use('/clients', clientRoutes);
app.use('/journals', journalRoutes);
app.use('/appointments', appointmentRoutes);
app.use('/insight', insightRoutes);
app.use('/session-links', sessionLinksRoutes);

// 404
app.use((req, res) => {
  res.status(404).json({ error: 'not_found', path: req.path });
});

// Global error handler
app.use((err, req, res, _next) => {
  console.error('[ERR]', err);
  res.status(500).json({
    error: 'internal_error',
    message: err.message || 'Bir hata oluştu.',
  });
});

const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0';

// Mac'in mevcut WiFi IP'sini bul → konsola düz yaz, demo için kolay olsun.
const os = require('os');
function detectLanIp() {
  const ifaces = os.networkInterfaces();
  for (const name of Object.keys(ifaces)) {
    for (const it of ifaces[name] || []) {
      if (it.family === 'IPv4' && !it.internal) return it.address;
    }
  }
  return 'localhost';
}

app.listen(PORT, HOST, () => {
  const lan = detectLanIp();
  console.log('');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`✅ Mentis backend listening on http://${HOST}:${PORT}`);
  console.log(`   Local:    http://localhost:${PORT}`);
  console.log(`   Network:  http://${lan}:${PORT}`);
  console.log(`   Env: ${process.env.NODE_ENV || 'development'}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');
  console.log(`📱 Telefon/Mac uygulaması bu IP'yi kullanmalı:  ${lan}`);
  console.log(`   lib/services/api_service.dart → _macHostIp = '${lan}';`);
  console.log('');
});
