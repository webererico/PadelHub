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

  /// Admin-only: lists every arena (not just the viewer's own club).
  Future<List<Arena>> fetchAllArenas() async {
    final json = await _api.get('/arenas') as List;
    return json.map((e) => Arena.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Admin-only: registers a new arena/club.
  Future<Arena> createArena({required String name, required String city, required String state, int courtCount = 1}) async {
    final json = await _api.post('/arenas', body: {
      'name': name,
      'city': city,
      'state': state,
      'courtCount': courtCount,
    });
    return Arena.fromJson(json as Map<String, dynamic>);
  }
}
