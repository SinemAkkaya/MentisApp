import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../client/client_home_screen.dart';
import '../therapist/therapist_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const _therapistPassword = 'terapist123';

  final ApiService _api = ApiService();

  UserRole? _selectedRole;
  // Terapist için isim, danışan için kullanıcı adı.
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _passwordError;
  String? _usernameError;

  late final AnimationController _logoCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  Color get _primary => _selectedRole == UserRole.therapist
      ? AppColors.secondary
      : AppColors.primary;

  Future<void> _handleSubmit() async {
    if (_selectedRole == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _passwordError = null;
      _usernameError = null;
      _submitting = true;
    });

    try {
      UserModel user;
      if (_selectedRole == UserRole.therapist) {
        if (_passwordController.text.trim() != _therapistPassword) {
          setState(() {
            _passwordError = 'Şifre hatalı. İpucu: terapist123';
            _submitting = false;
          });
          return;
        }
        user = await _api.therapistLogin(
          _nameController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        try {
          user = await _api.clientLogin(
            _usernameController.text.trim(),
            _passwordController.text,
          );
        } on ApiException catch (e) {
          setState(() {
            if (e.statusCode == 401 || e.statusCode == 404) {
              _usernameError = 'Hesap bulunamadı';
              _passwordError = 'Kullanıcı adı veya şifre hatalı';
            } else {
              _passwordError = e.message;
            }
            _submitting = false;
          });
          return;
        }
      }

      if (!mounted) return;
      _goToHome(user);
    } on ApiException catch (e) {
      setState(() {
        _passwordError = e.message;
        _submitting = false;
      });
    } catch (e) {
      setState(() {
        _passwordError = 'Sunucuya ulaşılamadı: ${e.toString().split('\n').first}';
        _submitting = false;
      });
    }
  }

  void _goToHome(UserModel user) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, __, ___) => user.isTherapist
            ? TherapistHomeScreen(user: user)
            : ClientHomeScreen(user: user),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF1EEFF),
              Color(0xFFFAF9FF),
              Color(0xFFE4F5F1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: media.size.height -
                    media.padding.top -
                    media.padding.bottom -
                    48,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 36),
                    _buildRoleCards(),
                    const SizedBox(height: 28),
                    _buildFormSection(),
                    const Spacer(),
                    _buildSubmitButton(),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        _selectedRole == UserRole.client
                            ? 'Danışan hesabını terapistinden alabilirsin'
                            : 'Terapist girişi için şifre gereklidir',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _logoCtrl,
            curve: Curves.elasticOut,
          ),
          child: Hero(
            tag: 'app-logo',
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(26),
                boxShadow: AppTheme.softShadow(),
              ),
              child: const Icon(
                Icons.spa_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Mentis',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sakinliğe açılan köprünüz',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCards() {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            title: 'Danışan',
            subtitle: 'Günlük yaz, randevu al',
            icon: Icons.favorite_rounded,
            color: AppColors.primary,
            gradient: AppColors.primaryGradient,
            selected: _selectedRole == UserRole.client,
            onTap: () => setState(() {
              _selectedRole = UserRole.client;
              _passwordController.clear();
              _passwordError = null;
              _usernameError = null;
            }),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _RoleCard(
            title: 'Terapist',
            subtitle: 'Danışanları takip et',
            icon: Icons.psychology_alt_rounded,
            color: AppColors.secondary,
            gradient: AppColors.secondaryGradient,
            selected: _selectedRole == UserRole.therapist,
            onTap: () => setState(() {
              _selectedRole = UserRole.therapist;
              _passwordError = null;
              _usernameError = null;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    final isVisible = _selectedRole != null;
    final isClient = _selectedRole == UserRole.client;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(top: 4),
      padding: EdgeInsets.all(isVisible ? 20 : 0),
      decoration: BoxDecoration(
        color: isVisible ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isVisible ? AppTheme.subtleShadow() : const [],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: !isVisible
            ? const SizedBox(height: 0, width: double.infinity)
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isClient ? 'Danışan Girişi' : 'Terapist Girişi',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (isClient) ...[
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Kullanıcı adı',
                          prefixIcon: const Icon(Icons.alternate_email_rounded),
                          errorText: _usernameError,
                        ),
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Kullanıcı adı zorunludur';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          errorText: _passwordError,
                        ),
                        textInputAction: TextInputAction.done,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Şifre zorunludur';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'İsminiz',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().length < 2) {
                            return 'Lütfen isminizi girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Terapist Şifresi',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          errorText: _passwordError,
                        ),
                        textInputAction: TextInputAction.done,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Şifre zorunludur';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final enabled = _selectedRole != null && !_submitting;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      height: 56,
      decoration: BoxDecoration(
        gradient: _selectedRole == UserRole.therapist
            ? AppColors.secondaryGradient
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                )
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? _handleSubmit : null,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    _selectedRole == null
                        ? 'Önce rolünüzü seçin'
                        : 'Giriş Yap',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      transform: selected
          ? Matrix4.diagonal3Values(1.03, 1.03, 1.0)
          : Matrix4.identity(),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: selected ? gradient : null,
        color: selected ? null : Colors.white,
        border: Border.all(
          color: selected ? Colors.transparent : const Color(0xFFE4E2F2),
          width: 1.2,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.32),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ]
            : AppTheme.subtleShadow(),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white24
                        : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: selected ? Colors.white : color,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
