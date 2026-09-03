class Arena {
  const Arena({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.courtCount,
    required this.activePlayerCount,
  });

  factory Arena.fromJson(Map<String, dynamic> json) => Arena(
        id: json['id'] as String,
        name: json['name'] as String,
        city: json['city'] as String,
        state: json['state'] as String,
        courtCount: json['courtCount'] as int,
        activePlayerCount: json['activePlayerCount'] as int,
      );

  final String id;
  final String name;
  final String city;
  final String state;
  final int courtCount;
  final int activePlayerCount;
}

class LiveMatch {
  const LiveMatch({
    required this.courtLabel,
    required this.startedAt,
    required this.teamA,
    required this.teamB,
    required this.scoreLabel,
  });

  final String courtLabel;
  final DateTime startedAt;
  final String teamA;
  final String teamB;
  final String scoreLabel;
}
