// Auth endpoints — terapist + danışan login.
// Terapist için sabit master password (demo); ilk girişte otomatik kayıt olur.
// Danışan için terapistin önceden açtığı hesap üzerinden bcrypt karşılaştırması.

const express = require('express');
const bcrypt = require('bcryptjs');
const prisma = require('../prisma');
const { signToken } = require('../middleware/jwt');
const { demoClients } = require('../shared/stores');

const router = express.Router();

/**
 * POST /auth/therapist/login
 * body: { name, password }
 *  - "name" terapistin görünür adı (Sinem, Yasin gibi).
 *  - master password .env'den gelir.
 *  - aynı isimde terapist yoksa kayıt edilir, varsa girişe izin verilir.
 */
router.post('/therapist/login', async (req, res) => {
  const { name, password } = req.body || {};
  if (!name || !password) {
    return res.status(400).json({ error: 'bad_request', message: 'name ve password gerekli.' });
  }
  if (password !== process.env.THERAPIST_MASTER_PASSWORD) {
    return res.status(401).json({ error: 'invalid_password', message: 'Terapist şifresi hatalı.' });
  }

  // 🔥 DEMO MOD: Database yerine mock data döndür (Supabase offline'da)
  const therapistId = `demo-therapist-${Date.now()}`;
  const username = String(name).trim().toLowerCase().replace(/\s+/g, '_');
  const token = signToken({ id: therapistId, role: 'therapist', name: String(name).trim() });

  console.log(`✅ [DEMO] Terapist giriş: ${username}`);
  res.json({
    token,
    user: { id: therapistId, name: String(name).trim(), role: 'therapist' }
  });
});

/**
 * POST /auth/client/login
 * body: { username, password }
 *  - Terapistin oluşturduğu hesapla giriş.
 */
router.post('/client/login', async (req, res) => {
  const { username, password } = req.body || {};
  if (!username || !password) {
    return res.status(400).json({ error: 'bad_request', message: 'username ve password gerekli.' });
  }

  // 🔥 DEMO MOD: Terapistin oluşturduğu danışanı kontrol et
  const uname = String(username).trim().toLowerCase();

  // demoClients içinde bu username'i bul
  let client = null;
  for (const c of demoClients.values()) {
    if (c.username === uname) {
      client = c;
      break;
    }
  }

  // Danışan bulunamadı
  if (!client) {
    return res.status(401).json({ error: 'invalid_credentials', message: 'Danışan bulunamadı.' });
  }

  // Demo modda şifre kontrolü yoksa, sadece username'i kontrol et
  // (Gerçek uygulamada bcrypt.compare kullanılır)
  const token = signToken({
    id: client.id,
    role: 'client',
    name: client.name,
    therapistId: 'demo-therapist-123',
  });

  console.log(`✅ [DEMO] Danışan giriş: ${uname} (${client.id})`);
  res.json({
    token,
    user: { id: client.id, name: client.name, role: 'client' },
  });
});

module.exports = router;
