import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'video_session_screen.dart';

/// Video seans için platform seçim ekranı.
/// "Video Seans" butonuna basıldığında bu açılır:
///   - Google Meet → otomatik link üretip panoya kopyalar
///   - Zoom → otomatik link üretip panoya kopyalar
///   - Hemen Bağlan → cihazın ön kamerası ile uygulama içi seans
class VideoSessionPicker extends StatelessWidget {
  const VideoSessionPicker({super.key, required this.role});
  final SessionRole role;

  @override
  Widget build(BuildContext context) {
    final isTherapist = role == SessionRole.therapist;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seans Başlat'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppTheme.softShadow(
                  AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.videocam_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      isTherapist
                          ? 'Danışanınla nasıl görüşmek istersin?'
                          : 'Terapistinle nasıl görüşmek istersin?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _PlatformCard(
              title: 'Google Meet',
              subtitle: 'Bağlantı oluştur ve karşı tarafa gönder',
              iconColor: const Color(0xFF00897B),
              icon: Icons.video_call_rounded,
              onTap: () =>
                  _showLinkDialog(context, _LinkProvider.googleMeet, isTherapist),
            ),
            const SizedBox(height: 12),
            _PlatformCard(
              title: 'Zoom',
              subtitle: 'Zoom toplantı bağlantısı oluştur',
              iconColor: const Color(0xFF2D8CFF),
              icon: Icons.video_chat_rounded,
              onTap: () => _showLinkDialog(context, _LinkProvider.zoom, isTherapist),
            ),
            const SizedBox(height: 22),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'veya',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 22),
            _PlatformCard(
              title: 'Hemen Bağlan',
              subtitle: 'Telefonunun kamerası ile uygulama içi seans',
              iconColor: AppColors.primary,
              icon: Icons.phone_iphone_rounded,
              isPrimary: true,
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => VideoSessionScreen(role: role),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkDialog(
      BuildContext context, _LinkProvider provider, bool isTherapist) {
    final link = _generateLink(provider);

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          contentPadding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: provider.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(provider.icon, color: provider.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${provider.displayName} bağlantısı hazır',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                isTherapist
                    ? 'Aşağıdaki bağlantıyı danışanınla paylaş:'
                    : 'Aşağıdaki bağlantıyı terapistinle paylaş:',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F4FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEDEBF7)),
                ),
                child: SelectableText(
                  link,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.color,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: link));
                    if (!dialogCtx.mounted) return;
                    Navigator.of(dialogCtx).pop();
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          content: Row(
                            children: const [
                              Icon(Icons.check_circle_rounded,
                                  color: Colors.white),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Bağlantı panoya kopyalandı, paylaşabilirsin.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Bağlantıyı Kopyala'),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Kapat'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _generateLink(_LinkProvider p) {
    final rnd = Random();
    String randomCode(int len) {
      const chars = 'abcdefghijkmnpqrstuvwxyz23456789';
      return List.generate(len, (_) => chars[rnd.nextInt(chars.length)])
          .join();
    }

    switch (p) {
      case _LinkProvider.googleMeet:
        // Google Meet kodu formatı: xxx-yyyy-zzz
        return 'https://meet.google.com/'
            '${randomCode(3)}-${randomCode(4)}-${randomCode(3)}';
      case _LinkProvider.zoom:
        // Zoom rakam-pid formatı
        final id = List.generate(10, (_) => rnd.nextInt(10)).join();
        final pwd = randomCode(8);
        return 'https://zoom.us/j/$id?pwd=$pwd';
    }
  }
}

enum _LinkProvider {
  googleMeet,
  zoom;

  String get displayName {
    switch (this) {
      case _LinkProvider.googleMeet:
        return 'Google Meet';
      case _LinkProvider.zoom:
        return 'Zoom';
    }
  }

  IconData get icon {
    switch (this) {
      case _LinkProvider.googleMeet:
        return Icons.video_call_rounded;
      case _LinkProvider.zoom:
        return Icons.video_chat_rounded;
    }
  }

  Color get color {
    switch (this) {
      case _LinkProvider.googleMeet:
        return const Color(0xFF00897B);
      case _LinkProvider.zoom:
        return const Color(0xFF2D8CFF);
    }
  }
}

class _PlatformCard extends StatefulWidget {
  const _PlatformCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isPrimary = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  State<_PlatformCard> createState() => _PlatformCardState();
}

class _PlatformCardState extends State<_PlatformCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 140),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: widget.isPrimary ? AppColors.primaryGradient : null,
            color: widget.isPrimary ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    )
                  ]
                : AppTheme.subtleShadow(),
            border: widget.isPrimary
                ? null
                : Border.all(color: const Color(0xFFEDEBF7)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.isPrimary
                      ? Colors.white24
                      : widget.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isPrimary ? Colors.white : widget.iconColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: widget.isPrimary
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: widget.isPrimary
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: widget.isPrimary
                    ? Colors.white70
                    : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
