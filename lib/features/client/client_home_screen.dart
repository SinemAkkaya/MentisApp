import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils_tr.dart';
import '../../models/journal_entry.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'appointment_screen.dart';
import 'journal_screen.dart';
import 'session_links_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key, required this.user});
  final UserModel user;

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  static const _motivations = [
    'Bugün kendine karşı nazik olmayı seç.',
    'Küçük adımlar da gerçek ilerlemedir.',
    'Hisleriniz geçerli; onları yargılamadan gözlemleyin.',
    'Nefes al. Bu an, geçici.',
    'İyileşmek doğrusal bir yol değildir, ama mümkündür.',
    'Bugünkü sen, dünküne minnettar olmalı.',
    'Duygularını bastırmak yerine onları adlandır.',
  ];

  late final String _motivation;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    final dayIndex = DateTime.now().day % _motivations.length;
    _motivation = _motivations[dayIndex];
    // Backend'den danışanın günlüklerini çek (en son entry kartı için)
    _api.fetchJournals().catchError((_) => <JournalEntry>[]);
  }

  void _logout() {
    _api.logout();
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 600));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildMotivationCard(),
              const SizedBox(height: 22),
              const Text(
                'Ne yapmak istersin?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              _buildMenuGrid(),
              const SizedBox(height: 26),
              const Text(
                'Son Günlüğüm',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _buildLastJournal(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Merhaba, ${widget.user.name} 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DayUtils.humanDate(DateTime.now()),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _AvatarButton(
          initial: widget.user.name.isNotEmpty
              ? widget.user.name[0].toUpperCase()
              : '?',
          onTap: _logout,
        ),
      ],
    );
  }

  Widget _buildMotivationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white24,
            child: Icon(Icons.format_quote_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Günün Sözü',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _motivation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15.5,
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

  Widget _buildMenuGrid() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.92,
      children: [
        _MenuCard(
          title: 'Günlüğüm',
          icon: Icons.menu_book_rounded,
          color: AppColors.primary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => JournalScreen(user: widget.user),
            ),
          ),
        ),
        _MenuCard(
          title: 'Randevu Al',
          icon: Icons.event_available_rounded,
          color: AppColors.secondary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AppointmentScreen(user: widget.user),
            ),
          ),
        ),
        _MenuCard(
          title: 'Bağlantılar',
          icon: Icons.link_rounded,
          color: const Color(0xFF8366FF),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SessionLinksScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLastJournal() {
    return ValueListenableBuilder<List<JournalEntry>>(
      valueListenable: _api.journalsNotifier,
      builder: (context, all, _) {
        final entries =
            all.where((j) => j.clientId == widget.user.id).toList();
        if (entries.isEmpty) {
          return _emptyCard(
            icon: Icons.edit_note_rounded,
            title: 'İlk günlüğünü yazmayı dene',
            subtitle: 'Bugün kendini nasıl hissediyorsun?',
          );
        }
        final latest = entries.first;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppTheme.subtleShadow(),
            border: Border.all(color: const Color(0xFFEDEBF7)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(latest.mood.emoji,
                    style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          latest.dayOfWeek,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${DayUtils.humanDate(latest.date)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      latest.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDEBF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
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

class _MenuCard extends StatefulWidget {
  const _MenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.subtleShadow(),
            border: Border.all(color: const Color(0xFFEDEBF7)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: widget.color),
              ),
              const SizedBox(height: 10),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.initial, required this.onTap});
  final String initial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _LogoutSheet(onLogout: onTap),
        );
      },
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.subtleShadow(),
        ),
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E2F2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 18),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
            title: const Text(
              'Çıkış Yap',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
        ],
      ),
    );
  }
}

// Hot-path: random import'u ileri gelişme için referans.
// ignore: unused_element
final _r = Random();
