/**
 * Mentis NLP Engine v2 — Profesyonel Türkçe Duygu Analizi
 * Terapistler için kapsamlı mental health insights
 */

// ═══════════════════════════════════════════════════════════
// GENIŞLETILMIŞ DUYGUSAL KELIMELER SÖZLÜĞÜ
// ═══════════════════════════════════════════════════════════

const emotionalWords = {
  // Pozitif (mutluluk, huzur, başarı)
  positive: [
    'mutlu', 'güzel', 'harika', 'iyi', 'mükemmel', 'sevgi', 'seviyorum',
    'heyecan', 'başarı', 'başardım', 'gurur', 'eğlendi', 'sakin', 'rahat',
    'huzur', 'şanslı', 'umut', 'ümit', 'başarılı', 'güçlü', 'cesur',
    'eğlenceli', 'keyif', 'zevk', 'memnun', 'minnettar', 'teşekkür',
    'özel', 'anlamlı', 'değerli', 'kıymetli', 'bereket', 'bolluk',
    'neşeli', 'şen', 'canlı', 'dinamik', 'enerjik', 'parlak',
    'umutlu', 'hopi', 'sevinç', 'coşku', 'tutkulu', 'istekli'
  ],

  // Negatif (üzüntü, hayal kırıklığı)
  negative: [
    'stres', 'endişe', 'korku', 'korkuyorum', 'ağlayan', 'ağladım', 'mutsuz',
    'üzgün', 'kötü', 'berbat', 'hüzün', 'çaresiz', 'sıkıntı', 'rahatsız',
    'kaygı', 'panik', 'hayal kırıklığı', 'hayal kırılganlık', 'çöküş',
    'yalnız', 'yalnızlık', 'yalnıyım', 'hopeless', 'boş', 'anlamsız',
    'negatif', 'kötüleşti', 'düştü', 'kırdım', 'kırıldım', 'suçlu',
    'utanç', 'rezil', 'başarısız', 'hüsran', 'bıkkın', 'usanmış',
    'sinirli', 'öfkeli', 'kızgın', 'rancıda', 'kederli', 'dişli'
  ],

  // Anksiyete (endişe, korku, tetikte)
  anxiety: [
    'endişe', 'kaygı', 'panik', 'korku', 'fırıldak', 'tedirgin', 'huzursuz',
    'korkuyorum', 'korkarak', 'panik', 'çöküş', 'çöktüm', 'felaket',
    'dehşet', 'ürperi', 'tüyleri diken diken', 'kalp çarpıntısı', 'nefes',
    'bunalım', 'sıkışmış', 'tuzak', 'tehdit', 'ön', 'gergin',
    'asık', 'bezgin', 'tükenmiş', 'yorgun', 'bitap', 'muztarip'
  ],

  // Depresyon (çaresizlik, boşluk, değersizlik)
  depression: [
    'mutsuz', 'depresyon', 'ümitsiz', 'umut yok', 'boşluk', 'değersiz',
    'değerli değilim', 'çöküş', 'çöktüm', 'hiç istemiyor', 'hiçbir şey',
    'anlamsız', 'niye yaşıyorum', 'kimse takmıyor', 'kimse umursamıyor',
    'içinde boşluk', 'motivasyon yok', 'gelecek yok', 'umut kalmadı',
    'mahvoldum', 'bitirdim', 'elim kolum bağlı', 'çaresiz'
  ],

  // Sosyal (ilişkiler, yalnızlık, bağlantı)
  social: [
    'yalnız', 'yalnızlık', 'arkadaş', 'aile', 'sevgi', 'ilişki', 'kimse',
    'sosyal', 'etkinlik', 'partisi', 'buluştu', 'konuştu', 'topluluk',
    'partner', 'sevgili', 'eş', 'çocuk', 'ebeveyn', 'kardeş',
    'toplum', 'grup', 'takım', 'birlikte', 'paylaş', 'samimi',
    'köşelenmiş', 'dışlanmış', 'hor görülmüş', 'itilmiş', 'reddedilmiş'
  ],

  // Uyku (yorgunluk, uyku problemi)
  sleep: [
    'uyku', 'uyuyamıyorum', 'uykusuz', 'uyumadım', 'kovalamaca', 'uyanık',
    'yorgun', 'bitkin', 'enerjisiz', 'uykulu', 'nadir', 'derin uyku',
    'gece', 'sabah erken', 'kısa uyku', 'kesintili', 'kâbustu', 'sudaki'
  ],

  // İş/Okul (çalışma stresi, deadline, başarı)
  work: [
    'çalışma', 'iş', 'proje', 'başarı', 'başarısız', 'baskı', 'deadline',
    'stres', 'mutsuz', 'tatmin', 'başarılı', 'yükseltme', 'promosyon',
    'ofis', 'toplantı', 'sunum', 'sınav', 'okul', 'üniversite',
    'derece', 'not', 'mezun', 'kariyer', 'gelecek', 'plan',
    'istifa', 'işten çıkması', 'denetmen', 'boss', 'zor'
  ],

  // Fiziksel Sağlık
  physical: [
    'ağrı', 'baş', 'migren', 'hastalık', 'hasta', 'ateş', 'grip',
    'yorgunluk', 'enerji', 'spor', 'egzersiz', 'yürüyüş', 'yüzme',
    'beslenme', 'diyet', 'vitamin', 'ilaç', 'doktor', 'tedavi'
  ],

  // Yapıcı Davranışlar (iyileşme işaretleri)
  coping: [
    'egzersiz', 'yürüyüş', 'spor', 'yoga', 'meditasyon', 'nefes',
    'sosyalleş', 'arkadaş', 'aile', 'konuş', 'terapist', 'danış',
    'oku', 'yazı', 'müzik', 'sanat', 'hobi', 'dinlenme',
    'tatil', 'seyahat', 'doğa', 'güneş', 'banyı', 'rahatlatıcı'
  ]
};

