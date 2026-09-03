class LeaderboardEntry {
  const LeaderboardEntry({
    required this.position,
    required this.userId,
    required this.name,
    required this.rating,
    required this.ratingDelta,
    this.clubName,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        position: json['position'] as int,
        userId: json['userId'] as String,
        name: json['name'] as String,
        rating: json['rating'] as int,
        ratingDelta: json['ratingDelta'] as int,
        clubName: json['clubName'] as String?,
      );

  final int position;
  final String userId;
  final String name;
  final int rating;
  final int ratingDelta;
  final String? clubName;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
