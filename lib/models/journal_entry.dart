/// Günlük girişindeki ruh hali seçenekleri.
enum MoodType { great, happy, normal, sad, anxious, angry }

extension MoodTypeExt on MoodType {
  String get emoji {
    switch (this) {
      case MoodType.great:
        return '🥰';
      case MoodType.happy:
        return '😊';
      case MoodType.normal:
        return '😐';
      case MoodType.sad:
        return '😔';
      case MoodType.anxious:
        return '😰';
      case MoodType.angry:
        return '😡';
    }
  }

  String get label {
    switch (this) {
      case MoodType.great:
        return 'Harika';
      case MoodType.happy:
        return 'İyi';
      case MoodType.normal:
        return 'Normal';
      case MoodType.sad:
        return 'Üzgün';
      case MoodType.anxious:
        return 'Endişeli';
      case MoodType.angry:
        return 'Sinirli';
    }
  }

  /// Map/JSON için stabil anahtar.
  String get key => name;

  static MoodType fromKey(String? key) {
    return MoodType.values.firstWhere(
      (m) => m.name == key,
      orElse: () => MoodType.normal,
    );
  }
}

/// Tek bir günlük girişi (cihaz belleğinde "journals" listesi).
class JournalEntry {
  final String id;
  final String clientId;
  final String clientName;
  final String content;
  final MoodType mood;
  final String dayOfWeek; // "Pazartesi", "Salı"...
  final DateTime date;

  const JournalEntry({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.content,
    required this.mood,
    required this.dayOfWeek,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientId': clientId,
        'clientName': clientName,
        'content': content,
        'mood': mood.key,
        'dayOfWeek': dayOfWeek,
        'date': date.toIso8601String(),
      };

  factory JournalEntry.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawDate = map['date'];
    DateTime parsed;
    if (rawDate is String) {
      parsed = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsed = DateTime.now();
    }

    return JournalEntry(
      id: (map['id'] ?? docId ?? '').toString(),
      clientId: (map['clientId'] ?? '').toString(),
      clientName: (map['clientName'] ?? '').toString(),
      content: (map['content'] ?? '').toString(),
      mood: MoodTypeExt.fromKey(map['mood']?.toString()),
      dayOfWeek: (map['dayOfWeek'] ?? '').toString(),
      date: parsed,
    );
  }

  JournalEntry copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? content,
    MoodType? mood,
    String? dayOfWeek,
    DateTime? date,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      date: date ?? this.date,
    );
  }
}
