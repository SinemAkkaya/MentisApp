// Randevu endpoint'leri.
// Danışan: kendi randevusunu oluşturur, kendi randevularını görür.
// Terapist: tüm randevuları görür, onaylar/sileyebilir.

const express = require('express');
const prisma = require('../prisma');
const { authRequired } = require('../middleware/jwt');
const { mockAppointments } = require('../shared/stores');

const router = express.Router();

router.use(authRequired);

/**
 * POST /appointments
 * Sadece danışan. body: { timeSlot, dayOfWeek, note }
 * Aynı gün+saat zaten varsa 409 döner.
 */
router.post('/', async (req, res) => {
  if (req.user.role !== 'client') {
    return res.status(403).json({ error: 'forbidden' });
  }
  const { timeSlot, dayOfWeek, note } = req.body || {};
  if (!timeSlot || !dayOfWeek) {
    return res.status(400).json({ error: 'bad_request' });
  }

  // 🔥 DEMO MOD: Mock store'a ekle
  const appointmentId = `appt-${Date.now()}`;
  const newAppointment = {
    id: appointmentId,
    clientId: req.user.id,
    timeSlot: String(timeSlot),
    dayOfWeek: String(dayOfWeek),
    note: note ? String(note).trim() : '',
    confirmed: false,
    createdAt: new Date(),
  };
  mockAppointments.set(appointmentId, newAppointment);
  console.log(`✅ [DEMO] Randevu oluşturuldu: ${dayOfWeek} ${timeSlot}`);
  res.status(201).json(newAppointment);
});

/**
 * GET /appointments
 *  - Danışan: kendi randevuları
 *  - Terapist: kendi danışanlarının tüm randevuları
 *  - ?dayOfWeek=Pazartesi destekler
 */
router.get('/', async (req, res) => {
  // 🔥 DEMO MOD: Mock store'dan döndür
  const appointmentList = Array.from(mockAppointments.values());
  console.log(`✅ [DEMO] Randevu listesi (${appointmentList.length} randevu)`);
  res.json(appointmentList);
});

/**
 * PATCH /appointments/:id/confirm
 * Yalnızca terapist.
 */
router.patch('/:id/confirm', async (req, res) => {
  if (req.user.role !== 'therapist') {
    return res.status(403).json({ error: 'forbidden' });
  }
  const { id } = req.params;
  // 🔥 DEMO MOD: Mock store'dan güncelle
  if (!mockAppointments.has(id)) {
    return res.status(404).json({ error: 'not_found' });
  }
  const appointment = mockAppointments.get(id);
  appointment.confirmed = true;
  console.log(`✅ [DEMO] Randevu onaylandı: ${id}`);
  res.json(appointment);
});

module.exports = router;
