import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/session_link.dart';
import '../../services/api_service.dart';

/// Danışan video seans bağlantılarını görüntüler
class SessionLinksScreen extends StatefulWidget {
  const SessionLinksScreen({super.key});

  @override
  State<SessionLinksScreen> createState() => _SessionLinksScreenState();
}

class _SessionLinksScreenState extends State<SessionLinksScreen> {
  late final ApiService _apiService;
  List<SessionLink> _links = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _apiService.get('/session-links');
      if (response is List) {
        final links = response
            .map((e) => SessionLink.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _links = links;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Bağlantılar yüklenemedi: $e';
        _loading = false;
      });
    }
  }

  Future<void> _openLink(SessionLink link) async {
    try {
      // Bağlantı tıklama sayısını artır
      await _apiService.post('/session-links/${link.id}/click', {});

      // macOS: Safari'ye doğrudan aç veya panoya kopyala
      if (Platform.isMacOS) {
        await Clipboard.setData(ClipboardData(text: link.link));

        // Safari'yi açmaya çalış
        try {
          await launchUrl(
            Uri.parse(link.link),
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {
          // Fallback: başarısız olursa snackbar göster
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                backgroundColor: AppColors.warning,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                content: const Row(
                  children: [
                    Icon(Icons.info_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bağlantı panoya kopyalandı. Safari\'yi açıp yapıştır.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            );
        }
      } else {
        // Diğer platformlar (iOS, Android)
        final uri = Uri.parse(link.link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      // Güncellemeleri yükle
      await Future.delayed(const Duration(seconds: 1));
      _loadLinks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _copyLink(SessionLink link) async {
    await Clipboard.setData(ClipboardData(text: link.link));
    if (!mounted) return;
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
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('Bağlantı panoya kopyalandı'),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Seans Bağlantıları'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
                : _links.isEmpty
                    ? _buildEmptyState()
                    : _buildLinksList(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                color: AppColors.danger, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Hata!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLinks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Yeniden Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.video_call_rounded,
                color: AppColors.primary, size: 50),
            ),
            const SizedBox(height: 20),
            Text(
              'Henüz bağlantı yok',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Terapistiniz sana video seans bağlantısı gönderdiğinde burada görünecek',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLinks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Kontrol Et'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksList() {
    return RefreshIndicator(
      onRefresh: _loadLinks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _links.length,
        itemBuilder: (context, i) => _buildLinkCard(_links[i]),
      ),
    );
  }

  Widget _buildLinkCard(SessionLink link) {
    final platformIcon = link.platform == 'google-meet'
        ? Icons.video_call_rounded
        : Icons.video_chat_rounded;
    final platformColor = link.platform == 'google-meet'
        ? const Color(0xFF00897B)
        : const Color(0xFF2D8CFF);
    final platformName = link.platform == 'google-meet'
        ? 'Google Meet'
        : 'Zoom';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEDEBF7)),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: AppTheme.subtleShadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: platformColor.withValues(alpha: 0.08),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: platformColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(platformIcon,
                      color: platformColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          link.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          platformName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bağlantı ve düğmeler
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bağlantı
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F4FB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEDEBF7)),
                    ),
                    child: SelectableText(
                      link.link,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Düğmeler
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: () => _openLink(link),
                            icon: const Icon(Icons.open_in_browser_rounded,
                              size: 16),
                            label: const Text('Aç'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: platformColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: IconButton(
                          onPressed: () => _copyLink(link),
                          icon: const Icon(Icons.copy_rounded,
                            color: AppColors.textSecondary, size: 18),
                          tooltip: 'Kopyala',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
