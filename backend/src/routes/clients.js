// Therapist tarafından danışan hesabı yönetimi.
// Tüm endpointler "therapist" rolü gerektirir.

const express = require('express');
const bcrypt = require('bcryptjs');
const prisma = require('../prisma');
const { authRequired, therapistOnly } = require('../middleware/jwt');
const { demoClients } = require('../shared/stores');

const router = express.Router();

router.use(authRequired);
router.use(therapistOnly);

/**
 * GET /clients
 * Therapist'in kendi danışanlarını listeler.
 */
router.get('/', async (req, res) => {
  // 🔥 DEMO MOD: In-memory store'dan döndür
  const clientList = Array.from(demoClients.values());
  console.log(`✅ [DEMO] Danışan listesi (${clientList.length} danışan)`);
  res.json(clientList);
});

/**
 * POST /clients
 * body: { name, username, password }
 * Yeni danışan oluşturur.
 */
router.post('/', async (req, res) => {
  const { name, username, password } = req.body || {};
  if (!name || !username || !password) {
    return res.status(400).json({ error: 'bad_request', message: 'name, username, password gerekli.' });
  }
  const uname = String(username).trim().toLowerCase();
  if (uname.length < 3 || uname.includes(' ')) {
    return res.status(400).json({ error: 'bad_username', message: 'Kullanıcı adı en az 3 karakter ve boşluksuz olmalı.' });
  }
  if (password.length < 4) {
    return res.status(400).json({ error: 'bad_password', message: 'Şifre en az 4 karakter olmalı.' });
  }

  // 🔥 DEMO MOD: In-memory store'a ekle
  const clientId = `client-${Date.now()}`;
  const newClient = {
    id: clientId,
    username: uname,
    name: String(name).trim(),
    createdAt: new Date(),
  };
  demoClients.set(clientId, newClient);
  console.log(`✅ [DEMO] Danışan oluşturuldu: ${uname}`);
  res.status(201).json(newClient);
});

/**
 * DELETE /clients/:id
 * Danışan hesabını siler. Cascade ile günlük ve randevu da silinir.
 */
router.delete('/:id', async (req, res) => {
  const { id } = req.params;
  // 🔥 DEMO MOD: In-memory store'dan sil
  if (demoClients.has(id)) {
    demoClients.delete(id);
    console.log(`✅ [DEMO] Danışan silindi: ${id}`);
    res.status(204).end();
  } else {
    res.status(404).json({ error: 'not_found' });
  }
});

module.exports = router;
