import '../core/network/api_client.dart';
import '../models/super_event.dart';

class EventService {
  EventService(this._api);

  final ApiClient _api;

  Future<List<SuperEventSummary>> fetchEvents() async {
    final json = await _api.get('/events') as List;
    return json.map((e) => SuperEventSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SuperEvent> fetchEvent(String eventId) async {
    final json = await _api.get('/events/$eventId');
    return SuperEvent.fromJson(json as Map<String, dynamic>);
  }

  Future<SuperEvent> createEvent({
    required String name,
    required EventFormat format,
    required List<String> playerIds,
    String? arenaId,
  }) async {
    final json = await _api.post('/events', body: {
      'name': name,
      'format': format.name,
      'playerIds': playerIds,
      if (arenaId != null) 'arenaId': arenaId,
    });
    return SuperEvent.fromJson(json as Map<String, dynamic>);
  }

  Future<SuperEvent> scoreRound(String eventId, String roundId, {required int teamAGames, required int teamBGames}) async {
    final json = await _api.post('/events/$eventId/rounds/$roundId/score', body: {
      'teamAGames': teamAGames,
      'teamBGames': teamBGames,
    });
    return SuperEvent.fromJson(json as Map<String, dynamic>);
  }
}