// ═══════════════════════════════════════════════════════════
// RISK TEŞKİLLEYİCİLERİ (ACIL UYARILER)
// ═══════════════════════════════════════════════════════════

const criticalRisks = [
  'intihar', 'ölmek istiyorum', 'ölmek', 'kendime zarar', 'kesiyorum',
  'zehir', 'ilaç aşırı', 'asılacağım', 'atlatacağım'
];

const highRisks = [
  'umut yok', 'dayanamıyorum', 'katlanamıyorum', 'çöküş', 'mahvoldum',
  'bitirdim', 'kimse umursamıyor', 'hiç fark yok', 'artık geç'
];

// ═══════════════════════════════════════════════════════════
// TEMEL ANALİZ FONKSİYONU
// ═══════════════════════════════════════════════════════════

function analyzeText(text) {
  if (!text || text.trim().length === 0) {
    return {
      mentisScore: 50,
      sentiment: { label: 'neutral', score: 0 },
      riskLevel: 'low',
      riskTriggers: [],
      categories: {},
      intensity: 0,
      insight: 'Günlük yazısı bulunmamaktadır.',
    };
  }

  const lowerText = text.toLowerCase();
  const words = lowerText.split(/\s+/).filter(w => w.length > 2);

  // Kategori sayıları
  let counts = {
    positive: 0,
    negative: 0,
    anxiety: 0,
    depression: 0,
    social: 0,
    sleep: 0,
    work: 0,
    physical: 0,
    coping: 0,
  };

  // Her kelimeyi kontrol et
  words.forEach(word => {
    Object.keys(emotionalWords).forEach(category => {
      if (emotionalWords[category].some(w => word.includes(w))) {
        counts[category]++;
      }
    });
  });

  // Risk tespiti
  let riskTriggersFound = [];
  let riskLevel = 'low';

  criticalRisks.forEach(trigger => {
    if (lowerText.includes(trigger)) {
      riskTriggersFound.push(trigger);
      riskLevel = 'critical';
    }
  });

  if (riskLevel !== 'critical') {
    highRisks.forEach(trigger => {
      if (lowerText.includes(trigger)) {
        riskTriggersFound.push(trigger);
        if (riskLevel !== 'critical') riskLevel = 'high';
      }
    });
  }

  // Sentiment hesaplama
  const totalEmotional = counts.positive + counts.negative;
  let sentimentScore = 0;
  if (totalEmotional > 0) {
    sentimentScore = (counts.positive - counts.negative) / totalEmotional;
  }

  let sentimentLabel = 'neutral';
  if (sentimentScore > 0.4) sentimentLabel = 'positive';
  else if (sentimentScore < -0.4) sentimentLabel = 'negative';
  else if (sentimentScore < -0.1) sentimentLabel = 'mixed';

  // Mentis Score (0-100)
  let mentisScore = 50;
  mentisScore += counts.positive * 4;
  mentisScore -= counts.negative * 4;
  mentisScore -= counts.depression * 8;
  mentisScore -= counts.anxiety * 6;
  mentisScore += counts.coping * 5; // Yapıcı davranışlar artırır
  mentisScore -= riskTriggersFound.length * 25;
  mentisScore = Math.max(0, Math.min(100, mentisScore));

  // Risk seviyesi (daha detaylı)
  if (riskLevel === 'low') {
    if (counts.depression > 3) riskLevel = 'high';
    else if (counts.anxiety > 2 || counts.negative > 5) riskLevel = 'moderate';
  }

  // Intensity (0-10)
  const intensity = Math.round(
    (counts.anxiety * 1.5 + counts.depression * 2 + counts.negative) / 3
  );

  return {
    mentisScore: Math.round(mentisScore),
    sentiment: { label: sentimentLabel, score: parseFloat(sentimentScore.toFixed(2)) },
    riskLevel,
    riskTriggers: riskTriggersFound,
    categories: counts,
    intensity: Math.min(10, intensity),
  };
}

