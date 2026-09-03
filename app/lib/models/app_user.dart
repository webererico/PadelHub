class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.rating,
    this.photoUrl,
    this.clubId,
    this.clubName,
    this.city,
    this.state,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        rating: json['rating'] as int? ?? 1000,
        photoUrl: json['photoUrl'] as String?,
        clubId: json['clubId'] as String?,
        clubName: json['clubName'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
      );

  final String id;
  final String name;
  final String email;
  final int rating;
  final String? photoUrl;
  final String? clubId;
  final String? clubName;
  final String? city;
  final String? state;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
