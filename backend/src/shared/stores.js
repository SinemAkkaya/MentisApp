/**
 * Shared In-Memory Stores
 * Tüm routes'lar bu stores'u kullanır
 *
 * DEMO İÇİN: 2 danışan (1 depresif, 1 mutlu) + 7 günlük entri
 */

const demoClients = new Map([
  ['client-1', { id: 'client-1', username: 'ahmet', name: 'Ahmet Kaya', createdAt: new Date() }],
  ['client-2', { id: 'client-2', username: 'zeynep', name: 'Zeynep Şahin', createdAt: new Date() }],
  ['client-3', { id: 'client-3', username: 'elif', name: 'Elif Demir', createdAt: new Date() }],
]);

const mockAppointments = new Map([
  ['appt-1', { id: 'appt-1', clientId: 'client-1', timeSlot: '10:00', dayOfWeek: 'Pazartesi', note: 'Depresyon değerlendirmesi', confirmed: true, createdAt: new Date() }],
  ['appt-2', { id: 'appt-2', clientId: 'client-2', timeSlot: '14:30', dayOfWeek: 'Çarşamba', note: 'Düzenli kontrol', confirmed: false, createdAt: new Date() }],
  ['appt-3', { id: 'appt-3', clientId: 'client-3', timeSlot: '11:00', dayOfWeek: 'Salı', note: 'Anksiyete yönetimi', confirmed: true, createdAt: new Date() }],
]);

// ═══════════════════════════════════════════════════════════
// DEPRESIF DANIŞAN: Ahmet (client-1)
// ═══════════════════════════════════════════════════════════

const ahmetJournals = [
  {
    id: 'journal-ahmet-1',
    clientId: 'client-1',
    clientName: 'Ahmet Kaya',
    content: 'Pazartesi günü oldu, haftanın başından itibaren çok kötü hissediyorum. Uyku çok kötü, sadece 3-4 saat uyuyabildum. Kafamda sürekli negatif düşünceler var. Kendime değersiz hissediyorum, hiçbir şeyde başarısız oldum. Belki de hayatımda hiçbir perde yok.',
    mood: 'sad',
    dayOfWeek: 'Pazartesi',
    date: new Date('2026-05-01'),
    createdAt: new Date('2026-05-01')
  },
  {
    id: 'journal-ahmet-2',
    clientId: 'client-1',
    clientName: 'Ahmet Kaya',
    content: 'Salı günü. İş çok stresli oldu. Müdür bana çok baskı yaptı, belki de işten atılacağım. Sosyal ortamlarda kendimi yalnız hissediyorum. Hiç kimse beni anlamıyor. Depresyon hissiyorum, her gün aynı şey, monoton ve boş. Umutsuzluk içindeyim.',
    mood: 'anxious',
    dayOfWeek: 'Salı',
    date: new Date('2026-05-02'),
    createdAt: new Date('2026-05-02')
  },
  {
    id: 'journal-ahmet-3',
    clientId: 'client-1',
    clientName: 'Ahmet Kaya',
    content: 'Çarşamba. Dün gece kabus gördüm. Bugün aile ile konuşmak istedim ama çöküştümü hissettim. Kimsede bana yardım edemeyecek. Hiçbir şey beni mutlu etmiyor artık. Enerji yok, her şey çok zorla yapıyorum.',
    mood: 'sad',
    dayOfWeek: 'Çarşamba',
    date: new Date('2026-05-03'),
    createdAt: new Date('2026-05-03')
  },
  {
    id: 'journal-ahmet-4',
    clientId: 'client-1',
    clientName: 'Ahmet Kaya',
    content: 'Perşembe. Yine uyku problemleri. Sabah erken uyandım, öğleden sonra da kovalamaca başladı. İş projesi başarısız oldu, resmen bitirdim kendimi. Arkadaşlarımla görüşmeyi iptal ettim, sosyal hayatımız yok zaten.',
    mood: 'sad',
    dayOfWeek: 'Perşembe',
    date: new Date('2026-05-04'),
    createdAt: new Date('2026-05-04')
  },
  {
    id: 'journal-ahmet-5',
    clientId: 'client-1',
    clientName: 'Ahmet Kaya',
    content: 'Cuma. Haftanın sonuna geldik ama hiçbir şey değişmedi. Hâlâ çaresiz hissediyorum. Geleceğim hakkında kötü düşünceler var, hiçbir umut kalmadı. Belki de geçerse diye düşünüyorum. Her gün same, nothing changes.',
    mood: 'sad',
    dayOfWeek: 'Cuma',
    date: new Date('2026-05-05'),
    createdAt: new Date('2026-05-05')
  },
  {
    id: 'journal-ahmet-6',
    clientId: 'client-1',
    clientName: 'Ahmet Kaya',
    content: 'Cumartesi. Tatil günü ama yine de bir anlam yok. Yatakta kaldım, televizyon izledim. Aileme zahmet olup olmadığımı düşündüm. Motivasyon yok, hiç bir şey yapmak istemiyorum.',
    mood: 'sad',
    dayOfWeek: 'Cumartesi',
    date: new Date('2026-05-06'),
    createdAt: new Date('2026-05-06')
  },
  {
    id: 'journal-ahmet-7',
    clientId: 'client-1',
    clientName: 'Ahmet Kaya',
    content: 'Pazar. Haftanın sonunda, yeni haftaya girmeden önce çok endişeliyim. İş başında ne olacak diye kaygı yapıyorum. Uyku ağrısı, baş ağrısı. Yalnız ve değersiz hissediyorum. Her gün same old story.',
    mood: 'anxious',
    dayOfWeek: 'Pazar',
    date: new Date('2026-05-07'),
    createdAt: new Date('2026-05-07')
  },
];

