/**
 * Shared In-Memory Stores
 * Tüm routes'lar bu stores'u kullanır
 */

const demoClients = new Map([
  ['client-1', { id: 'client-1', username: 'ece', name: 'Ece Yılmaz', createdAt: new Date() }],
  ['client-2', { id: 'client-2', username: 'aylin', name: 'Aylin Kaya', createdAt: new Date() }],
]);

const mockAppointments = new Map([
  ['appt-1', { id: 'appt-1', clientId: 'client-1', timeSlot: '10:00', dayOfWeek: 'Pazartesi', note: 'İlk seansı konuşacağız', confirmed: true, createdAt: new Date() }],
  ['appt-2', { id: 'appt-2', clientId: 'client-2', timeSlot: '14:30', dayOfWeek: 'Çarşamba', note: 'Haftalık kontrol', confirmed: false, createdAt: new Date() }],
]);

const mockJournals = new Map([
  ['journal-1', { id: 'journal-1', clientId: 'client-1', content: 'Bugün çok stresli bir gün geçirdim. Ama sabah yürüyüşü beni sakinleştirdi.', mood: 'anxious', dayOfWeek: 'Pazartesi', date: new Date('2026-05-04'), createdAt: new Date('2026-05-04') }],
  ['journal-2', { id: 'journal-2', clientId: 'client-1', content: 'Bugün harika bir gün! Arkadaşlarımla kahve içtik ve çok eğlendik.', mood: 'happy', dayOfWeek: 'Salı', date: new Date('2026-05-05'), createdAt: new Date('2026-05-05') }],
]);

module.exports = {
  demoClients,
  mockAppointments,
  mockJournals,
};
