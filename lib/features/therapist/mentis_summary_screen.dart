import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/client_account.dart';
import '../../models/journal_entry.dart';
import '../../services/api_service.dart';

/// Mentis Özeti Ekranı
/// Terapist danışanlarını seçip günlükleri görüp, yapay zeka tarafından
/// analiz edilen Mentis Score, Sentiment, Risk Level ve önerileri görebilir.
class MentisSummaryScreen extends StatefulWidget {
  const MentisSummaryScreen({super.key});

  @override
  State<MentisSummaryScreen> createState() => _MentisSummaryScreenState();
}

class _MentisSummaryScreenState extends State<MentisSummaryScreen> {
  final ApiService _api = ApiService();

  bool _loadingInsight = false;
  String? _errorInsight;
  MentisInsight? _insight;

  String? _selectedClientId;
  String _selectedClientName = 'Danışan seçin';

  @override
  void initState() {
    super.initState();
    _api.fetchClients().catchError((_) => <ClientAccount>[]);
    _api.fetchJournals().catchError((_) => <JournalEntry>[]);
  }

  Future<void> _generateInsight() async {
    if (_selectedClientId == null) {
      _snack('Danışan seçin', AppColors.warning);
      return;
    }

    setState(() {
      _loadingInsight = true;
      _errorInsight = null;
      _insight = null;
    });

    try {
      final res = await _api.generateInsight(
        clientId: _selectedClientId,
        limit: 20,
      );
      if (!mounted) return;
      setState(() => _insight = res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorInsight = e.toString());
    } finally {
      if (mounted) setState(() => _loadingInsight = false);
    }
  }

  void _snack(String msg, Color c) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mentis Özeti')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intro Card
              _buildIntroCard(),
              const SizedBox(height: 20),

              // Danışan Seçimi
              const Text('Danışan Seçin',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _buildClientDropdown(),
              const SizedBox(height: 16),

              // Danışan Günlükleri
              if (_selectedClientId != null) ...[
                const Text('Günlükleri',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _buildJournalsList(),
                const SizedBox(height: 20),
              ],

              // Analiz Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loadingInsight ? null : _generateInsight,
                  icon: const Icon(Icons.insights_rounded),
                  label: _loadingInsight
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Text('Mentis Analiz Yap'),
                ),
              ),
              const SizedBox(height: 20),

              // Hata Mesajı
              if (_errorInsight != null) _buildError(_errorInsight!),

