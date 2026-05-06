/// Terapist tarafından oluşturulan danışan hesabı.
/// Login'de kullanıcı adı + şifre ile doğrulanır.
class ClientAccount {
  final String id;
  final String username;
  final String password;
  final String name;
  final DateTime createdAt;

  const ClientAccount({
    required this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'password': password,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ClientAccount.fromMap(Map<String, dynamic> map) {
    final raw = map['createdAt'];
    DateTime parsed;
    if (raw is String) {
      parsed = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      parsed = DateTime.now();
    }
    return ClientAccount(
      id: (map['id'] ?? '').toString(),
      username: (map['username'] ?? '').toString(),
      password: (map['password'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      createdAt: parsed,
    );
  }
}
