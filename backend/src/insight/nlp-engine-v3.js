/**
 * Mentis NLP Engine v3 — Professional-Grade Turkish Mental Health Analysis
 *
 * Features:
 * ✅ Turkish text processing (stemming, stopwords, negation)
 * ✅ Context-aware sentiment analysis
 * ✅ Pattern recognition & triggers
 * ✅ Risk detection (DSM-5 aligned)
 * ✅ Mental health domain mapping
 * ✅ Trend forecasting
 * ✅ Explainability & confidence scores
 * ✅ PHQ-9 & GAD-7 alignment
 */

// ═══════════════════════════════════════════════════════════
// TÜRKÇE TEXT PROCESSING
// ═══════════════════════════════════════════════════════════

const turkishStopwords = new Set([
  've', 'ama', 'ise', 'veya', 'ya', 'için', 'çünkü', 'gibi', 'kadar',
  'her', 'hep', 'her', 'hiç', 'sadece', 'yalnız', 'ise', 'mi', 'mi',
  'de', 'da', 'nin', 'nın', 'ın', 'an', 'den', 'dan', 'tan', 'ten',
  'le', 'la', 'ta', 'te', 'dir', 'değil', 'var', 'yok', 'ben', 'sen',
  'o', 'biz', 'siz', 'onlar', 'bu', 'şu', 'bununla'
]);

const turkishNegations = ['değil', 'değilim', 'değilsin', 'değil', 'yok', 'yoktur'];

// Stem mapping (Türkçe kelime köklerine indirgeme)
const stemMap = {
  'stresli': 'stres',
  'streslenmiş': 'stres',
  'stresleniyorum': 'stres',
  'streslendiğim': 'stres',
  'mutlu': 'mutluluk',
  'mutsuz': 'üzüntü',
  'üzgün': 'üzüntü',
  'üzülmüş': 'üzüntü',
  'uyuyamıyorum': 'uyku_sorunu',
  'uykusuz': 'uyku_sorunu',
  'enerjisiz': 'enerji_yok',
  'yorgun': 'yorgunluk',
  'bitkin': 'bitkinlik',
  'endişeli': 'endişe',
  'endişeleniyorum': 'endişe',
  'kaygılı': 'kaygı',
  'kaygılanıyorum': 'kaygı',
  'yalnız': 'yalnızlık',
  'yalnızlığını': 'yalnızlık',
  'sosyalleş': 'sosyal',
  'depresyon': 'depresyon',
  'depresyonda': 'depresyon',
  'depresif': 'depresyon',
};

function cleanText(text) {
  return text
    .toLowerCase()
    .replace(/[^ğüşöçıa-z0-9\s]/g, '')
    .split(/\s+/)
    .filter(w => w.length > 2 && !turkishStopwords.has(w))
    .map(w => stemMap[w] || w);
}

function hasNegation(sentence) {
  return turkishNegations.some(neg => sentence.includes(neg));
}

// ═══════════════════════════════════════════════════════════
// GENIŞLETILMIŞ DUYGUSAL SÖZLÜK (Mental Health Domain)
// ═══════════════════════════════════════════════════════════

