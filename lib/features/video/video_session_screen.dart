import 'dart:async';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/face_detection_service.dart';

/// Video Seans ekranı — gerçek ön kamera + karşı taraf simülasyonu.
///
/// Roller:
///  - SessionRole.client    → "Terapist bekleniyor..."
///  - SessionRole.therapist → "Danışan bekleniyor..."
///
/// Notlar:
///  - permission_handler KULLANILMIYOR; camera paketi kendi izni alır.
///  - ML Kit yüz tespiti EKLENMEDİ (build çakışmasını önlemek için);
///    bunun yerine "Bağlantı: Canlı / Kapalı" göstergesi var.
///  - AnimatedSwitcher + ValueKey YASAK — sadece AnimatedContainer.
class VideoSessionScreen extends StatefulWidget {
  const VideoSessionScreen({
    super.key,
    this.role = SessionRole.client,
  });

  final SessionRole role;

  @override
  State<VideoSessionScreen> createState() => _VideoSessionScreenState();
}

enum SessionRole { client, therapist }

class _VideoSessionScreenState extends State<VideoSessionScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _camera;
  final FaceDetectionService _faceService = FaceDetectionService();
  bool _starting = false;
  bool _inSession = false;
  String? _startupError;

  // Durum
  bool _muted = false;
  bool _cameraOff = false;
  int _faceCount = 0; // ML Kit'ten gelen gerçek yüz sayısı

  // Zamanlayıcı
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  DateTime? _startedAt;

  // Karşı taraf "yazıyor / bağlanıyor" pulse
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final AnimationController _avatarPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  String get _otherSideName =>
      widget.role == SessionRole.therapist ? 'Danışanın' : 'Terapistin';
  String get _otherSideWaitingMsg =>
      widget.role == SessionRole.therapist
          ? 'Danışan bekleniyor...'
          : 'Terapist bekleniyor...';
  String get _otherSideHint =>
      widget.role == SessionRole.therapist
          ? 'Danışan seansa katıldığında görüntüsü burada belirir'
          : 'Terapistin seansa katıldığında görüntüsü burada belirir';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pulseCtrl.dispose();
    _avatarPulse.dispose();
    // Camera image stream + camera kapat
    try {
      if (_camera?.value.isStreamingImages == true) {
        _camera?.stopImageStream();
      }
    } catch (_) {}
    _camera?.dispose();
    _faceService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopSession(popAfter: false);
    }
  }

  Future<void> _startSession() async {
    setState(() {
      _starting = true;
      _startupError = null;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Cihazda kamera bulunamadı.');
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _camera = controller;

      // GERÇEK YÜZ TESPİTİ — frame stream başlat
      try {
        await controller.startImageStream(_onCameraImage);
      } catch (_) {
        // Image stream başlatılamazsa sorun değil, sadece yüz sayısı 0 kalır.
      }

      _startedAt = DateTime.now();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _elapsed = DateTime.now().difference(_startedAt!);
        });
      });

      HapticFeedback.lightImpact();
      setState(() {
        _inSession = true;
        _starting = false;
      });
    } catch (e) {
      try {
        await _camera?.dispose();
      } catch (_) {}
      _camera = null;
      if (!mounted) return;
      setState(() {
        _starting = false;
        _startupError = 'Kamera başlatılamadı: $e';
      });
    }
  }

  Future<void> _stopSession({bool popAfter = true}) async {
    _timer?.cancel();
    _timer = null;
    try {
      if (_camera?.value.isStreamingImages == true) {
        await _camera?.stopImageStream();
      }
    } catch (_) {}
    try {
      await _camera?.dispose();
    } catch (_) {}
    _camera = null;
    if (!mounted) return;
    setState(() {
      _inSession = false;
      _elapsed = Duration.zero;
      _faceCount = 0;
    });
    if (popAfter && mounted) Navigator.of(context).pop();
  }

  /// Kameradan gelen her frame için ML Kit'e ileriler.
  /// Throttle FaceDetectionService içinde yapılıyor (busy flag).
  Future<void> _onCameraImage(CameraImage image) async {
    final cam = _camera;
    if (cam == null) return;
    final result = await _faceService.processCameraImage(
      image: image,
      sensorOrientation: cam.description.sensorOrientation,
      lensDirection: cam.description.lensDirection,
    );
    if (result == null) return;
    if (!mounted) return;
    if (result.faceCount != _faceCount) {
      setState(() => _faceCount = result.faceCount);
    }
  }

  String _fmtTime(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: _inSession ? _buildInSession() : _buildPreSession(),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  PRE-SESSION
  // ────────────────────────────────────────────────────────────
  Widget _buildPreSession() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1B2E), Color(0xFF2F2A58)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Video Seans',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: AnimatedBuilder(
                  animation: _avatarPulse,
                  builder: (_, child) {
                    final v = _avatarPulse.value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 160 + v * 16,
                          height: 160 + v * 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary
                                .withValues(alpha: 0.15 * (1 - v)),
                          ),
                        ),
                        Container(
                          width: 130,
                          height: 130,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.35),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.videocam_rounded,
                              color: Colors.white, size: 58),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
              Text(
                widget.role == SessionRole.therapist
                    ? 'Danışanınla seansa hazır mısın?'
                    : 'Terapistinle seansa hazır mısın?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.role == SessionRole.therapist
                    ? 'Seansa katıldığında ön kameran açılır. '
                        'Danışan bağlandığında görüntüsü ekrana gelir.'
                    : 'Seansa katıldığında ön kameran açılır. '
                        'Terapistin bağlandığında görüntüsü ekrana gelir.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              if (_startupError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    _startupError!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _starting ? null : _startSession,
                  icon: _starting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 26),
                  label: Text(
                    _starting ? 'Kamera açılıyor...' : 'Seansa Katıl',
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  IN-SESSION
  // ────────────────────────────────────────────────────────────
  Widget _buildInSession() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Büyük alan: KARŞI TARAF (bekleniyor durumu)
        _buildOtherSideArea(),

        // Üst bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _buildLiveBadge(),
                  const SizedBox(width: 10),
                  _buildTimerBadge(),
                  const Spacer(),
                  _buildConnectionBadge(),
                ],
              ),
            ),
          ),
        ),

        // Sağ üstte küçük PIP: KENDİ KAMERAN
        Positioned(
          right: 14,
          top: 78,
          child: _buildSelfPip(),
        ),

        // Alt bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildWaitingBanner(),
                  const SizedBox(height: 14),
                  _buildControls(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Karşı tarafın görüntüsünün ekranı — kamera kapalı + bekleniyor.
  Widget _buildOtherSideArea() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final v = _pulseCtrl.value; // 0..1
        return Stack(
          fit: StackFit.expand,
          children: [
            // Yumuşak gradient arkaplan
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF24223A), Color(0xFF3B3478)],
                ),
              ),
            ),
            // Pulse halkası
            Center(
              child: Container(
                width: 180 + v * 40,
                height: 180 + v * 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06 * (1 - v)),
                ),
              ),
            ),
            // Avatar + bekleniyor mesajı
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.secondaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.videocam_off_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _otherSideName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _otherSideWaitingMsg,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Sağ üstteki küçük PIP: kullanıcının kendi kamerası.
  Widget _buildSelfPip() {
    final cam = _camera;
    final w = 110.0;
    final h = 150.0;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF111017),
        border: Border.all(color: Colors.white24, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cam != null && cam.value.isInitialized && !_cameraOff)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: cam.value.previewSize?.height ?? 1,
                  height: cam.value.previewSize?.width ?? 1,
                  child: CameraPreview(cam),
                ),
              )
            else
              const Center(
                child: Icon(
                  Icons.videocam_off_rounded,
                  size: 36,
                  color: Colors.white38,
                ),
              ),
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Sen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.circle, color: Colors.white, size: 10),
          SizedBox(width: 6),
          Text(
            'CANLI',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _fmtTime(_elapsed),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  /// Üst sağ rozet — ML Kit'ten gelen GERÇEK yüz sayısı.
  Widget _buildConnectionBadge() {
    final cameraReady =
        !_cameraOff && _camera?.value.isInitialized == true;
    final detected = cameraReady && _faceCount > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: detected
            ? AppColors.success.withValues(alpha: 0.92)
            : Colors.white24,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            detected ? Icons.face_rounded : Icons.face_retouching_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Yüz: $_faceCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingBanner() {
    // Üç durum:
    //  - kamera kapalı  → "kamerayı aç" mesajı (white)
    //  - kamera açık + yüz yok  → "kameraya geri dön" (kırmızı)
    //  - kamera açık + yüz var  → karşı taraf bekleme mesajı (default)
    final cameraReady =
        !_cameraOff && _camera?.value.isInitialized == true;
    final detected = cameraReady && _faceCount > 0;

    Color bg;
    Color fg;
    IconData icon;
    String text;

    if (!cameraReady) {
      bg = Colors.white.withValues(alpha: 0.10);
      fg = Colors.white70;
      icon = Icons.videocam_off_rounded;
      text = 'Kamera kapalı';
    } else if (!detected) {
      bg = AppColors.danger.withValues(alpha: 0.90);
      fg = Colors.white;
      icon = Icons.warning_amber_rounded;
      text = 'Lütfen kameraya geri dön';
    } else {
      bg = AppColors.success.withValues(alpha: 0.85);
      fg = Colors.white;
      icon = Icons.check_circle_rounded;
      text = 'Yüz algılandı ✓  •  $_otherSideHint';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: AppTheme.softShadow(Colors.black.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ControlButton(
            icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: _muted ? 'Açık değil' : 'Mikrofon',
            active: !_muted,
            onTap: () => setState(() => _muted = !_muted),
          ),
          _ControlButton(
            icon: Icons.call_end_rounded,
            label: 'Seansı Bitir',
            color: AppColors.danger,
            highlight: true,
            onTap: () => _stopSession(popAfter: true),
          ),
          _ControlButton(
            icon: _cameraOff
                ? Icons.videocam_off_rounded
                : Icons.videocam_rounded,
            label: _cameraOff ? 'Kamera kapalı' : 'Kamera',
            active: !_cameraOff,
            onTap: () => setState(() {
              _cameraOff = !_cameraOff;
              if (_cameraOff) _faceCount = 0;
            }),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = true,
    this.color,
    this.highlight = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bg = highlight
        ? (color ?? AppColors.primary)
        : (active ? Colors.white24 : Colors.white12);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
