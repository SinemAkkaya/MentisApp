// Mentis Insight Engine — kendi yazdığımız NLP motoru.
// 4 katmanlı analiz:
//   1) Sentiment (Türkçe sözlük tabanlı duygu)
//   2) Risk (kriz/uyarı kelime tespiti)
//   3) Word Frequency (en sık kullanılan anlamlı kelimeler, stopword filtreli)
//   4) Mentis Score (0-100 birleşik skor + kişisel rapor)

const {
  TURKISH_STOPWORDS,
  SENTIMENT_PHRASES,
  SENTIMENT_WORDS,
  RISK_PHRASES,
  RISK_WORDS,
} = require('./lexicons');

// ────────────────────────────────────────────────────────────
//  Yardımcı fonksiyonlar
// ────────────────────────────────────────────────────────────

/** Türkçe karakterleri normalize eder, küçük harfe çevirir. */
function normalize(s) {
  if (!s) return '';
  return String(s)
    .toLowerCase()
    .replace(/ı/g, 'i')
    .replace(/ş/g, 's')
    .replace(/ğ/g, 'g')
    .replace(/ü/g, 'u')
    .replace(/ö/g, 'o')
    .replace(/ç/g, 'c')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Metni token'lara ayır (Türkçe karakter set + sayı). */
function tokenize(text) {
  return text
    .split(/[^\p{L}\p{N}]+/u)
    .filter((t) => t && t.length > 1);
}

// ────────────────────────────────────────────────────────────
//  1) SENTIMENT
// ────────────────────────────────────────────────────────────

function analyzeSentimentEntry(text) {
  const norm = normalize(text);
  if (!norm) return { score: 0, label: 'neutral', matches: 0 };

  let sum = 0;
  let matched = 0;
  let working = ' ' + norm + ' ';

  // Çok kelimeli
  for (const [phrase, w] of Object.entries(SENTIMENT_PHRASES)) {
    const pn = normalize(phrase);
    const needle = ' ' + pn + ' ';
    let idx = working.indexOf(needle);
    while (idx >= 0) {
      sum += w;
      matched++;
      working = working.replace(needle, ' ' + '·'.repeat(pn.length) + ' ');
      idx = working.indexOf(needle);
    }
  }

  // Tek kelime / kök
  const tokens = tokenize(working).filter((t) => !t.includes('·'));
  for (const t of tokens) {
    const exact = SENTIMENT_WORDS[t];
    if (exact !== undefined) {
      sum += exact;
      matched++;
      continue;
    }
    for (const [k, v] of Object.entries(SENTIMENT_WORDS)) {
      if (k.length >= 4 && t.startsWith(k)) {
        sum += v;
        matched++;
        break;
      }
    }
  }

  const avg = matched === 0 ? 0 : sum / matched;
  return {
    score: Math.max(-2, Math.min(2, avg)),
    label: scoreToSentLabel(avg),
    matches: matched,
  };
}

function scoreToSentLabel(s) {
  if (s <= -1.25) return 'very_negative';
  if (s <= -0.25) return 'negative';
  if (s < 0.25) return 'neutral';
  if (s < 1.25) return 'positive';
  return 'very_positive';
}

// ────────────────────────────────────────────────────────────
//  2) RISK
// ────────────────────────────────────────────────────────────

function analyzeRiskEntry(text) {
  const norm = normalize(text);
  if (!norm) return { weight: 0, maxTier: 1, hits: [] };

  let weight = 0;
  let maxTier = 1;
  const hits = [];
  let working = ' ' + norm + ' ';

  for (const [phrase, tier] of Object.entries(RISK_PHRASES)) {
    const pn = normalize(phrase);
    const needle = ' ' + pn + ' ';
    let idx = working.indexOf(needle);
    while (idx >= 0) {
      weight += tier;
      if (tier > maxTier) maxTier = tier;
      hits.push(phrase);
      working = working.replace(needle, ' ' + '·'.repeat(pn.length) + ' ');
      idx = working.indexOf(needle);
    }
  }

  const tokens = tokenize(working).filter((t) => !t.includes('·'));
  for (const t of tokens) {
    let tier = RISK_WORDS[t];
    if (tier === undefined) {
      for (const [k, v] of Object.entries(RISK_WORDS)) {
        if (k.length >= 4 && t.startsWith(k)) { tier = v; break; }
      }
    }
    if (tier !== undefined) {
      weight += tier;
      if (tier > maxTier) maxTier = tier;
      if (hits.length < 8) hits.push(t);
    }
  }

  return { weight, maxTier, hits };
}

function levelFromScore(score100) {
  if (score100 >= 70) return 'critical';
  if (score100 >= 50) return 'high';
  if (score100 >= 25) return 'moderate';
  return 'low';
}

// ────────────────────────────────────────────────────────────
//  3) WORD FREQUENCY (Türkçe stop-word filtreli)
// ────────────────────────────────────────────────────────────

function analyzeWordFrequency(entries, topN = 10) {
  const counts = new Map();
  for (const e of entries) {
    const norm = normalize(e.content);
    const tokens = tokenize(norm);
    for (let t of tokens) {
      // Çok kısa ya da stop-word ise atla
      if (t.length < 3) continue;
      // Stop-words listesini de normalize et
      const stopNorm = normalize(t);
      let isStop = false;
      for (const sw of TURKISH_STOPWORDS) {
        if (normalize(sw) === stopNorm) { isStop = true; break; }
      }
      if (isStop) continue;

      counts.set(t, (counts.get(t) || 0) + 1);
    }
  }
  // En sık N kelime
  const top = [...counts.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, topN)
    .map(([word, count]) => ({ word, count }));
  return top;
}

// ────────────────────────────────────────────────────────────
//  4) MENTIS SCORE — kompozit puan + kişisel rapor
// ────────────────────────────────────────────────────────────

/**
 * Mentis Score 0-100:
 *   - 100 = mükemmel iyi olma hali
 *   -  0 = ciddi sıkıntı / kriz
 * Bileşenler:
 *   sentiment: -2..+2 → 0..100 lineer
 *   risk: 0..25 raw (cap) → 100..0 ters
 *   ağırlık: sentiment %50, risk %50
 */
function computeMentisScore(sentimentReport, riskReport) {
  const sentNorm = ((sentimentReport.overallScore + 2) / 4) * 100; // 0..100
  const riskCap = Math.min(riskReport.rawWeightTotal, 25);
  const riskNorm = 100 - (riskCap * 100) / 25; // ters çevir
  const score = Math.round(sentNorm * 0.5 + riskNorm * 0.5);
  return Math.max(0, Math.min(100, score));
}

function mentisRecommendation(score, riskLevel, dominantSent) {
  if (riskLevel === 'critical') {
    return {
      title: 'ACİL',
      tone: 'critical',
      message:
        'Kriz sinyali içeren ifadeler tespit edildi. Danışana doğrudan ulaşmayı ve gerekirse profesyonel yönlendirme yapmayı düşün.',
    };
  }
  if (riskLevel === 'high' || score < 30) {
    return {
      title: 'YÜKSEK DİKKAT',
      tone: 'high',
      message:
        'Belirgin tükenme, çaresizlik ya da kayıp duygusu sinyalleri var. Bir sonraki seansı öne almayı düşünebilirsin.',
    };
  }
  if (riskLevel === 'moderate' || score < 50) {
    return {
      title: 'TAKİBE AL',
      tone: 'moderate',
      message:
        'Ortanca seviyede stres ve üzüntü dili var. Seansta tetikleyici olayları ele al, baş etme stratejilerini yenile.',
    };
  }
  if (score >= 75) {
    return {
      title: 'OLUMLU GİDİŞAT',
      tone: 'positive',
      message:
        'Danışanın dilinde umut, huzur ve enerji baskın. Mevcut stratejileri pekiştirmek faydalı olabilir.',
    };
  }
  return {
    title: 'DENGELİ',
    tone: 'neutral',
    message:
      'Genel tablo dengeli görünüyor. Olumlu ve olumsuz duygular dengede; belirgin bir kriz işareti yok.',
  };
}

// ────────────────────────────────────────────────────────────
//  ANA ENTRY POINT — analyzeJournals(entries)
// ────────────────────────────────────────────────────────────

function analyzeJournals(entries) {
  if (!Array.isArray(entries) || entries.length === 0) {
    return {
      hasData: false,
      mentisScore: 50,
      sentiment: { overallScore: 0, overallLabel: 'neutral', perEntry: [], histogram: {} },
      risk: { score: 0, level: 'low', maxTier: 1, triggers: [] },
      topWords: [],
      recommendation: {
        title: 'VERİ YOK',
        tone: 'neutral',
        message: 'Bu danışan için henüz analiz edilebilecek günlük girişi yok.',
      },
      analyzedCount: 0,
    };
  }

  // Sentiment
  const perEntrySent = entries.map((e) => ({
    entryId: e.id,
    ...analyzeSentimentEntry(e.content),
  }));
  let sumSent = 0;
  let matchedSent = 0;
  const histogram = {
    very_negative: 0, negative: 0, neutral: 0,
    positive: 0, very_positive: 0,
  };
  for (const s of perEntrySent) {
    if (s.matches > 0) { sumSent += s.score; matchedSent++; }
    histogram[s.label] = (histogram[s.label] || 0) + 1;
  }
  const sentAvg = matchedSent === 0 ? 0 : sumSent / matchedSent;
  const sentReport = {
    overallScore: sentAvg,
    overallLabel: scoreToSentLabel(sentAvg),
    perEntry: perEntrySent,
    histogram,
  };

  // Risk
  const perEntryRisk = entries.map((e) => ({
    entryId: e.id,
    ...analyzeRiskEntry(e.content),
  }));
  let totalWeight = 0;
  let maxTier = 1;
  const allHits = [];
  for (const r of perEntryRisk) {
    totalWeight += r.weight;
    if (r.maxTier > maxTier) maxTier = r.maxTier;
    allHits.push(...r.hits);
  }
  const cappedW = Math.min(totalWeight, 25);
  const riskScore = Math.round((cappedW * 100) / 25);
  const riskReport = {
    score: riskScore,
    level: levelFromScore(riskScore),
    maxTier,
    rawWeightTotal: totalWeight,
    triggers: [...new Set(allHits)].slice(0, 10),
  };

  // Word frequency
  const topWords = analyzeWordFrequency(entries, 10);

  // Mentis Score
  const mentisScore = computeMentisScore(sentReport, riskReport);

  // Tavsiye
  const recommendation = mentisRecommendation(
    mentisScore,
    riskReport.level,
    sentReport.overallLabel,
  );

  return {
    hasData: true,
    mentisScore,
    sentiment: sentReport,
    risk: riskReport,
    topWords,
    recommendation,
    analyzedCount: entries.length,
  };
}

module.exports = {
  analyzeJournals,
  // expose for tests
  analyzeSentimentEntry,
  analyzeRiskEntry,
  analyzeWordFrequency,
  computeMentisScore,
  normalize,
};
