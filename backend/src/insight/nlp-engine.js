/**
 * Mentis NLP Engine
 * Türkçe günlük analizi için basit ama etkili NLP
 */

// Duygusal kelimeler sözlüğü (Türkçe)
const emotionalWords = {
  positive: [
    'mutlu', 'güzel', 'harika', 'iyi', 'mükemmel', 'sevgi', 'seviyorum',
    'heyecan', 'başarı', 'başardım', 'gurur', 'eğlendi', 'sakin', 'rahat',
    'huzur', 'şanslı', 'umut', 'ümit', 'başarılı', 'güçlü', 'cesur'
  ],
  negative: [
    'stres', 'endişe', 'korku', 'korkuyorum', 'ağlayan', 'ağladım', 'mutsuz',
    'üzgün', 'kötü', 'berbat', 'hüzün', 'çaresiz', 'sıkıntı', 'rahatsız',
    'kaygı', 'panik', 'hayal kırıklığı', 'hayal kırılganlık', 'çöküş',
    'yalnız', 'yalnızlık', 'yalnıyım', 'hopeless', 'hopeless'
  ],
  anxiety: [
    'endişe', 'kaygı', 'panik', 'korku', 'fırıldak', 'tedirgin', 'huzursuz',
    'korkuyorum', 'korkarak', 'panik', 'çöküş', 'çöktüm', 'felaket'
  ],
  depression: [
    'mutsuz', 'depresyon', 'ümitsiz', 'umut yok', 'boşluk', 'değersiz',
    'değerli değilim', 'çöküş', 'çöktüm', 'hiç istemiyor', 'hiçbir şey'
  ],
  social: [
    'yalnız', 'yalnızlık', 'arkadaş', 'aile', 'sevgi', 'ilişki', 'kimse',
    'sosyal', 'etkinlik', 'partisi', 'buluştu', 'konuştu', 'topluluk'
  ],
  sleep: [
    'uyku', 'uyuyamıyorum', 'uykusuz', 'uyumadım', 'kovalamaca', 'uyanık',
    'yorgun', 'bitkin', 'enerjisiz'
  ],
  work: [
    'çalışma', 'iş', 'proje', 'başarı', 'başarısız', 'baskı', 'deadline',
    'stres', 'mutsuz', 'tatmin', 'başarılı', 'yükseltme', 'promosyon'
  ],
};

// Risk tetikleyicileri
const riskTriggers = [
  'intihar', 'ölmek', 'ölümü', 'öldürmek',
  'kendime zarar', 'yazık', 'çöküş', 'umut yok',
  'kimse umursamıyor', 'tamamen yalnızım', 'artık dayanamıyorum'
];

/**
 * Metni analiz et ve Mentis Score + sentiment döndür
 */