// ═══════════════════════════════════════════════════════════
// MUTLU DANIŞAN: Zeynep (client-2)
// ═══════════════════════════════════════════════════════════

const zeynepJournals = [
  {
    id: 'journal-zeynep-1',
    clientId: 'client-2',
    clientName: 'Zeynep Şahin',
    content: 'Pazartesi! Haftanın başı ve çok heyecanlandım. Yeni bir proje başlıyoruz ve ekip gerçekten harika. Sabah yürüyüşe çıktım, hava güzeldi ve kendimi iyi hissettim. Enerji dolu başladım haftaya. Arkadaşlarımla kahvaltı yaptık, çok eğlendik!',
    mood: 'happy',
    dayOfWeek: 'Pazartesi',
    date: new Date('2026-05-01'),
    createdAt: new Date('2026-05-01')
  },
  {
    id: 'journal-zeynep-2',
    clientId: 'client-2',
    clientName: 'Zeynep Şahin',
    content: 'Salı. Dün gece iyi uyudum, çok rahat bir uyku oldu. Bugün iş çok produktif geçti, başarılı olduk! Müdür projeyi çok beğendi, gurur hissettim. Akşam spor yaptım, yoga dersi aldım. Çok sakin ve huzur dolu bir gün.',
    mood: 'happy',
    dayOfWeek: 'Salı',
    date: new Date('2026-05-02'),
    createdAt: new Date('2026-05-02')
  },
  {
    id: 'journal-zeynep-3',
    clientId: 'client-2',
    clientName: 'Zeynep Şahin',
    content: 'Çarşamba. Tatil hakkı kullanarak arkadaşlarımla müze ziyaretine gittim. Çok güzel sanat eserleri vardı, ilham aldım. Sosyal hayatım harika, sevdiklerimle zaman geçirmek çok kıymetli. Huzur ve mutluluk hissediyorum.',
    mood: 'happy',
    dayOfWeek: 'Çarşamba',
    date: new Date('2026-05-03'),
    createdAt: new Date('2026-05-03')
  },
  {
    id: 'journal-zeynep-4',
    clientId: 'client-2',
    clientName: 'Zeynep Şahin',
    content: 'Perşembe. İşte başarılı bir sunum yaptım ve herkes beğendi. Kendimden çok memnun hissediyorum. Enerji seviyeleri yüksek, hiç yorgun değilim. Aile ile akşam yemeği yaptım, paylaştığım her anı sevdim.',
    mood: 'happy',
    dayOfWeek: 'Perşembe',
    date: new Date('2026-05-04'),
    createdAt: new Date('2026-05-04')
  },
  {
    id: 'journal-zeynep-5',
    clientId: 'client-2',
    clientName: 'Zeynep Şahin',
    content: 'Cuma! Hafta sonu geliyor! İş iyi gitti, arkadaşlarım davet etti ve ben de gitmek istiyorum. Heyecan ve sevinç içindeyim. Güneş batışında yürüyüş yaptım, doğa çok güzeldi. Yaşamak çok güzel.',
    mood: 'happy',
    dayOfWeek: 'Cuma',
    date: new Date('2026-05-05'),
    createdAt: new Date('2026-05-05')
  },
  {
    id: 'journal-zeynep-6',
    clientId: 'client-2',
    clientName: 'Zeynep Şahin',
    content: 'Cumartesi. Sabah erken uyandım ama hiç sorun değil! Doğa yürüyüşü yaptım, harika hava ve manzara. Akşam konser vardı, müzik çok iyiydi, coşkulu bir ortam. Güzel insanlarla zaman geçirdim. Yaşamdan huzur alıyorum.',
    mood: 'happy',
    dayOfWeek: 'Cumartesi',
    date: new Date('2026-05-06'),
    createdAt: new Date('2026-05-06')
  },
  {
    id: 'journal-zeynep-7',
    clientId: 'client-2',
    clientName: 'Zeynep Şahin',
    content: 'Pazar. Hafta sonu çok güzel geçti. Kendime özen verdim, meditasyon yaptım, kitap okudum. Aile ve arkadaşlarımla anlamlı sohbetler yaptım. Hayata teşekkür hissediyorum. Yeni haftaya güvenle başlayacağım, umut dolu!',
    mood: 'happy',
    dayOfWeek: 'Pazar',
    date: new Date('2026-05-07'),
    createdAt: new Date('2026-05-07')
  },
];