              // Insight Sonuçları
              if (_insight != null) _buildInsightCard(_insight!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.secondaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow:
            AppTheme.softShadow(AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            child:
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mentis Özeti',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text(
                  'Danışanın günlükleri Türkçe NLP ile analiz edilerek ruh hali ve mental sağlık skoru hesaplanır.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientDropdown() {
    return ValueListenableBuilder<List<ClientAccount>>(
      valueListenable: _api.clientsNotifier,
      builder: (context, clients, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDEBF7)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedClientId,
              hint: Row(
                children: [
                  const Icon(Icons.person_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(_selectedClientName),
                ],
              ),
              items: clients
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ))
                  .toList(),
              onChanged: (id) {
                if (id != null) {
                  final client = clients.firstWhere((c) => c.id == id);
                  setState(() {
                    _selectedClientId = id;
                    _selectedClientName = client.name;
                    _insight = null;
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildJournalsList() {
    return ValueListenableBuilder<List<JournalEntry>>(
      valueListenable: _api.journalsNotifier,
      builder: (context, journals, _) {
        final clientJournals = journals
            .where((j) => j.clientId == _selectedClientId)
            .toList();

        if (clientJournals.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text('Bu danışanın henüz günlüğü yok',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
          );
        }

        return Column(
          children: clientJournals
              .map((j) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildJournalTile(j),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildJournalTile(JournalEntry j) {
    final moodEmoji = {
      'happy': '😊',
      'sad': '😢',
      'anxious': '😰',
      'neutral': '😐',
      'angry': '😠',
      'excited': '🤩',
    }[j.mood.key] ?? '📝';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEBF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(moodEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(j.dayOfWeek,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                        'Ruh hali: ${j.mood.name}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            j.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: const TextStyle(fontSize: 12, color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(MentisInsight insight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trend göstergesi
        _buildTrendIndicator(insight),
        const SizedBox(height: 16),

        // Mentis Score Card
        _buildMentisScoreCard(insight),
        const SizedBox(height: 16),

        // Intensity göstergesi
        _buildIntensityCard(insight),
        const SizedBox(height: 16),

        // Risk Card
        _buildRiskCard(insight),
        const SizedBox(height: 16),

        // Sentiment Card
        _buildSentimentCard(insight),
        const SizedBox(height: 16),

        // Duygu Kategorileri
        if (insight.topWords.isNotEmpty) ...[
          _buildKeywordsCard(insight),
          const SizedBox(height: 16),
        ],

        // Terapist Önerileri
        _buildRecommendationsCard(insight),
      ],
    );
  }

  Widget _buildTrendIndicator(MentisInsight insight) {
    final trendIcon = insight.moodTrend == 'improving'
        ? '📈'
        : (insight.moodTrend == 'declining'
            ? '📉'
            : '➡️');

    final trendLabel = insight.moodTrend == 'improving'
        ? 'İyileşme Trendi'
        : (insight.moodTrend == 'declining'
            ? 'Kötüleşme Trendi'
            : 'Stabil');

    final trendColor = insight.moodTrend == 'improving'
        ? Colors.green
        : (insight.moodTrend == 'declining'
            ? AppColors.danger
            : Colors.blue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: trendColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(trendIcon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ruh Hali Trendi',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                Text(trendLabel,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: trendColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityCard(MentisInsight insight) {
    // Intensity 0-10 şiddet seviyesi
    final intensityLabel = insight.intensity > 7
        ? 'Yüksek Şiddet'
        : (insight.intensity > 4
            ? 'Orta Şiddet'
            : 'Düşük Şiddet');

    final intensityColor = insight.intensity > 7
        ? AppColors.danger
        : (insight.intensity > 4
            ? AppColors.warning
            : Colors.green);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: intensityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: intensityColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: AppColors.secondary),
              const SizedBox(width: 8),
              const Text('Emotional Intensity',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              Text('${insight.intensity}/10',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: intensityColor)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: insight.intensity / 10,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(intensityColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(intensityLabel,
              style: TextStyle(
                  fontSize: 12,
                  color: intensityColor,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMentisScoreCard(MentisInsight insight) {
    final score = insight.mentisScore;
    final color = score >= 70
        ? AppColors.success
        : (score >= 50
            ? AppColors.warning
            : AppColors.danger);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: AppColors.secondary),
              const SizedBox(width: 8),
              const Text('Mentis Score',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              Text('$score/100',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            score >= 70
                ? '✓ Mental sağlık iyi'
                : (score >= 50
                    ? '⚠️ Dikkat gerekebilir'
                    : '⚠️ Profesyonel destek önerilir'),
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCard(MentisInsight insight) {
    final colors = {
      'critical': AppColors.danger,
      'high': Color(0xFFFF9800),
      'moderate': AppColors.warning,
      'low': AppColors.success,
    };
    final color = colors[insight.risk.level] ?? AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: color),
              const SizedBox(width: 8),
              const Text('Risk Seviyesi',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(insight.risk.level.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ],
          ),
          if (insight.risk.triggers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: insight.risk.triggers
                  .take(3)
                  .map((t) => Chip(
                        label: Text(t,
                            style: const TextStyle(fontSize: 11)),
                        backgroundColor: color.withValues(alpha: 0.2),
                        side: BorderSide(color: color.withValues(alpha: 0.3)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSentimentCard(MentisInsight insight) {
    final sentiment = insight.sentiment;
    final label = sentiment.overallLabel;
    final score = sentiment.overallScore;

    final icon = label == 'positive'
        ? '😊'
        : (label == 'negative'
            ? '😟'
            : '😐');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Duygu Durumu',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(label.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Text('${(score * 100).toInt()}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16))
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordsCard(MentisInsight insight) {
    // Duygu kategorileri için emoji ve label haritası
    final emotionEmojis = {
      'stress': '⚠️',
      'anxiety': '😰',
      'depression': '😢',
      'social': '👥',
      'sleep': '😴',
      'happiness': '😊',
    };

    final emotionLabels = {
      'stress': 'Stres',
      'anxiety': 'Anksiyete',
      'depression': 'Depresyon',
      'social': 'Sosyal',
      'sleep': 'Uyku',
      'happiness': 'Mutluluk',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tag_rounded, color: Colors.purple),
              SizedBox(width: 8),
              Text('Duygu Kategorileri',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: insight.topWords
                .map((kw) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.purple.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emotionEmojis[kw.word] ?? '🏷️',
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            '${emotionLabels[kw.word] ?? kw.word}: ${kw.count}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(MentisInsight insight) {
    final message = insight.recommendation.message;
    final recommendations = message.split(' • ').where((r) => r.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Mentis Önerileri',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          ...recommendations
              .asMap()
              .entries
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${e.key + 1}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(e.value,
                              style: const TextStyle(fontSize: 12, height: 1.4)),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }
}
