import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils_tr.dart';
import '../../models/journal_entry.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key, required this.user});
  final UserModel user;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ApiService _api = ApiService();

  late DateTime _selectedDay;
  MoodType? _selectedMood;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    // İlk açılışta backend'den geçmiş günlükleri yükle
    _api.fetchJournals().catchError((_) => <JournalEntry>[]);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  List<DateTime> get _weekDays {
    final now = DateTime.now();
    // Haftanın pazartesine hizala
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(
        7, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  Future<void> _save() async {
    if (_selectedMood == null) {
      _snack('Lütfen bir ruh hali seç', AppColors.warning);
      return;
    }
    if (_textCtrl.text.trim().isEmpty) {
      _snack('Günlük metni boş olamaz', AppColors.warning);
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.addJournal(
        content: _textCtrl.text.trim(),
        mood: _selectedMood!,
        dayOfWeek: DayUtils.fromDate(_selectedDay),
        date: _selectedDay,
      );

      // KRİTİK: Veritabanı işlemi bitince sayfa hala açık mı kontrol et
      if (!mounted) return;

      _textCtrl.clear();
      setState(() => _selectedMood = null);
      _snack('Günlüğün kaydedildi ✨', AppColors.success);
    } catch (e) {
      // KRİTİK: Hata mesajı (snack) göstermeden önce context kontrolü
      if (!mounted) return;
      _snack('Kayıt başarısız: $e', AppColors.danger);
    } finally {
      // GARANTİ DURDURMA: İşlem bitse de hata da verse yükleme durumu kesin kapanacak
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          content: Row(
            children: [
              Icon(
                color == AppColors.success
                    ? Icons.check_circle_rounded
                    : (color == AppColors.warning
                        ? Icons.warning_amber_rounded
                        : Icons.error_rounded),
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(msg)),
            ],
          ),
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlüğüm'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _buildWeekStrip(),
            const SizedBox(height: 20),
            _buildMoodPicker(),
            const SizedBox(height: 20),
            _buildTextField(),
            const SizedBox(height: 14),
            _buildSaveButton(),
            const SizedBox(height: 26),
            Row(
              children: [
                const Text(
                  'Geçmiş Günlüklerim',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                const Icon(Icons.history_rounded,
                    color: AppColors.textSecondary, size: 18),
              ],
            ),
            const SizedBox(height: 12),
            _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekStrip() {
    final days = _weekDays;
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final d = days[i];
          final isSelected = d.day == _selectedDay.day &&
              d.month == _selectedDay.month &&
              d.year == _selectedDay.year;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 62,
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      isSelected ? Colors.transparent : const Color(0xFFEDEBF7),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DayUtils.short[d.weekday - 1],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodPicker() {
    const moods = MoodType.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bugün kendini nasıl hissediyorsun?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: moods.map((m) {
              final selected = _selectedMood == m;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMood = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    width: selected ? 86 : 72,
                    height: selected ? 102 : 90,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFFEDEBF7),
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.18),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              )
                            ]
                          : AppTheme.subtleShadow(),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: TextStyle(fontSize: selected ? 34 : 26),
                          child: Text(m.emoji),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.subtleShadow(),
        border: Border.all(color: const Color(0xFFEDEBF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aklından ne geçiyor?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textCtrl,
            maxLines: 6,
            minLines: 4,
            maxLength: 600,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText:
                  'Bugün yaşadıklarını, hissettiklerini veya fark ettiğin küçük şeyleri yazabilirsin...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              counterText: '',
              filled: false,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_textCtrl.text.length}/600',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.save_alt_rounded),
        label: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
      ),
    );
  }

  Widget _buildHistoryList() {
    return ValueListenableBuilder<List<JournalEntry>>(
      valueListenable: _api.journalsNotifier,
      builder: (context, all, _) {
        final entries =
            all.where((j) => j.clientId == widget.user.id).toList();
        if (entries.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEDEBF7)),
            ),
            child: Column(
              children: [
                const Text('📖', style: TextStyle(fontSize: 38)),
                const SizedBox(height: 8),
                const Text(
                  'Henüz bir günlüğün yok',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'İlk satırı yaz ve bu yolculuğu başlat.',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return Column(
          children: entries
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HistoryCard(entry: e),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEBF7)),
        boxShadow: AppTheme.subtleShadow(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(entry.mood.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.dayOfWeek,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${DayUtils.humanDate(entry.date)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
