// Mentis Insight motorunun sözlükleri.
// Tamamen ekibimiz tarafından elle hazırlandı; harici bir LLM çağrısı yok.

// ────────────────────────────────────────────────────────────
//  TÜRKÇE STOP WORDS — anlam taşımayan kelimeler
//  Word frequency analizinde bu kelimeler atlanır.
// ────────────────────────────────────────────────────────────
const TURKISH_STOPWORDS = new Set([
  've', 'veya', 'ile', 'bir', 'bu', 'şu', 'o', 'için', 'ama', 'fakat',
  'lakin', 'çünkü', 'gibi', 'kadar', 'daha', 'çok', 'az', 'her', 'hiç',
  'de', 'da', 'ki', 'mi', 'mı', 'mu', 'mü', 'ya', 'ise', 'ben',
  'sen', 'biz', 'siz', 'onlar', 'beni', 'seni', 'bizi', 'sizi', 'onu',
  'bana', 'sana', 'bize', 'size', 'ona', 'benim', 'senin', 'bizim',
  'sizin', 'onun', 'kendi', 'kim', 'ne', 'nasıl', 'neden', 'niye',
  'hangi', 'nerede', 'nereye', 'ne zaman', 'kaç', 'evet', 'hayır',
  'var', 'yok', 'olur', 'oldu', 'olmuş', 'olacak', 'olarak', 'olan',
  'idi', 'iken', 'imiş', 'iyice', 'tek', 'iki', 'üç', 'dört', 'beş',
  'şey', 'bütün', 'bile', 'sadece', 'yalnızca', 'belki', 'galiba',
  'mesela', 'yani', 'yine', 'tekrar', 'henüz', 'önce', 'sonra', 'şimdi',
  'bugün', 'dün', 'yarın', 'falan', 'filan', 'işte', 'tabii', 'tabi',
  'eğer', 'ama', 'fakat', 'lakin', 'oysa', 'rağmen', 'aslında',
  'gerçekten', 'genellikle', 'genelde', 'genel', 'oldukça', 'epey',
  'biraz', 'birkaç', 'biri', 'bazı', 'tüm', 'bütün', 'birden', 'birden',
  'mı', 'mi', 'mu', 'mü', 'ki', 'ya', 'ah', 'oh', 'eh', 'iyi',
  'kötü', 'güzel', 'fena', 'belki', 'lazım', 'gerek', 'olmalı',
  'için', 'doğru', 'yanlış',
  // tekleştirme: lowercase
]);

// ────────────────────────────────────────────────────────────
//  ÇOK KELİMELİ DUYGU İFADELERİ — önce bunlar taranır
// ────────────────────────────────────────────────────────────
const SENTIMENT_PHRASES = {
  // Çok olumlu (+2)
  'kendimi iyi hissediyorum': 2.0,
  'çok mutluyum': 2.0,
  'harika hissediyorum': 2.0,
  'enerji dolu': 2.0,
  'huzur içinde': 2.0,
  'çok şükür': 1.5,
  'bugün güzel geçti': 1.5,
  'gülümsedim': 1.5,
  'içim açıldı': 1.5,
  'kendime iyi bakıyorum': 1.5,
  'umut dolu': 1.5,
  'rahatladım': 1.5,
  'içim ferahladı': 1.5,
  'iyi hissediyorum': 1.0,
  // Çok olumsuz
  'iyi değilim': -1.0,
  'kötü hissediyorum': -1.5,
  'çok yorgunum': -1.0,
  'çok stresliyim': -1.0,
  'kendimi kötü hissediyorum': -1.5,
  'içim sıkıldı': -1.0,
  'içim daraldı': -1.0,
  'canım sıkkın': -1.0,
  'bunaldım': -1.5,
  'çok kötüyüm': -2.0,
  'dayanamıyorum': -2.0,
  'umut yok': -2.0,
  'her şey berbat': -2.0,
  'hayat anlamsız': -2.0,
  'kimsem yok': -2.0,
  'içim boş': -1.5,
  'kalbim kırık': -1.5,
  'ağlamak istiyorum': -1.5,
};

// ────────────────────────────────────────────────────────────
//  TEK KELİME (kök) DUYGU SÖZLÜĞÜ — Türkçe karakterler normalize edilmiş
//  Aksan kaldırılır: ı→i, ş→s, ğ→g, ü→u, ö→o, ç→c
// ────────────────────────────────────────────────────────────
const SENTIMENT_WORDS = {
  // +2
  'harika': 2.0, 'mukemmel': 2.0, 'muhtesem': 2.0,
  'sevin': 2.0, 'mutlu': 2.0, 'huzur': 2.0,
  'umut': 1.8, 'sevgi': 1.8, 'sukur': 1.8,
  'gulum': 1.8, 'basar': 1.8, 'gurur': 1.5,
  // +1
  'iyi': 1.0, 'guzel': 1.0, 'keyif': 1.0,
  'sakin': 1.0, 'rahat': 1.0, 'ferah': 1.0,
  'dingin': 1.0, 'hosnut': 1.0, 'memnun': 1.0,
  'sevdik': 1.2, 'minnettar': 1.2, 'guven': 0.9,
  'pozitif': 1.2, 'olumlu': 1.0, 'cesur': 1.0,
  'umutlu': 1.5, 'neselen': 1.3, 'gulduk': 1.3,
  'eglendik': 1.2, 'mutlandim': 1.5, 'iyilesti': 1.3,
  // -1
  'kotu': -1.0, 'uzgun': -1.0, 'uzul': -1.0,
  'sikil': -1.0, 'yorgun': -1.0, 'gergin': -1.0,
  'kayg': -1.2, 'endis': -1.2, 'korku': -1.2,
  'ofkel': -1.2, 'sinirl': -1.2, 'kizgin': -1.2,
  'yalniz': -1.2, 'caresiz': -1.5, 'pisman': -1.0,
  'olumsuz': -1.0, 'agla': -1.3, 'huzun': -1.2,
  'panik': -1.5, 'utanc': -1.0, 'sucl': -1.0,
  'tukand': -1.5, 'bittim': -1.5,
  // -2
  'berbat': -2.0, 'felaket': -2.0, 'rezalet': -2.0,
  'corkme': -2.0, 'bunalim': -2.0, 'depres': -2.0,
  'dayanam': -2.0, 'mahvolduk': -2.0, 'mahvet': -1.8,
  'olmek': -2.0, 'umutsuz': -2.0, 'cikmaz': -1.8,
  'karanl': -1.5, 'igrenc': -1.5, 'tiksin': -1.5,
  'nefret': -1.8, 'asagilan': -1.5, 'degersiz': -1.8,
};

