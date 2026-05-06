/// Uygulamadaki iki rol: danışan ve terapist.
enum UserRole { client, therapist }

/// Oturum açmış kullanıcıyı temsil eder.
class UserModel {
  final String id;
  final String name;
  final UserRole role;

  const UserModel({
    required this.id,
    required this.name,
    required this.role,
  });

  bool get isTherapist => role == UserRole.therapist;
  bool get isClient => role == UserRole.client;

  /// Terapistler için "Dr." önekli görüntü adı.
  String get displayName => isTherapist ? 'Dr. $name' : name;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'role': role.name,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      role: (map['role'] == 'therapist')
          ? UserRole.therapist
          : UserRole.client,
    );
  }

  UserModel copyWith({String? id, String? name, UserRole? role}) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }
}
