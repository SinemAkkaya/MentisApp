import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/client_account.dart';
import '../../services/api_service.dart';

/// Mentis Insight ekranı.
/// Terapist bir danışan veya tüm danışanlar için backend'in
/// `POST /insight` endpoint'ini çağırır. Sonuç:
///   - Mentis Score (0-100)
///   - Sentiment summary
///   - Risk summary + tetikleyiciler
///   - En sık kullanılan kelimeler (stop-word filtreli)
///   - Otomatik tavsiye metni
class AiSummaryScreen extends StatefulWidget {
  const AiSummaryScreen({super.key});

  @override
  State<AiSummaryScreen> createState() => _AiSummaryScreenState();
}

class _AiSummaryScreenState extends State<AiSummaryScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();

  bool _loading = false;
  String? _error;
  MentisInsight? _insight;

  String? _selectedClientId;
  String _selectedClientName = 'Tüm danışanlar';

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _api.fetchClients().catchError((_) => <ClientAccount>[]);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
      _insight = null;
    });
    try {
      final res = await _api.generateInsight(
        clientId: _selectedClientId,
        limit: 10,
      );
      if (!mounted) return;
      setState(() => _insight = res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mentis Insight')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _buildIntro(),
            const SizedBox(height: 18),
            _buildClientDropdown(),
            const SizedBox(height: 14),
            _buildGenerateButton(),
            const SizedBox(height: 22),
            if (_loading) _buildLoading(),
            if (_error != null) _buildError(_error!),
            if (_insight != null) _buildInsightCard(_insight!),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.secondaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow:
            AppTheme.softShadow(AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white24,
            child: Icon(Icons.insights_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Mentis Insight: Danışan günlüklerini kendi yazdığımız Türkçe '
              'NLP motorumuzla analiz eder. Sentiment, risk, sık kullanılan '
              'kelimeler ve Mentis Score üretir.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEDEBF7)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedClientId,
              hint: Row(
                children: const [
                  Icon(Icons.people_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text('Tüm danışanlar'),
                ],
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.people_rounded, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Tüm danışanlar'),
                    ],
                  ),
                ),
                ...clients.map(
                  (c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          child: Text(
                            c.name.isNotEmpty
                                ? c.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(c.name),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  _selectedClientId = v;
                  _selectedClientName = v == null
                      ? 'Tüm danışanlar'
                      : clients
                          .firstWhere(
                            (c) => c.id == v,
                            orElse: () => ClientAccount(
                              id: v,
                              username: '',
                              password: '',
                              name: 'Bilinmeyen',
                              createdAt: DateTime.now(),
                            ),
                          )
                          .name;
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
        onPressed: _loading ? null : _generate,
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.auto_fix_high_rounded),
        label: Text(_loading ? 'Analiz ediliyor...' : 'Mentis Insight Oluştur'),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDEBF7)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 80,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => CustomPaint(
                painter: _PulseWavePainter(progress: _pulseCtrl.value),
                size: const Size(240, 80),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Sözlükler taranıyor, skor hesaplanıyor...',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Mentis NLP motoru çalışıyor.',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildError(String err) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(err, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  INSIGHT KARTI
  // ────────────────────────────────────────────────────────────

  Widget _buildInsightCard(MentisInsight ins) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow(
            AppColors.secondary.withValues(alpha: 0.16)),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.insights_rounded,
                    color: AppColors.secondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mentis Insight Raporu',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                      '$_selectedClientName • ${ins.analyzedCount} günlük',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MentisScoreBlock(score: ins.mentisScore),
          const SizedBox(height: 16),
          _RecommendationBanner(rec: ins.recommendation),
          const SizedBox(height: 14),
          if (ins.risk.score > 0) _RiskBlock(risk: ins.risk),
          if (ins.risk.score > 0) const SizedBox(height: 14),
          _SentimentBlock(sent: ins.sentiment),
          const SizedBox(height: 14),
          _TopWordsBlock(words: ins.topWords),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.shield_rounded, size: 14, color: AppColors.textMuted),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Mentis Insight motoru tamamen ekibimizin yazdığı Türkçe '
                  'sözlük tabanlı analiz sistemiyle çalışır. Klinik karar '
                  'yerine geçmez.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────

class _MentisScoreBlock extends StatelessWidget {
  const _MentisScoreBlock({required this.score});
  final int score;

  Color _color() {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.secondary;
    if (score >= 25) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    final pct = score / 100;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.withValues(alpha: 0.18), c.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 8,
                    backgroundColor: c.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(c),
                  ),
                ),
                Text(
                  '$score',
                  style: TextStyle(
                    color: c,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Mentis Score',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                SizedBox(height: 4),
                Text(
                  '0-100 ölçeğinde danışanın genel ruh hali endeksi. '
                  '100\'e yaklaştıkça iyi olma hali artar.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
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
}

class _RecommendationBanner extends StatelessWidget {
  const _RecommendationBanner({required this.rec});
  final Recommendation rec;

  Color _color() {
    switch (rec.tone) {
      case 'critical':
        return AppColors.danger;
      case 'high':
        return const Color(0xFFE65100);
      case 'moderate':
        return AppColors.warning;
      case 'positive':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  IconData _icon() {
    switch (rec.tone) {
      case 'critical':
        return Icons.warning_rounded;
      case 'high':
        return Icons.priority_high_rounded;
      case 'moderate':
        return Icons.info_rounded;
      case 'positive':
        return Icons.check_circle_rounded;
      default:
        return Icons.lightbulb_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon(), color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  rec.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
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
}

class _RiskBlock extends StatelessWidget {
  const _RiskBlock({required this.risk});
  final RiskSummary risk;

  Color _color() {
    switch (risk.level) {
      case 'critical':
        return AppColors.danger;
      case 'high':
        return const Color(0xFFE65100);
      case 'moderate':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  String _levelLabel() {
    switch (risk.level) {
      case 'critical':
        return 'ACİL';
      case 'high':
        return 'Yüksek';
      case 'moderate':
        return 'Orta';
      default:
        return 'Düşük';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.shield_rounded, size: 18, color: c),
          const SizedBox(width: 8),
          Text('Risk: ${_levelLabel()}  •  ${risk.score}/100',
              style: TextStyle(
                  color: c, fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
        if (risk.triggers.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: risk.triggers
                .take(8)
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: c.withValues(alpha: 0.30)),
                      ),
                      child: Text(t,
                          style: TextStyle(
                              color: c,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _SentimentBlock extends StatelessWidget {
  const _SentimentBlock({required this.sent});
  final SentimentSummary sent;

  static const labels = {
    'very_negative': 'Çok Olumsuz',
    'negative': 'Olumsuz',
    'neutral': 'Nötr',
    'positive': 'Olumlu',
    'very_positive': 'Çok Olumlu',
  };
  static const emojis = {
    'very_negative': '😢',
    'negative': '😔',
    'neutral': '😐',
    'positive': '🙂',
    'very_positive': '🥰',
  };

  Color _colorFor(String l) {
    switch (l) {
      case 'very_negative':
        return AppColors.danger;
      case 'negative':
        return AppColors.warning;
      case 'positive':
        return AppColors.secondary;
      case 'very_positive':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colorFor(sent.overallLabel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: const [
          Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Duygu Eğilimi',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withValues(alpha: 0.30)),
          ),
          child: Row(
            children: [
              Text(emojis[sent.overallLabel] ?? '😐',
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Genel: ${labels[sent.overallLabel] ?? sent.overallLabel}',
                      style: TextStyle(
                          color: c,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5),
                    ),
                    Text(
                      'Skor: ${sent.overallScore.toStringAsFixed(2)} (-2..+2)',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: sent.histogram.entries.where((e) => e.value > 0).map((e) {
            final color = _colorFor(e.key);
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.30)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emojis[e.key] ?? '',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text('${labels[e.key] ?? e.key}: ${e.value}',
                      style: TextStyle(
                          color: color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TopWordsBlock extends StatelessWidget {
  const _TopWordsBlock({required this.words});
  final List<TopWord> words;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const SizedBox.shrink();
    final maxCount = words.map((w) => w.count).reduce(max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: const [
          Icon(Icons.translate_rounded, size: 18, color: AppColors.primary),
          SizedBox(width: 8),
          Text('En Sık Kullanılan Kelimeler',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: words.map((w) {
            final relative = (w.count / maxCount).clamp(0.3, 1.0);
            final size = 12.0 + relative * 6;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withValues(alpha: 0.05 + relative * 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.30)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    w.word,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: size,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${w.count}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PulseWavePainter extends CustomPainter {
  _PulseWavePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    for (int i = 0; i < 3; i++) {
      final phase = (progress + i * 0.25) % 1.0;
      paint.color = AppColors.secondary.withValues(alpha: 1.0 - phase);
      final radius = 16 + phase * 70;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        radius,
        paint,
      );
    }
    final centerPaint = Paint()..color = AppColors.secondary;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      14 + sin(progress * 2 * pi) * 2,
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PulseWavePainter old) =>
      old.progress != progress;
}