// ═══════════════════════════════════════════════════════════
// ÇOKLU GÜNLÜK ANALİZİ
// ═══════════════════════════════════════════════════════════

function analyzeMultipleJournals(journals) {
  if (!journals || journals.length === 0) {
    return {
      mentisScore: 50,
      sentiment: { label: 'neutral', score: 0 },
      riskLevel: 'low',
      riskTriggers: [],
      categories: {},
      moodTrend: 'stable',
      dominantCategory: 'balanced',
      recommendations: [
        'Düzenli günlük yazımına devam edin',
        'Ruh halinizi takip edin ve desenleri gözlemleyin',
        'Gerekirse profesyonel yardım alın'
      ],
      analyzedCount: 0,
      intensity: 0,
      trend: 'insufficient_data'
    };
  }

  // Her günlüğü analiz et
  const analyses = journals.map(j => analyzeText(j.content || ''));

  // Ortalamalar
  const avgMentisScore = Math.round(
    analyses.reduce((sum, a) => sum + a.mentisScore, 0) / analyses.length
  );

  const avgSentiment = parseFloat(
    (analyses.reduce((sum, a) => sum + a.sentiment.score, 0) / analyses.length).toFixed(2)
  );

  const avgIntensity = Math.round(
    analyses.reduce((sum, a) => sum + a.intensity, 0) / analyses.length
  );

  // Kategorileri topla
  const categoryTotals = {
    anxiety: 0,
    depression: 0,
    social: 0,
    sleep: 0,
    work: 0,
    physical: 0,
    coping: 0,
    positive: 0,
    negative: 0,
  };

  analyses.forEach(a => {
    Object.keys(categoryTotals).forEach(cat => {
      categoryTotals[cat] += a.categories[cat] || 0;
    });
  });

  // En sık risk tetikleyicileri
  const allRisks = analyses.flatMap(a => a.riskTriggers);
  const riskFreq = {};
  allRisks.forEach(risk => {
    riskFreq[risk] = (riskFreq[risk] || 0) + 1;
  });
  const topRisks = Object.entries(riskFreq)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([risk]) => risk);

  // Baskın kategori
  const dominantCategory = Object.entries(categoryTotals)
    .sort((a, b) => b[1] - a[1])[0]?.[0] || 'balanced';

  // Duygu kategorileri (en önemlileri)
  const emotionCategories = {
    stress: categoryTotals.work + categoryTotals.anxiety,
    anxiety: categoryTotals.anxiety,
    depression: categoryTotals.depression,
    social: categoryTotals.social,
    sleep: categoryTotals.sleep,
    happiness: analyses.filter(a => a.sentiment.score > 0.3).length,
    physical: categoryTotals.physical,
    coping: categoryTotals.coping,
  };

  // Trend (son 3 vs ilk 3)
  let moodTrend = 'stable';
  let trend = 'stable';
  if (analyses.length >= 3) {
    const recentAvg = analyses.slice(-3).reduce((sum, a) => sum + a.sentiment.score, 0) / 3;
    const olderAvg = analyses.slice(0, 3).reduce((sum, a) => sum + a.sentiment.score, 0) / 3;
    const diff = recentAvg - olderAvg;

    if (diff > 0.3) {
      moodTrend = 'improving';
      trend = 'improving';
    } else if (diff < -0.3) {
      moodTrend = 'declining';
      trend = 'declining';
    }
  }

  // Risk seviyesi
  let riskLevel = 'low';
  if (topRisks.length > 0) riskLevel = 'critical';
  else if (categoryTotals.depression > 10) riskLevel = 'high';
  else if (categoryTotals.anxiety > 5 || avgMentisScore < 40) riskLevel = 'moderate';

  // Öneriler (terapist için)
  const recommendations = generateDetailedRecommendations(
    avgMentisScore,
    riskLevel,
    categoryTotals,
    trend,
    analyses
  );

  return {
    mentisScore: avgMentisScore,
    sentiment: {
      label: avgSentiment > 0.2 ? 'positive' : (avgSentiment < -0.2 ? 'negative' : 'mixed'),
      score: avgSentiment,
    },
    riskLevel,
    riskTriggers: topRisks,
    categories: emotionCategories,
    moodTrend,
    dominantCategory,
    recommendations,
    analyzedCount: journals.length,
    intensity: avgIntensity,
    trend,
    detailedMetrics: {
      averageScore: avgMentisScore,
      averageIntensity: avgIntensity,
      emotionDistribution: emotionCategories,
      primaryConcerns: Object.entries(categoryTotals)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 3)
        .map(([cat, count]) => ({ category: cat, count }))
    }
  };
}

