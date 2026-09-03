import '../core/network/api_client.dart';
import '../models/leaderboard_entry.dart';

enum RankingScope { global, country, state, city, club, friends }

class RankingService {
  RankingService(this._api);

  final ApiClient _api;

  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required RankingScope scope,
    String? scopeId,
  }) async {
    final json = await _api.get('/ranking', query: {
      'scope': scope.name,
      if (scopeId != null) 'scopeId': scopeId,
    }) as List;
    return json.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}
