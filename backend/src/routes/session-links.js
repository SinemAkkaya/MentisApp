// Session links endpoint
// Terapistler video bağlantı oluşturup danışanlara gönderebilir
// Danışanlar bağlantı listesini görebilir ve klikleme yoluyla katılabilir

const express = require('express');
const { authRequired, therapistOnly } = require('../middleware/jwt');
const { demoClients } = require('../shared/stores');

const router = express.Router();

router.use(authRequired);

// In-memory store for session links
const sessionLinks = new Map();

/**
 * POST /session-links
 * Terapist tarafından çağrılır. Video seansı bağlantısı oluşturur.
 * body: { clientId, platform ('google-meet' | 'zoom'), title?, link? }
 */
router.post('/', async (req, res) => {
  if (req.user.role !== 'therapist') {
    return res.status(403).json({ error: 'forbidden', message: 'Sadece terapist bağlantı oluşturabilir.' });
  }

  const { clientId, platform, title, link } = req.body || {};
  if (!clientId || !platform || !['google-meet', 'zoom'].includes(platform)) {
    return res.status(400).json({
      error: 'bad_request',
      message: 'clientId, platform (google-meet|zoom) gerekli.',
    });
  }

  // Link varsa custom link'i kullan, yoksa oluştur
  const finalLink = link || _generateLink(platform);
  const linkId = `link-${Date.now()}`;

  const sessionLink = {
    id: linkId,
    clientId,
    therapistId: req.user.id,
    platform,
    link: finalLink,
    title: title || `${platform === 'google-meet' ? 'Google Meet' : 'Zoom'} Seansı`,
    createdAt: new Date(),
    expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 saat sonra
    isRead: false,
    clickCount: 0,
  };

  sessionLinks.set(linkId, sessionLink);
  console.log(`✅ [SESSION] Bağlantı oluşturuldu: ${platform} - Danışan: ${clientId}`);
  res.status(201).json(sessionLink);
});

/**
 * GET /session-links
 *  - Danışan: kendi bağlantılarını görür (okumadığı)
 *  - Terapist: ?clientId=... ile spesifik danışanın bağlantılarını, yoksa tümünü
 */
router.get('/', async (req, res) => {
  let links = Array.from(sessionLinks.values());

  // Danışan: kendi bağlantılarını
  if (req.user.role === 'client') {
    links = links.filter(l => l.clientId === req.user.id && !l.isRead);
  }
  // Terapist: danışan bağlantılarını
  else if (req.user.role === 'therapist' && req.query.clientId) {
    links = links.filter(l => l.clientId === req.query.clientId && l.therapistId === req.user.id);
  } else if (req.user.role === 'therapist') {
    links = links.filter(l => l.therapistId === req.user.id);
  }

  // Geçmiş bağlantıları dışla
  links = links.filter(l => new Date(l.expiresAt) > new Date());

  // En yeni başta
  links.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

  console.log(`✅ [SESSION] Bağlantı listesi alındı (${links.length} adet)`);
  res.json(links);
});

/**
 * PATCH /session-links/:id
 * Danışan bağlantı tıkladığında "okundu" işareti
 * body: { isRead?, clickCount? }
 */
router.patch('/:id', async (req, res) => {
  const { id } = req.params;
  const { isRead, clickCount } = req.body || {};

  const link = sessionLinks.get(id);
  if (!link) {
    return res.status(404).json({ error: 'not_found' });
  }

  // Danışan sadece kendi bağlantısını güncelleyebilir
  if (req.user.role === 'client' && link.clientId !== req.user.id) {
    return res.status(403).json({ error: 'forbidden' });
  }

  if (isRead !== undefined) link.isRead = Boolean(isRead);
  if (clickCount !== undefined) link.clickCount = parseInt(clickCount);

  console.log(`✅ [SESSION] Bağlantı güncellendi: ${id}`);
  res.json(link);
});

/**
 * DELETE /session-links/:id
 * Terapist bağlantı silebilir
 */
router.delete('/:id', async (req, res) => {
  if (req.user.role !== 'therapist') {
    return res.status(403).json({ error: 'forbidden' });
  }

  const { id } = req.params;
  const link = sessionLinks.get(id);

  if (!link) {
    return res.status(404).json({ error: 'not_found' });
  }

  if (link.therapistId !== req.user.id) {
    return res.status(403).json({ error: 'forbidden' });
  }

  sessionLinks.delete(id);
  console.log(`✅ [SESSION] Bağlantı silindi: ${id}`);
  res.json({ success: true });
});

/**
 * POST /session-links/:id/click
 * Danışan bağlantı tıklanma sayısını artır
 */
router.post('/:id/click', async (req, res) => {
  const { id } = req.params;
  const link = sessionLinks.get(id);

  if (!link) {
    return res.status(404).json({ error: 'not_found' });
  }

  // Danışan sadece kendi bağlantısında tıklayabilir
  if (req.user.role === 'client' && link.clientId !== req.user.id) {
    return res.status(403).json({ error: 'forbidden' });
  }

  link.clickCount = (link.clickCount || 0) + 1;
  link.isRead = true;

  console.log(`✅ [SESSION] Bağlantı tıklandı: ${id} (${link.clickCount}x)`);
  res.json(link);
});

// ────────────────────────────────────────────────────────────
// Yardımcı fonksiyonlar
// ────────────────────────────────────────────────────────────

function _generateLink(platform) {
  const rnd = Math.random;
  function randomCode(len) {
    const chars = 'abcdefghijkmnpqrstuvwxyz23456789';
    return Array.from(
      { length: len },
      () => chars[Math.floor(Math.random() * chars.length)]
    ).join('');
  }

  if (platform === 'google-meet') {
    // Google Meet: xxx-yyyy-zzz
    return `https://meet.google.com/${randomCode(3)}-${randomCode(4)}-${randomCode(3)}`;
  } else if (platform === 'zoom') {
    // Zoom: j/ID?pwd=PASSWORD
    const id = Array.from({ length: 10 }, () =>
      Math.floor(Math.random() * 10)
    ).join('');
    const pwd = randomCode(8);
    return `https://zoom.us/j/${id}?pwd=${pwd}`;
  }
}

module.exports = router;
