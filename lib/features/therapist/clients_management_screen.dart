import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils_tr.dart';
import '../../models/client_account.dart';
import '../../services/api_service.dart';
import 'add_client_dialog.dart';

/// Terapistin kendi danışanları için kullanıcı adı + şifre oluşturduğu ekran.
/// Sadece bu listedeki hesaplar danışan girişi yapabilir.
class ClientsManagementScreen extends StatefulWidget {
  const ClientsManagementScreen({super.key});

  @override
  State<ClientsManagementScreen> createState() =>
      _ClientsManagementScreenState();
}

class _ClientsManagementScreenState extends State<ClientsManagementScreen> {
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _api.fetchClients().catchError((_) => <ClientAccount>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danışanlarım'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_rounded, color: Colors.white),
        label: const Text(
          'Yeni Danışan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<ClientAccount>>(
          valueListenable: _api.clientsNotifier,
          builder: (context, clients, _) {
            if (clients.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
              itemCount: clients.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i == 0) return _buildHeader(clients.length);
                final c = clients[i - 1];
                return _ClientCard(
                  account: c,
                  onDelete: () => _confirmDelete(c),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow(
          AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white24,
            child: Icon(Icons.verified_user_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count danışanın var',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Sadece oluşturduğun hesaplar uygulamaya giriş yapabilir.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group_add_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Henüz danışanın yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sağ alttaki "Yeni Danışan" butonuna basıp '
              'danışanına özel bir kullanıcı adı ve şifre oluştur.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => const AddClientDialog(),
    );
  }

  Future<void> _confirmDelete(ClientAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Danışanı sil',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Text(
            '${account.name} adlı danışanın hesabı kaldırılacak. '
            'Bu işlem geri alınamaz.',
            style: const TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.delete_rounded, size: 18),
              label: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await _api.removeClient(account.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text('${account.name} silindi'),
        ),
      );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.account, required this.onDelete});
  final ClientAccount account;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEBF7)),
        boxShadow: AppTheme.subtleShadow(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              account.name.isNotEmpty
                  ? account.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.alternate_email_rounded,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(
                      account.username,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Eklendi • ${DayUtils.humanDate(account.createdAt)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sil',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }
}
