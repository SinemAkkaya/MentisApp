/// Video seans bağlantı modeli
class SessionLink {
  final String id;
  final String clientId;
  final String therapistId;
  final String platform; // 'google-meet' | 'zoom'
  final String link;
  final String title;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isRead;
  final int clickCount;

  SessionLink({
    required this.id,
    required this.clientId,
    required this.therapistId,
    required this.platform,
    required this.link,
    required this.title,
    required this.createdAt,
    required this.expiresAt,
    required this.isRead,
    required this.clickCount,
  });

  factory SessionLink.fromJson(Map<String, dynamic> json) {
    return SessionLink(
      id: json['id'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      therapistId: json['therapistId'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      link: json['link'] as String? ?? '',
      title: json['title'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      clickCount: json['clickCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'therapistId': therapistId,
      'platform': platform,
      'link': link,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isRead': isRead,
      'clickCount': clickCount,
    };
  }
}