// ────────────────────────────────────────────────────────────
//  RİSK İFADELERİ — kriz dili
//  Tier 4 (×4) → acil; Tier 1 (×1) → hafif
// ────────────────────────────────────────────────────────────
const RISK_TIER = { LOW: 1, MEDIUM: 2, HIGH: 3, CRITICAL: 4 };

const RISK_PHRASES = {
  'olmek istiyorum': RISK_TIER.CRITICAL,
  'kendimi oldurmek': RISK_TIER.CRITICAL,
  'hayata son': RISK_TIER.CRITICAL,
  'intihar etmek': RISK_TIER.CRITICAL,
  'kendime zarar': RISK_TIER.CRITICAL,
  'kendime zarar vermek': RISK_TIER.CRITICAL,
  'kendime zarar verdim': RISK_TIER.CRITICAL,
  'kestim kendimi': RISK_TIER.CRITICAL,
  'kendimi kesmek': RISK_TIER.CRITICAL,
  'asacagim kendimi': RISK_TIER.CRITICAL,
  'son verecegim': RISK_TIER.CRITICAL,
  'veda mektubu': RISK_TIER.CRITICAL,
  'dunya bensiz': RISK_TIER.CRITICAL,
  'planim var': RISK_TIER.HIGH,
  'dayanamiyorum artik': RISK_TIER.HIGH,
  'umut yok': RISK_TIER.HIGH,
  'cikis yok': RISK_TIER.HIGH,
  'her sey bitti': RISK_TIER.HIGH,
  'yasamak istemiyorum': RISK_TIER.CRITICAL,
  'hicbir sey istemiyorum': RISK_TIER.HIGH,
  'hayat anlamsiz': RISK_TIER.HIGH,
  'hicbir anlami yok': RISK_TIER.HIGH,
  'beni kimse anlamiyor': RISK_TIER.MEDIUM,
  'kimsem yok': RISK_TIER.MEDIUM,
  'ic karartici': RISK_TIER.MEDIUM,
  'igrenc hissediyorum': RISK_TIER.MEDIUM,
  'kendimi degersiz': RISK_TIER.MEDIUM,
  'kimseye yaramiyorum': RISK_TIER.MEDIUM,
  'yuk oluyorum': RISK_TIER.MEDIUM,
  'cevreye yuk': RISK_TIER.MEDIUM,
  'sevilmiyorum': RISK_TIER.MEDIUM,
  'kendimi suclu': RISK_TIER.MEDIUM,
  'cok yorgunum': RISK_TIER.LOW,
  'uykum gelmiyor': RISK_TIER.LOW,
  'uykusuz kaldim': RISK_TIER.LOW,
  'mutsuzum': RISK_TIER.LOW,
  'iyi degilim': RISK_TIER.LOW,
  'icim sik': RISK_TIER.LOW,
  'icim daral': RISK_TIER.LOW,
  'agladim': RISK_TIER.LOW,
};

const RISK_WORDS = {
  // Tier 4
  'intihar': RISK_TIER.CRITICAL,
  'oldur': RISK_TIER.CRITICAL,
  'asilmak': RISK_TIER.CRITICAL,
  'asilacagim': RISK_TIER.CRITICAL,
  // Tier 3
  'umutsuz': RISK_TIER.HIGH,
  'dayanam': RISK_TIER.HIGH,
  'caresiz': RISK_TIER.HIGH,
  'tukand': RISK_TIER.HIGH,
  'mahvold': RISK_TIER.HIGH,
  'bittim': RISK_TIER.HIGH,
  'depresyon': RISK_TIER.MEDIUM,
  'depresif': RISK_TIER.MEDIUM,
  'panik': RISK_TIER.MEDIUM,
  // Tier 2
  'degersiz': RISK_TIER.MEDIUM,
  'yetersiz': RISK_TIER.MEDIUM,
  'yalnizim': RISK_TIER.MEDIUM,
  'igrenc': RISK_TIER.LOW,
  'tiksin': RISK_TIER.MEDIUM,
  'nefret': RISK_TIER.MEDIUM,
  // Tier 1
  'yorgun': RISK_TIER.LOW,
  'uykusuz': RISK_TIER.LOW,
  'mutsuz': RISK_TIER.LOW,
  'gergin': RISK_TIER.LOW,
  'kayg': RISK_TIER.LOW,
  'endis': RISK_TIER.LOW,
  'huzun': RISK_TIER.LOW,
  'sucl': RISK_TIER.LOW,
};

module.exports = {
  TURKISH_STOPWORDS,
  SENTIMENT_PHRASES,
  SENTIMENT_WORDS,
  RISK_PHRASES,
  RISK_WORDS,
  RISK_TIER,
};
