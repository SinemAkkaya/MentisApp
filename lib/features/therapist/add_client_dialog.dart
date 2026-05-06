import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/api_service.dart';

class AddClientDialog extends StatefulWidget {
  const AddClientDialog({super.key});

  @override
  State<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController();
  late final _usernameCtrl = TextEditingController();
  late final _passwordCtrl = TextEditingController();
  bool _obscurePwd = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
      contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_add_alt_rounded,
                color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Yeni Danışan',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'En az 2 karakter' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameCtrl,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı adı',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                  helperText: 'Boşluk olmasın, küçük harf önerilir',
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.length < 3) return 'En az 3 karakter';
                  if (t.contains(' ')) return 'Boşluk içeremez';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (ctx, setSt) => TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePwd,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePwd
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded),
                      onPressed: () =>
                          setSt(() => _obscurePwd = !_obscurePwd),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 4) ? 'En az 4 karakter' : null,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.info),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu bilgileri danışanına ileterek uygulamaya giriş yapabilmesini sağla.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            try {
              await ApiService().addClient(
                name: _nameCtrl.text.trim(),
                username: _usernameCtrl.text.trim(),
                password: _passwordCtrl.text,
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                content: Text(e.toString()),
              ));
              return;
            }
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              margin: const EdgeInsets.all(16),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        '${_nameCtrl.text.trim()} eklendi — kullanıcı adı: ${_usernameCtrl.text.trim()}'),
                  ),
                ],
              ),
            ));
          },
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Oluştur'),
        ),
      ],
    );
  }
}
