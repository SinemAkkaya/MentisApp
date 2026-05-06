/// Haftanın günlerini ve Türkçe biçimlendirmeyi tek bir yerden yönetir.
class DayUtils {
  DayUtils._();

  /// Hafta içi iş günleri — terapist takvimi ve danışan randevu ekranında ortak.
  static const List<String> workWeek = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
  ];

  static const List<String> allWeek = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  static const List<String> short = [
    'Pzt',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
    'Paz',
  ];

  /// `DateTime.weekday` 1 (Pzt) … 7 (Paz) — dizi indekslemek için.
  static String fromDate(DateTime d) => allWeek[d.weekday - 1];
  static String shortFromDate(DateTime d) => short[d.weekday - 1];

  static String todayName() => fromDate(DateTime.now());
  static String todayShort() => shortFromDate(DateTime.now());

  /// "24 Nisan 2026" biçiminde.
  static String humanDate(DateTime d) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
