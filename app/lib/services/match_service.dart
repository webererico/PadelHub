import '../core/network/api_client.dart';
import '../models/match.dart';

class MatchService {
  MatchService(this._api);

  final ApiClient _api;

  /// Feed de partidas — global ou filtrado por amigos/arena, conforme [scope].
  Future<List<PadelMatch>> fetchFeed({String scope = 'friends'}) async {
    final json = await _api.get('/matches/feed', query: {'scope': scope}) as List;
    return json.map((e) => PadelMatch.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PadelMatch>> fetchHistory(String userId) async {
    final json = await _api.get('/users/$userId/matches') as List;
    return json.map((e) => PadelMatch.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Registra o placar. A partida entra como [MatchStatus.pendingConfirmation]
  /// até que ao menos um adversário confirme (validação cruzada anti-fraude).
  Future<PadelMatch> submitMatch({
    required MatchFormat format,
    required List<String> teamAPlayerIds,
    required List<String> teamBPlayerIds,
    required List<SetScore> sets,
    String? arenaId,
  }) async {
    final json = await _api.post('/matches', body: {
      'format': format.name,
      'teamAPlayerIds': teamAPlayerIds,
      'teamBPlayerIds': teamBPlayerIds,
      'sets': sets.map((s) => {'teamA': s.teamA, 'teamB': s.teamB}).toList(),
      if (arenaId != null) 'arenaId': arenaId,
    });
    return PadelMatch.fromJson(json as Map<String, dynamic>);
  }

  Future<void> confirmMatch(String matchId) {
    return _api.post('/matches/$matchId/confirm');
  }

  Future<void> giveKudos(String matchId) {
    return _api.post('/matches/$matchId/kudos');
  }
}
