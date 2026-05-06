import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/client_account.dart';
import '../../services/api_service.dart';

/// Terapist video seans bağlantısı gönderme diyaloğu
/// Terapist kendi linkini (https://zoom.us/j/... vb) yapıştırır
class SendSessionLinkDialog extends StatefulWidget {
  const SendSessionLinkDialog({
    super.key,
    required this.clientId,
    required this.clientName,
    this.isPickClient = false,
  });

  final String clientId;
  final String clientName;
  final bool isPickClient; // true ise danışan seçme ekranı göster

  @override
  State<SendSessionLinkDialog> createState() => _SendSessionLinkDialogState();
}

class _SendSessionLinkDialogState extends State<SendSessionLinkDialog> {
  late final TextEditingController _linkController;
  late final TextEditingController _titleController;
  String? _selectedPlatform; // 'google-meet' or 'zoom'
  bool _sending = false;
  String? _error;
  String? _selectedClientId;
  List<ClientAccount> _clients = [];
  bool _loadingClients = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _linkController = TextEditingController();
    _titleController = TextEditingController();
    if (widget.isPickClient) {
      _loadClients();
    } else {
      _selectedClientId = widget.clientId;
    }
  }

  Future<void> _loadClients() async {
    setState(() => _loadingClients = true);
    try {
      final clients = await _apiService.fetchClients();
      if (mounted) {
        setState(() {
          _clients = clients;
          _selectedClientId = clients.isNotEmpty ? clients.first.id : null;
          _loadingClients = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Danışanlar yüklenemedi: $e';
          _loadingClients = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _linkController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      contentPadding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.video_call_rounded,
                    color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Video Seans Bağlantısı Gönder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        widget.isPickClient
                            ? 'Danışan seç'
                            : widget.clientName,
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
            const SizedBox(height: 20),

            // Danışan seçimi (isPickClient ise)
            if (widget.isPickClient) ...[
              const Text(
                'Danışan Seç',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              if (_loadingClients)
                const Center(child: CircularProgressIndicator())
              else if (_clients.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Danışan bulunamadı',
                    style: TextStyle(color: AppColors.danger),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedClientId,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFEDEBF7)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFEDEBF7)),
                    ),
                  ),
                  items: _clients
                      .map((client) => DropdownMenuItem(
                            value: client.id,
                            child: Text(client.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedClientId = value);
                    }
                  },
                ),
              const SizedBox(height: 16),
            ],

            // Platform seçimi
            const Text(
              'Platform',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            _buildPlatformOption('google-meet', 'Google Meet',
              const Color(0xFF00897B), Icons.video_call_rounded),
            const SizedBox(height: 10),
            _buildPlatformOption('zoom', 'Zoom',
              const Color(0xFF2D8CFF), Icons.video_chat_rounded),

            const SizedBox(height: 20),

            // Başlık
            const Text(
              'Başlık (İsteğe Bağlı)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'ör: Haftalık Seans',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFEDEBF7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFEDEBF7)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bağlantı URL'si
            const Text(
              'Video Bağlantısı',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _linkController,
              decoration: InputDecoration(
                hintText: 'https://zoom.us/j/123456789?pwd=...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFEDEBF7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFEDEBF7)),
                ),
                suffixIcon: _linkController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.content_paste_rounded,
                          color: AppColors.primary),
                        onPressed: _pasteFromClipboard,
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            // Hata mesajı
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Düğmeler
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _sending ? null : () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedPlatform == null ||
                            _linkController.text.isEmpty ||
                            _sending
                        ? null
                        : _sendLink,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_sending ? 'Gönderiliyor...' : 'Gönder'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformOption(
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    final isSelected = _selectedPlatform == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlatform = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : const Color(0xFFEDEBF7),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null && clipboardData.text != null) {
      _linkController.text = clipboardData.text!;
      setState(() {});
    }
  }

  Future<void> _sendLink() async {
    if (_selectedPlatform == null ||
        _linkController.text.isEmpty ||
        _selectedClientId == null) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final response = await _apiService.post(
        '/session-links',
        {
          'clientId': _selectedClientId,
          'platform': _selectedPlatform,
          'title': _titleController.text.isNotEmpty
              ? _titleController.text
              : '$_selectedPlatform Video Seansı',
          'link': _linkController.text,
        },
      );

      if (!mounted) return;

      // İlk dialog'ı kapat
      if (mounted) Navigator.pop(context, response);

      // Sonra snackbar göster (parent context'te)
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
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
                    Icon(Icons.check_circle_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bağlantı başarıyla gönderildi!',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Bağlantı gönderilemedi: $e';
        _sending = false;
      });
    }
  }
}