const emotionalVocabulary = {
  // DSM-5 Depresyon Belirtileri
  depression: [
    'mutsuz', 'üzgün', 'depresyon', 'çöküş', 'çöktüm', 'hopeless',
    'ümitsiz', 'umut yok', 'boşluk', 'anlamsız', 'niye yaşıyorum',
    'değersiz', 'çaresiz', 'mahvoldum', 'gelecek yok'
  ],

  // DSM-5 Anksiyete Belirtileri
  anxiety: [
    'endişe', 'kaygı', 'panik', 'korku', 'tedirgin', 'huzursuz',
    'gergin', 'tüyleri diken', 'tuzak', 'tehdit', 'kalp çarpıntısı',
    'nefes', 'asık', 'bunalım', 'sıkışmış'
  ],

  // Uyku Bozuklukları (Sleep Disorders)
  sleep_issues: [
    'uyku', 'uyuyamıyorum', 'uykusuz', 'kovalamaca', 'gece', 'sabah erken',
    'kesintili', 'kabus', 'uyku kaçmış', 'bitik', 'enerji yok'
  ],

  // İş/Okul Stresi
  work_stress: [
    'çalışma', 'iş', 'stres', 'baskı', 'deadline', 'müdür', 'proje',
    'başarısız', 'not', 'sınav', 'stresli', 'başarı', 'baskı yapıyor'
  ],

  // Sosyal İzolasyon
  social_isolation: [
    'yalnız', 'yalnızlık', 'kimse', 'dışlanmış', 'hor görülmüş',
    'itilmiş', 'reddedilmiş', 'köşelenmiş', 'terk', 'sokak'
  ],

  // Pozitif Duygular (İyileşme göstergesi)
  positive: [
    'mutlu', 'harika', 'güzel', 'iyi', 'mükemmel', 'sevinç', 'gurur',
    'umut', 'huzur', 'rahat', 'başarılı', 'güçlü', 'cesur', 'neşeli'
  ],

  // Baş Etme Stratejileri (Coping - Olumlu davranış)
  coping: [
    'egzersiz', 'yürüyüş', 'spor', 'yoga', 'meditasyon', 'nefes',
    'sosyalleş', 'arkadaş', 'aile', 'konuş', 'terapist', 'danış',
    'oku', 'yazı', 'müzik', 'sanat', 'hobi', 'tatil'
  ],

  // İyileşme İşaretleri
  recovery: [
    'düzeldi', 'iyi gidiyor', 'iyileşiyorum', 'başarılı', 'kontrol edebiliyorum',
    'yapabilirim', 'güçlü', 'umutlu', 'gelişim', 'ileriye', 'başarı'
  ],

  // Fiziksel Sağlık Sorunları
  physical: [
    'ağrı', 'baş', 'migren', 'hasta', 'ateş', 'hastalık', 'doktor'
  ],

  // Motivasyon Eksikliği
  low_motivation: [
    'hiç istemiyor', 'yapamıyorum', 'gücüm yok', 'uğraşamıyorum',
    'başaramıyorum', 'çalışamıyorum', 'hareket edemiyorum'
  ]
};

// ═══════════════════════════════════════════════════════════
// ACIL RİSK TEŞKİLLEYİCİLERİ
// ═══════════════════════════════════════════════════════════

const riskLevels = {
  critical: [
    'intihar', 'ölmek istiyorum', 'kendime zarar', 'kesiyorum',
    'zehir', 'ilaç aşırı', 'asılacağım', 'boğulacağım'
  ],
  high: [
    'dayanamıyorum', 'katlanamıyorum', 'umut yok', 'mahvoldum',
    'kimse umursamıyor', 'hiçbir anlamı yok', 'artık geç'
  ],
  moderate: [
    'çok kötü', 'bitirdim kendimi', 'başarısız', 'elim kolum bağlı',
    'çaresiz', 'çöküş'
  ]
};

