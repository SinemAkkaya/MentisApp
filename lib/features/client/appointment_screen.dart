import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils_tr.dart';
import '../../models/appointment.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key, required this.user});
  final UserModel user;

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  static const _slots = [
    '09:00',
    '10:00',
    '11:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00'
  ];

  final ApiService _api = ApiService();
  final TextEditingController _noteCtrl = TextEditingController();
  late final TextEditingController _nameCtrl;
  String? _day;
  String? _slot;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    // Slot grid'inin "dolu/boş" görünmesi için randevuları çek
    _api.fetchAppointments().catchError((_) => <Appointment>[]);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_day == null) return _snack('Bir gün seç', AppColors.warning);
    if (_slot == null) return _snack('Bir saat seç', AppColors.warning);
    if (_nameCtrl.text.trim().isEmpty) {
      return _snack('İsim boş olamaz', AppColors.warning);
    }

    // Çift rezervasyon kontrolü
    if (_api.isSlotTaken(_day!, _slot!)) {
      return _snack('Bu saat artık dolu, başka bir saat seç', AppColors.warning);
    }

    setState(() => _saving = true);
    try {
      final appointment = await _api.addAppointment(
        timeSlot: _slot!,
        dayOfWeek: _day!,
        note: _noteCtrl.text.trim(),
      );
      if (!mounted) return;

      // Önce snackbar göster, sonra geri dön
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Randevun oluşturuldu — ${appointment.dayOfWeek}, ${appointment.timeSlot}',
                  ),
                ),
              ],
            ),
          ),
        );
      // Snackbar'ı gösterdikten sonra ekrandan çık
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _snack('Kayıt başarısız: $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _saving = false);
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
      appBar: AppBar(
        title: const Text('Randevu Al'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text(
              'Gün seçin',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildDayRow(),
            const SizedBox(height: 24),
            const Text(
              'Uygun saatler',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildSlotGrid(),
            const SizedBox(height: 24),
            _buildNameField(),
            const SizedBox(height: 12),
            _buildNoteField(),
            const SizedBox(height: 22),
            _buildSubmit(),
          ],
        ),
      ),
    );
  }

  Widget _buildDayRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DayUtils.workWeek.map((d) {
          final selected = d == _day;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() {
                _day = d;
                _slot = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.primaryGradient : null,
                  color: selected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : const Color(0xFFEDEBF7),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 8))
                        ]
                      : AppTheme.subtleShadow(),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: selected ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      d,
                      style: TextStyle(
                        color:
                            selected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSlotGrid() {
    return ValueListenableBuilder<List<Appointment>>(
      valueListenable: _api.appointmentsNotifier,
      builder: (context, all, _) {
        final taken = _day == null
            ? <String>{}
            : all
                .where((a) => a.dayOfWeek == _day)
                .map((a) => a.timeSlot)
                .toSet();
        return GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: _slots.map((s) {
            final selected = _slot == s;
            final dayUnselected = _day == null;
            final isTaken = taken.contains(s);
            final disabled = dayUnselected || isTaken;

            final Color bgColor;
            final Color fgColor;
            final Color borderColor;
            if (selected) {
              bgColor = AppColors.primary;
              fgColor = Colors.white;
              borderColor = AppColors.primary;
            } else if (isTaken) {
              bgColor = const Color(0xFFF1EFF7);
              fgColor = AppColors.textMuted;
              borderColor = const Color(0xFFE1DEEC);
            } else {
              bgColor = Colors.white;
              fgColor = AppColors.textPrimary;
              borderColor = const Color(0xFFEDEBF7);
            }

            return AnimatedOpacity(
              opacity: dayUnselected ? 0.45 : 1,
              duration: const Duration(milliseconds: 220),
              child: GestureDetector(
                onTap: disabled
                    ? () {
                        if (isTaken) {
                          _snack('Bu saat zaten dolu', AppColors.warning);
                        }
                      }
                    : () => setState(() => _slot = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.20),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isTaken && !selected)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.lock_rounded,
                              size: 12, color: fgColor),
                        ),
                      Text(
                        s,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: fgColor,
                          decoration: isTaken && !selected
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameCtrl,
      decoration: const InputDecoration(
        labelText: 'İsminiz',
        prefixIcon: Icon(Icons.person_rounded),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextField(
      controller: _noteCtrl,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Terapiste not (opsiyonel)',
        hintText: 'Görüşme öncesi belirtmek istediğin bir şey var mı?',
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 40),
          child: Icon(Icons.note_alt_rounded),
        ),
      ),
    );
  }

  Widget _buildSubmit() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _saving ? null : _submit,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.check_circle_rounded),
        label: Text(_saving ? 'Kaydediliyor...' : 'Randevumu Onayla'),
      ),
    );
  }
}