// ═══════════════════════════════════════════════════════════
// DETAYLI TERAPIST ÖNERİLERİ
// ═══════════════════════════════════════════════════════════

function generateDetailedRecommendations(score, riskLevel, categories, trend, analyses) {
  const recommendations = [];

  // ACİL RİSK
  if (riskLevel === 'critical') {
    recommendations.push('🚨 ACİL: Danışanla derhal görüşün ve profesyonel yardım değerlendirin');
    recommendations.push('⚠️ İntihar riski değerlendirmesi yapın ve kriz planı oluşturun');
  }

  // SCORE BAZLI
  if (score < 30) {
    recommendations.push('❌ Ciddi mental sağlık sorunu - Yoğun terapi seansları önerilir');
  } else if (score < 50) {
    recommendations.push('⚠️ Orta seviye stres/depresyon - Haftada 2 seans başlayın');
  } else if (score < 70) {
    recommendations.push('✓ Hafif iyileşme gösteriliyor - Günlük yazımı devam ettirin');
  } else {
    recommendations.push('✓ İyi ilerleme - Stratejileri pekiştirmeye odaklanın');
  }

  // KATEGORİ BAZLI
  if (categories.depression > 5) {
    recommendations.push('📋 Depresyon belirtileri belirgin - Davranışsal aktivasyon ve CBT önerilir');
  }

  if (categories.anxiety > 5) {
    recommendations.push('📋 Yüksek anksiyete - Mindfulness, nefes teknikleri önerilir');
  }

  if (categories.sleep > 3) {
    recommendations.push('📋 Uyku sorunu tespit edildi - Uyku hijyeni ve gevşeme teknikleri');
  }

  if (categories.work > 5) {
    recommendations.push('📋 İş stresi yoğun - İş-yaşam dengesi konusunda terapi yapın');
  }

  if (categories.social < 2) {
    recommendations.push('📋 Sosyal izolasyon - Sosyal çıkış aktiviteleri planlayın');
  }

  // TREND BAZLI
  if (trend === 'declining') {
    recommendations.push('⬇️ Durumu kötüleşiyor - Seans sıklığını artırın ve durumu yakından takip edin');
  } else if (trend === 'improving') {
    recommendations.push('⬆️ İyileşme trendi var - Başarılarını vurgulayın ve motivasyonu arttırın');
  }

  // YAPICI DAVRANIŞLAR
  if (categories.coping > 0) {
    recommendations.push('✅ Olumlu baş etme stratejileri kullanıyor - Bunları pekiştirin');
  } else {
    recommendations.push('💡 Sağlık davranışları eksik - Egzersiz, sosyalleşme aktiviteleri önerilir');
  }

  return recommendations.length > 0 ? recommendations : [
    '📝 Daha fazla veri gereklidir - Düzenli günlük yazılmasını teşvik edin'
  ];
}

module.exports = {
  analyzeText,
  analyzeMultipleJournals,
};
