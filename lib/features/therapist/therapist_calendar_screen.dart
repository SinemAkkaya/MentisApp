import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils_tr.dart';
import '../../models/appointment.dart';
import '../../services/api_service.dart';

class TherapistCalendarScreen extends StatefulWidget {
  const TherapistCalendarScreen({super.key});

  @override
  State<TherapistCalendarScreen> createState() =>
      _TherapistCalendarScreenState();
}

class _TherapistCalendarScreenState extends State<TherapistCalendarScreen> {
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _api.fetchAppointments().catchError((_) => <Appointment>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haftalık Takvim'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text(
              'Pazartesi - Cuma arası randevular',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ...DayUtils.workWeek.map((d) => _buildDaySection(d)),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySection(String day) {
    return ValueListenableBuilder<List<Appointment>>(
      valueListenable: _api.appointmentsNotifier,
      builder: (context, all, _) {
        final list = all.where((a) => a.dayOfWeek == day).toList()
          ..sort((a, b) => a.timeSlot.compareTo(b.timeSlot));
        final isEmpty = list.isEmpty;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEmpty
                  ? const Color(0xFFEDEBF7)
                  : AppColors.primary.withValues(alpha: 0.3),
              width: isEmpty ? 1 : 1.5,
            ),
            boxShadow: AppTheme.subtleShadow(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isEmpty
                            ? const Color(0xFFF0EFF6)
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: isEmpty ? AppColors.textMuted : Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isEmpty
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            isEmpty
                                ? 'Boş gün'
                                : '${list.length} randevu',
                            style: TextStyle(
                              fontSize: 12,
                              color: isEmpty
                                  ? AppColors.textMuted
                                  : AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${list.length}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                if (!isEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  ...list.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AppointmentTile(appointment: a),
                      )),
                ] else ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Icon(Icons.coffee_rounded,
                          color: AppColors.textMuted, size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Bu gün için randevun yok, biraz nefeslen ☕',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AppointmentTile extends StatefulWidget {
  const _AppointmentTile({required this.appointment});
  final Appointment appointment;

  @override
  State<_AppointmentTile> createState() => _AppointmentTileState();
}

class _AppointmentTileState extends State<_AppointmentTile>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _animating = false;

  late final AnimationController _confirmCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _animating = true);
    _confirmCtrl.forward(from: 0);
    await _api.confirmAppointment(widget.appointment.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${widget.appointment.clientName} - ${widget.appointment.timeSlot} onaylandı',
                ),
              ),
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
    final a = widget.appointment;
    final confirmed = a.confirmed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: confirmed
            ? AppColors.success.withValues(alpha: 0.08)
            : const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(14),
        border: confirmed
            ? Border.all(color: AppColors.success.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: confirmed ? AppColors.success : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  a.timeSlot,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            a.clientName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (confirmed) ...[
                          const SizedBox(width: 6),
                          ScaleTransition(
                            scale: CurvedAnimation(
                              parent: _animating
                                  ? _confirmCtrl
                                  : const AlwaysStoppedAnimation(1),
                              curve: Curves.elasticOut,
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: AppColors.success,
                              size: 18,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (a.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        a.note,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ] else
                      const Text(
                        'Not bırakılmamış',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (confirmed)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Randevu onaylandı',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                onPressed: _confirm,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Randevuyu Onayla'),
              ),
            ),
        ],
      ),
    );
  }
}
