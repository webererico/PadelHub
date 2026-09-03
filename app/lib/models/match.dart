enum MatchFormat { amistosa, torneio, americano }

enum MatchStatus { pendingConfirmation, confirmed, disputed }

class SetScore {
  const SetScore({required this.teamA, required this.teamB});

  factory SetScore.fromJson(Map<String, dynamic> json) => SetScore(
        teamA: json['teamA'] as int,
        teamB: json['teamB'] as int,
      );

  final int teamA;
  final int teamB;

  bool get teamAWonSet => teamA > teamB;
}

class MatchPlayer {
  const MatchPlayer({required this.id, required this.name, this.photoUrl});

  final String id;
  final String name;
  final String? photoUrl;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class PadelMatch {
  const PadelMatch({
    required this.id,
    required this.format,
    required this.status,
    required this.teamA,
    required this.teamB,
    required this.sets,
    required this.playedAt,
    this.arenaName,
    this.ratingDelta,
    this.kudosCount = 0,
    this.commentCount = 0,
    this.highlight,
  });

  factory PadelMatch.fromJson(Map<String, dynamic> json) => PadelMatch(
        id: json['id'] as String,
        format: MatchFormat.values.byName(json['format'] as String),
        status: MatchStatus.values.byName(json['status'] as String),
        teamA: (json['teamA'] as List)
            .map((p) => MatchPlayer(id: p['id'] as String, name: p['name'] as String, photoUrl: p['photoUrl'] as String?))
            .toList(),
        teamB: (json['teamB'] as List)
            .map((p) => MatchPlayer(id: p['id'] as String, name: p['name'] as String, photoUrl: p['photoUrl'] as String?))
            .toList(),
        sets: (json['sets'] as List).map((s) => SetScore.fromJson(s as Map<String, dynamic>)).toList(),
        playedAt: DateTime.parse(json['playedAt'] as String),
        arenaName: json['arenaName'] as String?,
        ratingDelta: json['ratingDelta'] as int?,
        kudosCount: json['kudosCount'] as int? ?? 0,
        commentCount: json['commentCount'] as int? ?? 0,
        highlight: json['highlight'] as String?,
      );

  final String id;
  final MatchFormat format;
  final MatchStatus status;
  final List<MatchPlayer> teamA;
  final List<MatchPlayer> teamB;
  final List<SetScore> sets;
  final DateTime playedAt;
  final String? arenaName;
  final int? ratingDelta;
  final int kudosCount;
  final int commentCount;
  final String? highlight;

  int get setsWonByTeamA => sets.where((s) => s.teamAWonSet).length;
  int get setsWonByTeamB => sets.length - setsWonByTeamA;
  bool get teamAWonMatch => setsWonByTeamA > setsWonByTeamB;
}
