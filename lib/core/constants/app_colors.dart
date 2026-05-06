import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan sabit renkler.
/// Palet: Soft Mor - Mint Yeşil - Krem Beyaz.
class AppColors {
  AppColors._();

  // Ana palet
  static const Color primary = Color(0xFF5B4FCF);
  static const Color primaryLight = Color(0xFF8A7FF0);
  static const Color primaryDark = Color(0xFF3F34A8);

  static const Color secondary = Color(0xFF00897B);
  static const Color secondaryLight = Color(0xFF4DB6AC);
  static const Color secondaryDark = Color(0xFF00695C);

  static const Color background = Color(0xFFFAF9FF);
  static const Color surface = Colors.white;
  static const Color card = Color(0xFFFFFFFF);

  // Metin
  static const Color textPrimary = Color(0xFF1C1B2E);
  static const Color textSecondary = Color(0xFF6B6A7D);
  static const Color textMuted = Color(0xFFA8A6B8);

  // Durum renkleri
  static const Color success = Color(0xFF2E7D57);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFE04D5A);
  static const Color info = Color(0xFF4F9DFB);

  // Mood renkleri (günlük)
  static const Color moodHappy = Color(0xFFFFB84D);
  static const Color moodGreat = Color(0xFFFF80AB);
  static const Color moodNormal = Color(0xFF90A4AE);
  static const Color moodSad = Color(0xFF5C6BC0);
  static const Color moodAnxious = Color(0xFFAB47BC);
  static const Color moodAngry = Color(0xFFEF5350);

  // Yardımcı gradyanlar
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B4FCF), Color(0xFF8A7FF0)],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
  );

  static const LinearGradient calmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEDEAFF), Color(0xFFDDF5F1)],
  );
}