function analyzeText(text) {
  if (!text || text.trim().length === 0) {
    return {
      mentisScore: 50,
      sentiment: { label: 'neutral', score: 0 },
      riskLevel: 'low',
      riskTriggers: [],
      topKeywords: [],
      categories: {},
    };
  }

  const lowerText = text.toLowerCase();
  const words = lowerText.split(/\s+/).filter(w => w.length > 2);

  // Duygu analizi
  let positiveCount = 0;
  let negativeCount = 0;
  let anxietyCount = 0;
  let depressionCount = 0;
  let socialCount = 0;
  let sleepCount = 0;
  let workCount = 0;
  let riskTriggersFound = [];

  words.forEach(word => {
    if (emotionalWords.positive.some(w => word.includes(w))) positiveCount++;
    if (emotionalWords.negative.some(w => word.includes(w))) negativeCount++;
    if (emotionalWords.anxiety.some(w => word.includes(w))) anxietyCount++;
    if (emotionalWords.depression.some(w => word.includes(w))) depressionCount++;
    if (emotionalWords.social.some(w => word.includes(w))) socialCount++;
    if (emotionalWords.sleep.some(w => word.includes(w))) sleepCount++;
    if (emotionalWords.work.some(w => word.includes(w))) workCount++;
  });

  // Risk tetikleyicileri kontrol et
  riskTriggers.forEach(trigger => {
    if (lowerText.includes(trigger)) {
      riskTriggersFound.push(trigger);
    }
  });

  // Sentiment hesaplama (-1 to +1)
  const totalEmotional = positiveCount + negativeCount;
  let sentimentScore = 0;
  if (totalEmotional > 0) {
    sentimentScore = (positiveCount - negativeCount) / totalEmotional;
  }

  // Sentiment etiketi
  let sentimentLabel = 'neutral';
  if (sentimentScore > 0.3) sentimentLabel = 'positive';
  else if (sentimentScore < -0.3) sentimentLabel = 'negative';
  else if (sentimentScore < -0.1) sentimentLabel = 'mixed';

  // Mentis Score (0-100)
  // Base: 50
  // +Pozitif duygu: +5/kelime
  // -Negatif duygu: -5/kelime
  // -Risk tetikleyici: -15/tetikleyici
  let mentisScore = 50;
  mentisScore += positiveCount * 4;
  mentisScore -= negativeCount * 4;
  mentisScore -= depressionCount * 8;
  mentisScore -= anxietyCount * 6;
  mentisScore -= riskTriggersFound.length * 20;
  mentisScore = Math.max(0, Math.min(100, mentisScore));

  // Risk seviyesi
  let riskLevel = 'low';
  if (riskTriggersFound.length > 0) riskLevel = 'critical';
  else if (depressionCount > 3) riskLevel = 'high';
  else if (anxietyCount > 2 || negativeCount > 5) riskLevel = 'moderate';

  // Kategoriler
  const categories = {
    anxiety: anxietyCount,
    depression: depressionCount,
    social: socialCount,
    sleep: sleepCount,
    work: workCount,
  };

  // Anahtar kelimeler (en sık olanlar)
  const wordFreq = {};
  words.forEach(word => {
    if (word.length > 3) {
      wordFreq[word] = (wordFreq[word] || 0) + 1;
    }
  });
  const topKeywords = Object.entries(wordFreq)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([word, count]) => ({ word, count }));

  return {
    mentisScore: Math.round(mentisScore),
    sentiment: {
      label: sentimentLabel,
      score: parseFloat(sentimentScore.toFixed(2)),
    },
    riskLevel,
    riskTriggers: riskTriggersFound,
    topKeywords,
    categories,
  };
}

/**
 * Birden fazla günlüğü analiz et
 */