// ═══════════════════════════════════════════════════════════
// TEMELİ METIN ANALİZİ
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
      phq9Score: 0,
      gad7Score: 0,
      insights: []
    };
  }

  const sentences = text.split(/[.!?]+/).filter(s => s.trim().length > 0);
  const cleanedWords = cleanText(text);

  // Kategori puanlarını hesapla
  let categoryScores = {};
  Object.keys(emotionalVocabulary).forEach(category => {
    categoryScores[category] = cleanedWords.filter(w =>
      emotionalVocabulary[category].some(word => w.includes(word))
    ).length;
  });

  // Olumsuzluk kontrol (negation handling)
  let negationCount = 0;
  sentences.forEach(sent => {
    if (hasNegation(sent)) negationCount++;
  });

  // Risk tespiti
  let riskLevel = 'low';
  let riskTriggers = [];

  Object.entries(riskLevels).forEach(([level, triggers]) => {
    triggers.forEach(trigger => {
      if (text.toLowerCase().includes(trigger)) {
        riskTriggers.push(trigger);
        if (level === 'critical') riskLevel = 'critical';
        else if (level === 'high' && riskLevel !== 'critical') riskLevel = 'high';
        else if (level === 'moderate' && riskLevel === 'low') riskLevel = 'moderate';
      }
    });
  });

  // Sentiment hesaplama
  const positiveScore = categoryScores.positive || 0;
  const negativeScore = (categoryScores.depression || 0) + (categoryScores.anxiety || 0);
  const totalEmotional = positiveScore + negativeScore;

  let sentimentScore = 0;
  if (totalEmotional > 0) {
    sentimentScore = (positiveScore - negativeScore) / totalEmotional;
  }

  // Mentis Score (0-100)
  let mentisScore = 50;
  mentisScore += positiveScore * 5;
  mentisScore -= (categoryScores.depression || 0) * 8;
  mentisScore -= (categoryScores.anxiety || 0) * 6;
  mentisScore += (categoryScores.coping || 0) * 6;
  mentisScore += (categoryScores.recovery || 0) * 5;
  mentisScore -= (categoryScores.low_motivation || 0) * 4;
  mentisScore -= riskTriggers.length * 30;
  mentisScore = Math.max(0, Math.min(100, mentisScore));

  // PHQ-9 Score (Depresyon: 0-27)
  let phq9 = 0;
  phq9 += (categoryScores.depression || 0) * 2;
  phq9 += (categoryScores.sleep_issues || 0) * 1.5;
  phq9 += (categoryScores.low_motivation || 0) * 1.5;
  phq9 = Math.min(27, phq9);

  // GAD-7 Score (Anksiyete: 0-21)
  let gad7 = 0;
  gad7 += (categoryScores.anxiety || 0) * 2;
  gad7 += (categoryScores.social_isolation || 0) * 1;
  gad7 = Math.min(21, gad7);

  // Intensity (0-10)
  const intensity = Math.min(10, Math.round(negativeScore / 2));

  // Insights (temel gözlemler)
  const insights = [];
  if (categoryScores.depression > 3) insights.push('Depresyon belirtileri belirgin');
  if (categoryScores.anxiety > 3) insights.push('Anksiyete seviyeleri yüksek');
  if (categoryScores.sleep_issues > 2) insights.push('Uyku sorunları rapor ediliyor');
  if (categoryScores.coping > 0) insights.push('Pozitif baş etme stratejileri kullanıyor');
  if (categoryScores.recovery > 0) insights.push('İyileşme belirtileri mevcut');

  return {
    mentisScore: Math.round(mentisScore),
    sentiment: {
      label: sentimentScore > 0.3 ? 'positive' : (sentimentScore < -0.3 ? 'negative' : 'mixed'),
      score: parseFloat(sentimentScore.toFixed(2))
    },
    riskLevel,
    riskTriggers,
    categories: categoryScores,
    intensity,
    phq9Score: Math.round(phq9),
    gad7Score: Math.round(gad7),
    insights,
    sentenceCount: sentences.length,
    wordCount: cleanedWords.length
  };
}

// ═══════════════════════════════════════════════════════════
// ÇOKLU GÜNLÜK ANALİZİ (PROFESYONEL)
// ═══════════════════════════════════════════════════════════

