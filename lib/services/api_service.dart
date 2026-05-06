import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/appointment.dart';
import '../models/client_account.dart';
import '../models/journal_entry.dart';
import '../models/user_model.dart';

/// Mentis Backend ile iletişim katmanı.
/// - Tüm REST çağrıları buradan yapılır.
/// - JWT token SharedPreferences'ta saklanır.
/// - Veri değişiklikleri ValueNotifier ile UI'a yayınlanır.
class ApiService {
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  // ────────────────────────────────────────────────────────────
  //  KONFİGÜRASYON — Backend base URL
  //  - macOS:   localhost (uygulama backend ile aynı makinada)
  //  - iOS:     Mac'in WiFi IP adresi (telefon aynı ağda olmalı)
  //  - Android: 10.0.2.2 (emulator) veya Mac IP (gerçek cihaz)
  //  Production'da Render/Railway URL'i ile değiştirilir.
  // ────────────────────────────────────────────────────────────
  // ⚠️ Mac'in WiFi IP'si — ev/kampüs/cafe değişince burayı güncelle.
  // Kontrol için: terminalde `ipconfig getifaddr en0`
  // 🔥 iPhone hotspot: 172.20.10.3 (sunum günü kullanacağız!)
  static const String _macHostIp = '172.20.10.3';

  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    // Tüm native platformlar için Mac'in WiFi IP'si.
    // (macOS sandbox 127.0.0.1 bağlantısını engelliyor; LAN IP çalışıyor.)
    return 'http://$_macHostIp:3000';
  }

  static const String _tokenKey = 'mentis_token_v1';
  static const String _userKey = 'mentis_user_v1';

  // Reactive notifier'lar — ekranlar bunlara subscribe olur.
  final ValueNotifier<List<JournalEntry>> journalsNotifier =
      ValueNotifier<List<JournalEntry>>(<JournalEntry>[]);
  final ValueNotifier<List<Appointment>> appointmentsNotifier =
      ValueNotifier<List<Appointment>>(<Appointment>[]);
  final ValueNotifier<List<ClientAccount>> clientsNotifier =
      ValueNotifier<List<ClientAccount>>(<ClientAccount>[]);

  String? _token;
  UserModel? _currentUser;

  String get baseUrl => _baseUrl;
  bool get isLoggedIn => _token != null && _currentUser != null;
  UserModel? get currentUser => _currentUser;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        _currentUser = UserModel.fromMap(jsonDecode(userJson));
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  Future<void> _persistAuth(UserModel user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
    _token = token;
    _currentUser = user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _token = null;
    _currentUser = null;
    journalsNotifier.value = <JournalEntry>[];
    appointmentsNotifier.value = <Appointment>[];
    clientsNotifier.value = <ClientAccount>[];
  }

  // ────────────────────────────────────────────────────────────
  //  HTTP CORE
  // ────────────────────────────────────────────────────────────

  Map<String, String> _headers({bool auth = true, bool json = true}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    if (auth && _token != null) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final r = await http
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return _handle(r);
  }

  Future<dynamic> _get(String path, {bool auth = true}) async {
    final r = await http
        .get(
          Uri.parse('$_baseUrl$path'),
          headers: _headers(auth: auth, json: false),
        )
        .timeout(const Duration(seconds: 15));
    return _handle(r);
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final r = await http
        .patch(
          Uri.parse('$_baseUrl$path'),
          headers: _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return _handle(r);
  }

  Future<dynamic> _delete(String path, {bool auth = true}) async {
    final r = await http
        .delete(
          Uri.parse('$_baseUrl$path'),
          headers: _headers(auth: auth, json: false),
        )
        .timeout(const Duration(seconds: 15));
    return _handle(r);
  }

  dynamic _handle(http.Response r) {
    if (r.statusCode == 204) return null;
    final body = r.body.isEmpty ? null : jsonDecode(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return body;
    }
    final msg = (body is Map && body['message'] is String)
        ? body['message']
        : 'Sunucu hatası (${r.statusCode})';
    throw ApiException(r.statusCode, msg);
  }

  // ────────────────────────────────────────────────────────────
  //  AUTH
  // ────────────────────────────────────────────────────────────

  Future<UserModel> therapistLogin(String name, String password) async {
    final res = await _post('/auth/therapist/login', {
      'name': name,
      'password': password,
    }, auth: false) as Map<String, dynamic>;

    final token = res['token'] as String;
    final u = res['user'] as Map<String, dynamic>;
    final user = UserModel(
      id: u['id'] as String,
      name: u['name'] as String,
      role: UserRole.therapist,
    );
    await _persistAuth(user, token);
    return user;
  }

  Future<UserModel> clientLogin(String username, String password) async {
    final res = await _post('/auth/client/login', {
      'username': username,
      'password': password,
    }, auth: false) as Map<String, dynamic>;

    final token = res['token'] as String;
    final u = res['user'] as Map<String, dynamic>;
    final user = UserModel(
      id: u['id'] as String,
      name: u['name'] as String,
      role: UserRole.client,
    );
    await _persistAuth(user, token);
    return user;
  }

  // ────────────────────────────────────────────────────────────
  //  CLIENTS (terapist)
  // ────────────────────────────────────────────────────────────

  Future<List<ClientAccount>> fetchClients() async {
    final res = await _get('/clients') as List<dynamic>;
    final list = res
        .whereType<Map<String, dynamic>>()
        .map((m) => ClientAccount(
              id: m['id'] as String,
              username: m['username'] as String,
              password: '',
              name: m['name'] as String,
              createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
                  DateTime.now(),
            ))
        .toList();
    clientsNotifier.value = list;
    return list;
  }

  Future<ClientAccount> addClient({
    required String name,
    required String username,
    required String password,
  }) async {
    final res = await _post('/clients', {
      'name': name,
      'username': username,
      'password': password,
    }) as Map<String, dynamic>;
    await fetchClients();
    return ClientAccount(
      id: res['id'] as String,
      username: res['username'] as String,
      password: '',
      name: res['name'] as String,
      createdAt: DateTime.tryParse(res['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Future<void> removeClient(String id) async {
    await _delete('/clients/$id');
    await fetchClients();
  }

  // ────────────────────────────────────────────────────────────
  //  JOURNALS
  // ────────────────────────────────────────────────────────────

  Future<List<JournalEntry>> fetchJournals({
    String? clientId,
    int limit = 50,
  }) async {
    final qs = <String>[];
    if (clientId != null) qs.add('clientId=$clientId');
    qs.add('limit=$limit');
    final url = '/journals?${qs.join('&')}';
    final res = await _get(url) as List<dynamic>;
    final list = res
        .whereType<Map<String, dynamic>>()
        .map(_journalFromApi)
        .toList();
    journalsNotifier.value = list;
    return list;
  }

  JournalEntry _journalFromApi(Map<String, dynamic> m) {
    final clientName = (m['client'] is Map)
        ? ((m['client'] as Map)['name']?.toString() ?? '')
        : (m['clientName']?.toString() ?? '');
    return JournalEntry(
      id: m['id']?.toString() ?? '',
      clientId: m['clientId']?.toString() ?? '',
      clientName: clientName,
      content: m['content']?.toString() ?? '',
      mood: MoodTypeExt.fromKey(m['mood']?.toString()),
      dayOfWeek: m['dayOfWeek']?.toString() ?? '',
      date: DateTime.tryParse(m['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Future<JournalEntry> addJournal({
    required String content,
    required MoodType mood,
    required String dayOfWeek,
    required DateTime date,
  }) async {
    final res = await _post('/journals', {
      'content': content,
      'mood': mood.key,
      'dayOfWeek': dayOfWeek,
      'date': date.toIso8601String(),
    }) as Map<String, dynamic>;
    await fetchJournals();
    return _journalFromApi(res);
  }

  // ────────────────────────────────────────────────────────────
  //  APPOINTMENTS
  // ────────────────────────────────────────────────────────────

  Future<List<Appointment>> fetchAppointments({String? dayOfWeek}) async {
    final url = dayOfWeek != null
        ? '/appointments?dayOfWeek=$dayOfWeek'
        : '/appointments';
    final res = await _get(url) as List<dynamic>;
    final list = res
        .whereType<Map<String, dynamic>>()
        .map(_appointmentFromApi)
        .toList();
    appointmentsNotifier.value = list;
    return list;
  }

  Appointment _appointmentFromApi(Map<String, dynamic> m) {
    final clientName = (m['client'] is Map)
        ? ((m['client'] as Map)['name']?.toString() ?? '')
        : (m['clientName']?.toString() ?? '');
    return Appointment(
      id: m['id']?.toString() ?? '',
      clientId: m['clientId']?.toString() ?? '',
      clientName: clientName,
      timeSlot: m['timeSlot']?.toString() ?? '',
      dayOfWeek: m['dayOfWeek']?.toString() ?? '',
      note: m['note']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
      confirmed: m['confirmed'] == true,
    );
  }

  Future<Appointment> addAppointment({
    required String timeSlot,
    required String dayOfWeek,
    required String note,
  }) async {
    final res = await _post('/appointments', {
      'timeSlot': timeSlot,
      'dayOfWeek': dayOfWeek,
      'note': note,
    }) as Map<String, dynamic>;
    await fetchAppointments();
    return _appointmentFromApi(res);
  }

  Future<void> confirmAppointment(String id) async {
    await _patch('/appointments/$id/confirm', {});
    await fetchAppointments();
  }

  // Yardımcılar — uygulama içinde kullanılan basit sorgular.
  bool isSlotTaken(String dayOfWeek, String timeSlot) {
    return appointmentsNotifier.value.any(
      (a) => a.dayOfWeek == dayOfWeek && a.timeSlot == timeSlot,
    );
  }

  // ────────────────────────────────────────────────────────────
  //  MENTIS INSIGHT
  // ────────────────────────────────────────────────────────────

  Future<MentisInsight> generateInsight({String? clientId, int limit = 5}) async {
    final body = <String, dynamic>{'limit': limit};
    if (clientId != null) body['clientId'] = clientId;
    final res = await _post('/insight', body) as Map<String, dynamic>;
    return MentisInsight.fromJson(res);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ────────────────────────────────────────────────────────────
//  Mentis Insight model
// ────────────────────────────────────────────────────────────

class MentisInsight {
  final String clientName;
  final int mentisScore;
  final SentimentSummary sentiment;
  final RiskSummary risk;
  final List<TopWord> topWords;
  final Recommendation recommendation;
  final int analyzedCount;
  final bool hasData;

  MentisInsight({
    required this.clientName,
    required this.mentisScore,
    required this.sentiment,
    required this.risk,
    required this.topWords,
    required this.recommendation,
    required this.analyzedCount,
    required this.hasData,
  });

  factory MentisInsight.fromJson(Map<String, dynamic> m) {
    final tw = (m['topWords'] as List<dynamic>? ?? []);
    return MentisInsight(
      clientName: m['clientName']?.toString() ?? '',
      mentisScore: (m['mentisScore'] as num?)?.toInt() ?? 50,
      sentiment: SentimentSummary.fromJson(
          (m['sentiment'] as Map<String, dynamic>?) ?? const {}),
      risk:
          RiskSummary.fromJson((m['risk'] as Map<String, dynamic>?) ?? const {}),
      topWords: tw
          .whereType<Map<String, dynamic>>()
          .map((x) => TopWord(
                word: x['word']?.toString() ?? '',
                count: (x['count'] as num?)?.toInt() ?? 0,
              ))
          .toList(),
      recommendation: Recommendation.fromJson(
          (m['recommendation'] as Map<String, dynamic>?) ?? const {}),
      analyzedCount: (m['analyzedCount'] as num?)?.toInt() ?? 0,
      hasData: m['hasData'] == true,
    );
  }
}

class SentimentSummary {
  final double overallScore; // -2..+2
  final String overallLabel; // "neutral" | "positive" | ...
  final Map<String, int> histogram;

  SentimentSummary({
    required this.overallScore,
    required this.overallLabel,
    required this.histogram,
  });

  factory SentimentSummary.fromJson(Map<String, dynamic> m) {
    final h = (m['histogram'] as Map<String, dynamic>? ?? const {});
    return SentimentSummary(
      overallScore: (m['overallScore'] as num?)?.toDouble() ?? 0,
      overallLabel: m['overallLabel']?.toString() ?? 'neutral',
      histogram: h.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }
}

class RiskSummary {
  final int score; // 0..100
  final String level; // "low" | "moderate" | "high" | "critical"
  final List<String> triggers;

  RiskSummary({
    required this.score,
    required this.level,
    required this.triggers,
  });

  factory RiskSummary.fromJson(Map<String, dynamic> m) {
    final tr = (m['triggers'] as List<dynamic>? ?? []);
    return RiskSummary(
      score: (m['score'] as num?)?.toInt() ?? 0,
      level: m['level']?.toString() ?? 'low',
      triggers: tr.map((e) => e.toString()).toList(),
    );
  }
}

class TopWord {
  final String word;
  final int count;
  TopWord({required this.word, required this.count});
}

class Recommendation {
  final String title;
  final String tone; // "neutral" | "positive" | "moderate" | "high" | "critical"
  final String message;

  Recommendation({
    required this.title,
    required this.tone,
    required this.message,
  });

  factory Recommendation.fromJson(Map<String, dynamic> m) {
    return Recommendation(
      title: m['title']?.toString() ?? '',
      tone: m['tone']?.toString() ?? 'neutral',
      message: m['message']?.toString() ?? '',
    );
  }
}