function analyzeMultipleJournals(journals) {
  if (!journals || journals.length === 0) {
    return {
      mentisScore: 50,
      sentiment: { label: 'neutral', score: 0 },
      riskLevel: 'low',
      riskTriggers: [],
      topKeywords: [],
      moodTrend: 'stable',
      dominantCategory: 'balanced',
      recommendations: [
        'Düzenli günlük yazıp ruh halini not almaya devam edin',
        'Kendini iyi hissettiğin günleri analiz ederek desenleri tanımla',
        'Gerekirse profesyonel yardım alma konusunda terapist ile konuş'
      ],
      analyzedCount: 0,
    };
  }

  // Her günlüğü analiz et
  const analyses = journals.map(j => analyzeText(j.content || ''));

  // Ortalamaları hesapla
  const avgMentisScore = Math.round(
    analyses.reduce((sum, a) => sum + a.mentisScore, 0) / analyses.length
  );

  const avgSentiment = parseFloat(
    (analyses.reduce((sum, a) => sum + a.sentiment.score, 0) / analyses.length).toFixed(2)
  );

  // En sık risk
  const allRisks = analyses.flatMap(a => a.riskTriggers);
  const riskFreq = {};
  allRisks.forEach(risk => {
    riskFreq[risk] = (riskFreq[risk] || 0) + 1;
  });
  const topRisks = Object.entries(riskFreq)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([risk]) => risk);

  // En sık kategoriler
  const categoryTotals = {
    anxiety: 0,
    depression: 0,
    social: 0,
    sleep: 0,
    work: 0,
  };
  analyses.forEach(a => {
    Object.keys(categoryTotals).forEach(cat => {
      categoryTotals[cat] += a.categories[cat] || 0;
    });
  });
  const dominantCategory = Object.entries(categoryTotals)
    .sort((a, b) => b[1] - a[1])[0][0];

  // Duygu kategorileri — frequency değil, meaningful categories göster
  const emotionCategories = {
    stress: categoryTotals.work + categoryTotals.anxiety,
    anxiety: categoryTotals.anxiety,
    depression: categoryTotals.depression,
    social: categoryTotals.social,
    sleep: categoryTotals.sleep,
    happiness: analyses.filter(a => a.sentiment.score > 0.3).length,
  };
  const topKeywords = Object.entries(emotionCategories)
    .filter(([_, count]) => count > 0)
    .sort((a, b) => b[1] - a[1])
    .map(([category, count]) => ({ word: category, count }));

  // Risk seviyesi
  let riskLevel = 'low';
  if (topRisks.length > 0) riskLevel = 'critical';
  else if (categoryTotals.depression > 10) riskLevel = 'high';
  else if (categoryTotals.anxiety > 5 || avgMentisScore < 40) riskLevel = 'moderate';

  // Mood trend (son 3 ile önceki 3'ü karşılaştır)
  let moodTrend = 'stable';
  if (analyses.length >= 3) {
    const recentAvg = analyses.slice(-3).reduce((sum, a) => sum + a.sentiment.score, 0) / 3;
    const olderAvg = analyses.slice(0, 3).reduce((sum, a) => sum + a.sentiment.score, 0) / 3;
    if (recentAvg > olderAvg + 0.2) moodTrend = 'improving';
    else if (recentAvg < olderAvg - 0.2) moodTrend = 'declining';
  }

  // Öneriler
  const recommendations = generateRecommendations(avgMentisScore, riskLevel, categoryTotals);

  return {
    mentisScore: avgMentisScore,
    sentiment: {
      label: avgSentiment > 0.2 ? 'positive' : (avgSentiment < -0.2 ? 'negative' : 'mixed'),
      score: avgSentiment,
    },
    riskLevel,
    riskTriggers: topRisks,
    topKeywords,
    moodTrend,
    dominantCategory,
    recommendations,
    analyzedCount: journals.length,
  };
}

function generateRecommendations(score, riskLevel, categories) {
  const recommendations = [];

  if (riskLevel === 'critical') {
    recommendations.push('⚠️ Acil destek gerekebilir - Profesyonel yardım alınız');
    recommendations.push('Güvenilir biri ile durumunuzu paylaşın');
  }

  if (score < 30) {
    recommendations.push('Ruh hali çok düşük - Profesyonel terapist ile görüşün');
  } else if (score < 50) {
    recommendations.push('Kendine biraz daha iyi bakma vakti');
  }

  if (categories.anxiety > 5) {
    recommendations.push('Meditasyon veya derin nefes alışkanlıkları deneyin');
  }

  if (categories.depression > 5) {
    recommendations.push('Güneş ışığına maruz kalma süresini artırın');
    recommendations.push('Sosyal aktivitelere katılmaya çalışın');
  }

  if (categories.sleep > 3) {
    recommendations.push('Uyku hijyenine dikkat edin (saatler, ortam, ekran süresi)');
  }

  if (categories.work > 5) {
    recommendations.push('İş stresini yönetmek için terapi teknikleri öğrenin');
  }

  if (categories.social < 2) {
    recommendations.push('Sosyal bağlantıları artırmaya çalışın (aile, arkadaş)');
  }

  if (recommendations.length === 0) {
    recommendations.push('Günlük yazmaya devam edin');
    recommendations.push('İyi alışkanlıklarınızı sürdürün');
  }

  return recommendations;
}

module.exports = {
  analyzeText,
  analyzeMultipleJournals,
};