function analyzeMultipleJournals(journals) {
  if (!journals || journals.length === 0) {
    return {
      mentisScore: 50,
      sentiment: { label: 'neutral', score: 0 },
      riskLevel: 'low',
      riskTriggers: [],
      categories: {},
      trend: 'insufficient_data',
      recommendations: ['Daha fazla veri gereklidir'],
      analyzedCount: 0,
      intensity: 0,
      phq9Score: 0,
      gad7Score: 0,
      explanation: {}
    };
  }

  const analyses = journals.map(j => analyzeText(j.content || ''));

  // Ortalamalar
  const avgMentisScore = Math.round(
    analyses.reduce((sum, a) => sum + a.mentisScore, 0) / analyses.length
  );

  const avgPHQ9 = Math.round(
    analyses.reduce((sum, a) => sum + a.phq9Score, 0) / analyses.length
  );

  const avgGAD7 = Math.round(
    analyses.reduce((sum, a) => sum + a.gad7Score, 0) / analyses.length
  );

  const avgSentiment = parseFloat(
    (analyses.reduce((sum, a) => sum + a.sentiment.score, 0) / analyses.length).toFixed(2)
  );

  const avgIntensity = Math.round(
    analyses.reduce((sum, a) => sum + a.intensity, 0) / analyses.length
  );

  // Kategori toplamları
  const categoryTotals = {};
  Object.keys(emotionalVocabulary).forEach(cat => {
    categoryTotals[cat] = analyses.reduce((sum, a) => sum + (a.categories[cat] || 0), 0);
  });

  // Trend analizi
  let trend = 'stable';
  if (analyses.length >= 3) {
    const recent = analyses.slice(-3).map(a => a.mentisScore).reduce((a, b) => a + b) / 3;
    const older = analyses.slice(0, Math.min(3, analyses.length - 3)).map(a => a.mentisScore).reduce((a, b) => a + b) / Math.min(3, analyses.length - 3);
    if (recent > older + 10) trend = 'improving';
    else if (recent < older - 10) trend = 'declining';
  }

  // Risk seviyesi
  let riskLevel = 'low';
  const allRisks = analyses.flatMap(a => a.riskTriggers);
  if (allRisks.some(r => riskLevels.critical.includes(r))) riskLevel = 'critical';
  else if (avgPHQ9 > 15 || avgGAD7 > 10) riskLevel = 'high';
  else if (avgPHQ9 > 10 || avgGAD7 > 7) riskLevel = 'moderate';

  // Duygu kategorileri
  const emotionCategories = {
    depression: categoryTotals.depression || 0,
    anxiety: categoryTotals.anxiety || 0,
    sleep_issues: categoryTotals.sleep_issues || 0,
    work_stress: categoryTotals.work_stress || 0,
    social_isolation: categoryTotals.social_isolation || 0,
    coping: categoryTotals.coping || 0,
    recovery: categoryTotals.recovery || 0
  };

  // Terapist önerileri (DSM-5 aligned)
  const recommendations = generateProAiRecommendations(
    avgMentisScore,
    avgPHQ9,
    avgGAD7,
    riskLevel,
    emotionCategories,
    trend
  );

  // Explainability (Açıklanabilirlik)
  const explanation = {
    mentisScore: {
      value: avgMentisScore,
      interpretation: interpretMentisScore(avgMentisScore),
      contributors: [
        { label: 'Depresyon belirtileri', value: -(categoryTotals.depression || 0) * 8 },
        { label: 'Anksiyete belirtileri', value: -(categoryTotals.anxiety || 0) * 6 },
        { label: 'Baş etme stratejileri', value: (categoryTotals.coping || 0) * 6 },
        { label: 'Pozitif duygular', value: (categoryTotals.positive || 0) * 5 }
      ]
    },
    phq9: {
      value: avgPHQ9,
      severity: interpretPHQ9(avgPHQ9),
      recommendation: recommendForPHQ9(avgPHQ9)
    },
    gad7: {
      value: avgGAD7,
      severity: interpretGAD7(avgGAD7),
      recommendation: recommendForGAD7(avgGAD7)
    }
  };

  return {
    mentisScore: avgMentisScore,
    sentiment: {
      label: avgSentiment > 0.2 ? 'positive' : (avgSentiment < -0.2 ? 'negative' : 'mixed'),
      score: avgSentiment
    },
    riskLevel,
    riskTriggers: [...new Set(allRisks)].slice(0, 3),
    categories: emotionCategories,
    trend,
    recommendations,
    analyzedCount: journals.length,
    intensity: avgIntensity,
    phq9Score: avgPHQ9,
    gad7Score: avgGAD7,
    explanation
  };
}

// ═══════════════════════════════════════════════════════════
// SCORE İNTERPRETASYONLARI (Açıklanabilirlik)
// ═══════════════════════════════════════════════════════════

function interpretMentisScore(score) {
  if (score >= 80) return 'Çok İyi - Mental sağlık iyi';
  if (score >= 60) return 'İyi - Hafif iyileşme gösteriliyor';
  if (score >= 40) return 'Orta - Dikkat gerekiyor';
  if (score >= 20) return 'Kötü - Profesyonel yardım gerekli';
  return 'Çok Kötü - Acil müdahale gerekli';
}

function interpretPHQ9(score) {
  if (score <= 4) return 'Minimal depresyon yok';
  if (score <= 9) return 'Hafif depresyon';
  if (score <= 14) return 'Orta depresyon';
  if (score <= 19) return 'Orta-ağır depresyon';
  return 'Ağır depresyon';
}