// ═══════════════════════════════════════════════════════════
// KARIŞIK DUYGULU DANIŞAN: Elif (client-3)
// Anxiety + Coping + İyileşme trendi
// ═══════════════════════════════════════════════════════════

const elifJournals = [
  {
    id: 'journal-elif-1',
    clientId: 'client-3',
    clientName: 'Elif Demir',
    content: 'Pazartesi. Haftanın başı ve çok kaygılı hissediyorum. İş projesinde baskı var, deadline yakın. Uyku iyi değildi, sabah erken uyandım. Ama sabah yürüyüşe çıktım, bu bana yardımcı oldu. Arkadaşım aradı, konuştuk biraz. Endişeli ama yalnız değilim.',
    mood: 'anxious',
    dayOfWeek: 'Pazartesi',
    date: new Date('2026-05-01'),
    createdAt: new Date('2026-05-01')
  },
  {
    id: 'journal-elif-2',
    clientId: 'client-3',
    clientName: 'Elif Demir',
    content: 'Salı. Bugün zor bir gün oldu, müdür baskı yaptı. Kaygı hissettim, tüyleri diken diken oldum. Ama akşam yoga yaptım, çok iyi geldi. Nefes tekniğini uyguladım, biraz sakinleştim. Belki problem benim düşündüğüm kadar ciddi değil.',
    mood: 'anxious',
    dayOfWeek: 'Salı',
    date: new Date('2026-05-02'),
    createdAt: new Date('2026-05-02')
  },
  {
    id: 'journal-elif-3',
    clientId: 'client-3',
    clientName: 'Elif Demir',
    content: 'Çarşamba. Proje ilerledi, başarılı bir toplantı yaptık! Müdür beni tebrik etti, gurur hissettim. Enerji biraz arttı. Ama hâlâ stres var, endişe yapıyorum başarısızlıktan. Aile ile konuştum, beni desteklediler.',
    mood: 'mixed',
    dayOfWeek: 'Çarşamba',
    date: new Date('2026-05-03'),
    createdAt: new Date('2026-05-03')
  },
  {
    id: 'journal-elif-4',
    clientId: 'client-3',
    clientName: 'Elif Demir',
    content: 'Perşembe. Dün gece iyi uyudum, enerji biraz daha arttı. İş hâlâ stresli ama baş edebileceğimi hissediyorum. Arkadaşlarımla öğle yemeği yaptım, sohbet eşti, güldük. Meditasyon yaptım, çok sakinleşti.',
    mood: 'mixed',
    dayOfWeek: 'Perşembe',
    date: new Date('2026-05-04'),
    createdAt: new Date('2026-05-04')
  },
  {
    id: 'journal-elif-5',
    clientId: 'client-3',
    clientName: 'Elif Demir',
    content: 'Cuma. Haftanın sonuna geldim, başarılı oldum! Proje tamamlandı, rahat hissediyorum. Kaygı azaldı. Akşam arkadaşlarla buluştuk, çok eğlendik. Sosyal aktivite beni çok iyi hissetttirdi.',
    mood: 'happy',
    dayOfWeek: 'Cuma',
    date: new Date('2026-05-05'),
    createdAt: new Date('2026-05-05')
  },
  {
    id: 'journal-elif-6',
    clientId: 'client-3',
    clientName: 'Elif Demir',
    content: 'Cumartesi. Rahat bir gün oldu. Tatil yapıyorum, stres yok. Egzersiz yaptım, kitap okudum. Ruh halim çok daha iyi. Kendime bakma zamanı buldum, buna ihtiyacım vardı.',
    mood: 'happy',
    dayOfWeek: 'Cumartesi',
    date: new Date('2026-05-06'),
    createdAt: new Date('2026-05-06')
  },
  {
    id: 'journal-elif-7',
    clientId: 'client-3',
    clientName: 'Elif Demir',
    content: 'Pazar. Çok güzel bir hafta geçti. İyileşiyorum gibi hissediyorum. Kaygı hâlâ var ama kontrol edebiliyorum artık. Yoga ve meditasyon gerçekten yardımcı oldu. Aile desteği çok önemli. Yeni haftaya hazırız, umutlu ve güçlü!',
    mood: 'happy',
    dayOfWeek: 'Pazar',
    date: new Date('2026-05-07'),
    createdAt: new Date('2026-05-07')
  },
];

const mockJournals = new Map([
  ...ahmetJournals.map(j => [j.id, j]),
  ...zeynepJournals.map(j => [j.id, j]),
  ...elifJournals.map(j => [j.id, j]),
]);

module.exports = {
  demoClients,
  mockAppointments,
  mockJournals,
};
