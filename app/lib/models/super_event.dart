enum EventFormat { super8, super12 }

enum EventStatus { scheduled, inProgress, completed }

extension EventFormatX on EventFormat {
  int get playerCount => this == EventFormat.super8 ? 8 : 12;
  String get label => this == EventFormat.super8 ? 'Super 8' : 'Super 12';
}

class SuperEventPlayer {
  const SuperEventPlayer({required this.id, required this.name});

  factory SuperEventPlayer.fromJson(Map<String, dynamic> json) =>
      SuperEventPlayer(id: json['id'] as String, name: json['name'] as String);

  final String id;
  final String name;
}

class SuperEventRound {
  const SuperEventRound({
    required this.id,
    required this.roundIndex,
    required this.courtNumber,
    required this.teamAPlayerIds,
    required this.teamBPlayerIds,
    required this.teamAPlayerNames,
    required this.teamBPlayerNames,
    this.teamAGames,
    this.teamBGames,
  });

  factory SuperEventRound.fromJson(Map<String, dynamic> json) => SuperEventRound(
        id: json['id'] as String,
        roundIndex: json['roundIndex'] as int,
        courtNumber: json['courtNumber'] as int,
        teamAPlayerIds: (json['teamAPlayerIds'] as List).cast<String>(),
        teamBPlayerIds: (json['teamBPlayerIds'] as List).cast<String>(),
        teamAPlayerNames: (json['teamAPlayerNames'] as List).cast<String>(),
        teamBPlayerNames: (json['teamBPlayerNames'] as List).cast<String>(),
        teamAGames: json['teamAGames'] as int?,
        teamBGames: json['teamBGames'] as int?,
      );

  final String id;
  final int roundIndex;
  final int courtNumber;
  final List<String> teamAPlayerIds;
  final List<String> teamBPlayerIds;
  final List<String> teamAPlayerNames;
  final List<String> teamBPlayerNames;
  final int? teamAGames;
  final int? teamBGames;

  bool get isScored => teamAGames != null && teamBGames != null;
}

class SuperEventStanding {
  const SuperEventStanding({
    required this.userId,
    required this.name,
    required this.gamesWon,
    required this.gamesLost,
    required this.roundsWon,
    required this.roundsPlayed,
  });

  factory SuperEventStanding.fromJson(Map<String, dynamic> json) => SuperEventStanding(
        userId: json['userId'] as String,
        name: json['name'] as String,
        gamesWon: json['gamesWon'] as int,
        gamesLost: json['gamesLost'] as int,
        roundsWon: json['roundsWon'] as int,
        roundsPlayed: json['roundsPlayed'] as int,
      );

  final String userId;
  final String name;
  final int gamesWon;
  final int gamesLost;
  final int roundsWon;
  final int roundsPlayed;

  int get gamesDiff => gamesWon - gamesLost;
}

class SuperEvent {
  const SuperEvent({
    required this.id,
    required this.name,
    required this.format,
    required this.status,
    required this.createdAt,
    required this.players,
    required this.rounds,
    required this.standings,
    this.arenaId,
  });

  factory SuperEvent.fromJson(Map<String, dynamic> json) => SuperEvent(
        id: json['id'] as String,
        name: json['name'] as String,
        format: EventFormat.values.byName(json['format'] == 'super8' ? 'super8' : 'super12'),
        status: _statusFromJson(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        arenaId: json['arenaId'] as String?,
        players: (json['players'] as List).map((p) => SuperEventPlayer.fromJson(p as Map<String, dynamic>)).toList(),
        rounds: (json['rounds'] as List).map((r) => SuperEventRound.fromJson(r as Map<String, dynamic>)).toList(),
        standings: (json['standings'] as List).map((s) => SuperEventStanding.fromJson(s as Map<String, dynamic>)).toList(),
      );

  final String id;
  final String name;
  final EventFormat format;
  final EventStatus status;
  final DateTime createdAt;
  final String? arenaId;
  final List<SuperEventPlayer> players;
  final List<SuperEventRound> rounds;
  final List<SuperEventStanding> standings;

  int get roundCount => rounds.isEmpty ? 0 : rounds.map((r) => r.roundIndex).reduce((a, b) => a > b ? a : b) + 1;

  List<SuperEventRound> roundsAt(int roundIndex) => rounds.where((r) => r.roundIndex == roundIndex).toList();
}

class SuperEventSummary {
  const SuperEventSummary({
    required this.id,
    required this.name,
    required this.format,
    required this.status,
    required this.playerCount,
    required this.createdAt,
  });

  factory SuperEventSummary.fromJson(Map<String, dynamic> json) => SuperEventSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        format: EventFormat.values.byName(json['format'] == 'super8' ? 'super8' : 'super12'),
        status: _statusFromJson(json['status'] as String),
        playerCount: json['playerCount'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final String name;
  final EventFormat format;
  final EventStatus status;
  final int playerCount;
  final DateTime createdAt;
}

EventStatus _statusFromJson(String value) {
  switch (value) {
    case 'in_progress':
      return EventStatus.inProgress;
    case 'completed':
      return EventStatus.completed;
    default:
      return EventStatus.scheduled;
  }
}

extension EventStatusX on EventStatus {
  String get label {
    switch (this) {
      case EventStatus.scheduled:
        return 'Agendado';
      case EventStatus.inProgress:
        return 'Em andamento';
      case EventStatus.completed:
        return 'Concluído';
    }
  }
}
