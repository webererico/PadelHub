class MatchComment {
  const MatchComment({required this.id, required this.userId, required this.userName, required this.body, required this.createdAt});

  factory MatchComment.fromJson(Map<String, dynamic> json) => MatchComment(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final String userId;
  final String userName;
  final String body;
  final DateTime createdAt;

  String get initials {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
