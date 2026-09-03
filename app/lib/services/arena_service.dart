import '../core/network/api_client.dart';
import '../models/arena.dart';
import '../models/leaderboard_entry.dart';

class ArenaService {
  ArenaService(this._api);

  final ApiClient _api;

  Future<Arena> fetchArena(String arenaId) async {
    final json = await _api.get('/arenas/$arenaId');
    return Arena.fromJson(json as Map<String, dynamic>);
  }

  Future<List<LeaderboardEntry>> fetchInternalRanking(String arenaId) async {
    final json = await _api.get('/arenas/$arenaId/ranking') as List;
    return json.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LiveMatch>> fetchLiveMatches(String arenaId) async {
    final json = await _api.get('/arenas/$arenaId/live') as List;
    return json
        .map((e) => LiveMatch(
              courtLabel: (e as Map<String, dynamic>)['courtLabel'] as String,
              startedAt: DateTime.parse(e['startedAt'] as String),
              teamA: e['teamA'] as String,
              teamB: e['teamB'] as String,
              scoreLabel: e['scoreLabel'] as String,
            ))
        .toList();
  }
}
