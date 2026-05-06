// Mentis Insight endpoint'i.
// Sadece terapist erişebilir; bir danışanın günlüklerini analiz eder.
// Türkçe NLP motoru ile profesyonel analiz.

const express = require('express');
const { authRequired, therapistOnly } = require('../middleware/jwt');
const { analyzeMultipleJournals } = require('../insight/nlp-engine-v2');
const { demoClients, mockJournals } = require('../shared/stores');

const router = express.Router();

router.use(authRequired);
router.use(therapistOnly);

/**
 * POST /insight
 * body: { clientId? , limit? }
 *  - clientId verilirse o danışanın son N girişi.
 *  - clientId yoksa terapistin tüm danışanlarının son N girişi.
 *  - default limit: 5.
 */
router.post('/', async (req, res) => {
  const { clientId, limit = 10 } = req.body || {};

  // Danışan günlükleri al shared store'dan
  let journals = [];
  const journalList = Array.from(mockJournals.values());

  if (clientId) {
    journals = journalList
      .filter(j => j.clientId === clientId)
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .slice(0, limit);
  } else {
    journals = journalList
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .slice(0, limit);
  }

  // NLP analizi yap
  const analysis = analyzeMultipleJournals(journals);

  // Danışan adını bul
  let clientName = 'Tüm danışanlar';
  if (clientId) {
    const client = demoClients.get(clientId);
    if (client) clientName = client.name;
  }

  console.log(`✅ Insight analizi tamamlandı (${analysis.analyzedCount} günlük, danışan: ${clientName})`);

  // Duygu kategorilerini topWords format'ına çevir
  const topWords = Object.entries(analysis.categories || {})
    .filter(([_, count]) => count > 0)
    .sort((a, b) => b[1] - a[1])
    .map(([word, count]) => ({ word, count }));

  res.json({
    clientName,
    mentisScore: analysis.mentisScore,
    sentiment: {
      overallScore: analysis.sentiment.score,
      overallLabel: analysis.sentiment.label,
      histogram: {},
    },
    risk: {
      score: analysis.riskLevel === 'critical' ? 90 : (analysis.riskLevel === 'high' ? 60 : (analysis.riskLevel === 'moderate' ? 40 : 20)),
      level: analysis.riskLevel,
      triggers: analysis.riskTriggers,
    },
    topWords,
    recommendation: {
      title: 'Mentis Terapist Önerileri',
      tone: analysis.sentiment.label,
      message: analysis.recommendations.join(' • '),
    },
    moodTrend: analysis.trend || analysis.moodTrend,
    dominantCategory: analysis.dominantCategory,
    analyzedCount: analysis.analyzedCount,
    hasData: analysis.analyzedCount > 0,
    intensity: analysis.intensity || 0,
    detailedMetrics: analysis.detailedMetrics,
  });
});

module.exports = router;
