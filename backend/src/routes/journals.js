// Günlük endpoint'leri.
// Danışan kendi entry'lerini POST/GET edebilir.
// Terapist kendi danışanlarının entry'lerini GET edebilir.

const express = require('express');
const prisma = require('../prisma');
const { authRequired } = require('../middleware/jwt');
const { mockJournals, demoClients } = require('../shared/stores');

const router = express.Router();

router.use(authRequired);

/**
 * POST /journals
 * Sadece danışan. body: { content, mood, dayOfWeek, date(ISO) }
 */
router.post('/', async (req, res) => {
  if (req.user.role !== 'client') {
    return res.status(403).json({ error: 'forbidden', message: 'Yalnızca danışan günlük yazabilir.' });
  }
  const { content, mood, dayOfWeek, date } = req.body || {};
  if (!content || !mood || !dayOfWeek || !date) {
    return res.status(400).json({ error: 'bad_request', message: 'content, mood, dayOfWeek, date gerekli.' });
  }

  // 🔥 DEMO MOD: In-memory store'a ekle + clientName ekle
  const journalId = `journal-${Date.now()}`;
  const client = demoClients.get(req.user.id);
  const clientName = client?.name || req.user.name || 'Anonim';

  const newEntry = {
    id: journalId,
    clientId: req.user.id,
    clientName: clientName,
    content: String(content).trim(),
    mood: String(mood),
    dayOfWeek: String(dayOfWeek),
    date: new Date(date),
    createdAt: new Date(),
  };
  mockJournals.set(journalId, newEntry);
  console.log(`✅ [DEMO] Günlük kaydedildi: ${clientName} - ${mood}`);
  res.status(201).json(newEntry);
});

/**
 * GET /journals
 *  - Danışan: kendi entry'leri (sıralı, en yeni başta).
 *  - Terapist: ?clientId=... ile spesifik bir danışanın entry'leri,
 *              parametre verilmezse tüm danışanlarının son N entry'si.
 *  - ?limit=5 destekler.
 */
router.get('/', async (req, res) => {
  // 🔥 DEMO MOD: In-memory store'dan filtrele ve döndür
  let journalList = Array.from(mockJournals.values());

  // Danışan: kendi entry'leri
  if (req.user.role === 'client') {
    journalList = journalList.filter(j => j.clientId === req.user.id);
  }
  // Terapist: ?clientId parametresi varsa o danışan, yoksa tüm danışanlar
  else if (req.user.role === 'therapist' && req.query.clientId) {
    journalList = journalList.filter(j => j.clientId === req.query.clientId);
  }

  // En yeni başta
  journalList.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

  // Limit
  const limit = parseInt(req.query.limit) || 50;
  journalList = journalList.slice(0, limit);

  // clientName'i ekle (eğer yoksa)
  journalList = journalList.map(j => {
    if (!j.clientName && j.clientId) {
      const client = demoClients.get(j.clientId);
      return { ...j, clientName: client?.name || 'Anonim' };
    }
    return j;
  });

  console.log(`✅ [DEMO] Günlük listesi (${journalList.length} entry)`);
  res.json(journalList);
});

module.exports = router;
