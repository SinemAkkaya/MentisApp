/// Randevu modeli (cihaz belleğinde "appointments" listesi).
class Appointment {
  final String id;
  final String clientId;
  final String clientName;
  final String timeSlot; // "10:00"
  final String dayOfWeek; // "Pazartesi"
  final String note;
  final DateTime createdAt;
  final bool confirmed;

  const Appointment({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.timeSlot,
    required this.dayOfWeek,
    required this.note,
    required this.createdAt,
    this.confirmed = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientId': clientId,
        'clientName': clientName,
        'timeSlot': timeSlot,
        'dayOfWeek': dayOfWeek,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'confirmed': confirmed,
      };

  factory Appointment.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawDate = map['createdAt'];
    DateTime parsed;
    if (rawDate is String) {
      parsed = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsed = DateTime.now();
    }

    return Appointment(
      id: (map['id'] ?? docId ?? '').toString(),
      clientId: (map['clientId'] ?? '').toString(),
      clientName: (map['clientName'] ?? '').toString(),
      timeSlot: (map['timeSlot'] ?? '').toString(),
      dayOfWeek: (map['dayOfWeek'] ?? '').toString(),
      note: (map['note'] ?? '').toString(),
      createdAt: parsed,
      confirmed: map['confirmed'] == true,
    );
  }

  Appointment copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? timeSlot,
    String? dayOfWeek,
    String? note,
    DateTime? createdAt,
    bool? confirmed,
  }) {
    return Appointment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      timeSlot: timeSlot ?? this.timeSlot,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      confirmed: confirmed ?? this.confirmed,
    );
  }
}