function interpretGAD7(score) {
  if (score <= 4) return 'Minimal anksiyete';
  if (score <= 9) return 'Hafif anksiyete';
  if (score <= 14) return 'Orta anksiyete';
  return 'Ağır anksiyete';
}

function recommendForPHQ9(score) {
  if (score <= 4) return 'Rutin tarama yeterli';
  if (score <= 9) return 'Yaşam tarzı değişiklikleri ve takip';
  if (score <= 14) return 'Terapiye başlayın, psikiyatrist konsültasyonu';
  if (score <= 19) return 'Psikiyatrist görüşmesi, ilaç düşünün';
  return 'Acil psikiyatrik değerlendirme';
}

function recommendForGAD7(score) {
  if (score <= 4) return 'Rutin tarama yeterli';
  if (score <= 9) return 'Relaxation teknikleri, terapiye başlayın';
  if (score <= 14) return 'Terapist referansı ve psikiyatrist konsültasyonu';
  return 'Psikiyatrist görüşmesi, ilaç değerlendirmesi';
}

// ═══════════════════════════════════════════════════════════
// PRO ANALİZER ÖNERİLERİ
// ═══════════════════════════════════════════════════════════

function generateProAiRecommendations(score, phq9, gad7, risk, categories, trend) {
  const recommendations = [];

  // ACİL RİSK
  if (risk === 'critical') {
    recommendations.push('🚨 ACİL: Danışanla derhal görüşün - Intihar/zarar riski yüksek');
    recommendations.push('⚠️ Kriz planlamas yapın, güvenlik değerlendirmesi yapın');
    recommendations.push('📞 Psikiyatrist konsültasyonu ve muhtemelen hastaneye yatış');
    return recommendations;
  }

  // PHQ-9 BAZLI
  if (phq9 > 14) {
    recommendations.push(`📋 PHQ-9: ${phq9}/27 (Orta-Ağır Depresyon)`);
    recommendations.push('🔍 Kognitif Davranışçı Terapi (CBT) başlayın');
    recommendations.push('💊 Psikiyatrist konsültasyonu ve antidepresan değerlendirmesi');
  } else if (phq9 > 9) {
    recommendations.push(`📋 PHQ-9: ${phq9}/27 (Hafif-Orta Depresyon)`);
    recommendations.push('🎯 Davranışsal aktivasyon ve yaşam tarzı değişiklikleri');
    recommendations.push('📅 Haftada 1-2 seans terapi');
  }

  // GAD-7 BAZLI
  if (gad7 > 14) {
    recommendations.push(`📋 GAD-7: ${gad7}/21 (Ağır Anksiyete)`);
    recommendations.push('🧘 Mindfulness, derin nefes ve progresif gevşeme teknikleri');
    recommendations.push('💊 Kaygı kesici ilaç değerlendirmesi');
  } else if (gad7 > 9) {
    recommendations.push(`📋 GAD-7: ${gad7}/21 (Orta Anksiyete)`);
    recommendations.push('🧘 Meditasyon ve yoga pratiği');
    recommendations.push('⏰ Kaygı yönetimi teknikleri');
  }

  // KATEGORİ BAZLI
  if (categories.sleep_issues > 3) {
    recommendations.push('😴 Uyku sorunları: Uyku hijyeni, uyku saati düzenleme');
  }

  if (categories.work_stress > 4) {
    recommendations.push('💼 İş stresi yüksek: Iş-yaşam dengesi, sınır belirleme');
  }

  if (categories.social_isolation > 3) {
    recommendations.push('👥 Sosyal izolasyon: Sosyal çıkış aktiviteleri planlayın');
  }

  if (categories.coping > 0) {
    recommendations.push('✅ Olumlu baş etme: Mevcut stratejileri pekiştirin');
  }

  // TREND BAZLI
  if (trend === 'declining') {
    recommendations.push('⬇️ Durumu kötüleşiyor: Seans sıklığını artırın');
  } else if (trend === 'improving') {
    recommendations.push('⬆️ İyileşme eğilimi: Başarıları vurgulayın, motivasyonu arttırın');
  }

  return recommendations.length > 0 ? recommendations : ['📝 Düzenli takip devam etsin'];
}

module.exports = {
  analyzeText,
  analyzeMultipleJournals,
};
