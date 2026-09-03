import '../core/network/api_client.dart';
import '../models/app_user.dart';
import '../models/match.dart';
import '../models/player_badge.dart';

class UserService {
  UserService(this._api);

  final ApiClient _api;

  Future<AppUser> fetchProfile(String userId) async {
    final json = await _api.get('/users/$userId');
    return AppUser.fromJson(json as Map<String, dynamic>);
  }

  /// Firebase Auth and the Postgres profile are separate — call this right
  /// after sign-in so a `users` row exists for the signed-in uid.
  Future<AppUser> ensureProfile() async {
    final json = await _api.post('/users/me');
    return AppUser.fromJson(json as Map<String, dynamic>);
  }

  Future<List<MatchPlayer>> searchPlayers(String query) async {
    if (query.trim().length < 2) return [];
    final json = await _api.get('/users', query: {'q': query}) as List;
    return json
        .map((e) => MatchPlayer(
              id: (e as Map<String, dynamic>)['id'] as String,
              name: e['name'] as String,
              photoUrl: e['photoUrl'] as String?,
            ))
        .toList();
  }

  Future<List<double>> fetchRatingHistory(String userId) async {
    final json = await _api.get('/users/$userId/rating-history') as List;
    return json.map((e) => (e as num).toDouble()).toList();
  }

  Future<List<PlayerBadge>> fetchBadges(String userId) async {
    final json = await _api.get('/users/$userId/badges') as List;
    return json
        .map((e) => PlayerBadge(
              type: BadgeType.values.byName((e as Map<String, dynamic>)['type'] as String),
              unlockedAt: DateTime.parse(e['unlockedAt'] as String),
            ))
        .toList();
  }
}
