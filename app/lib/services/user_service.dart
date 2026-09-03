import '../core/network/api_client.dart';
import '../models/app_user.dart';
import '../models/player_badge.dart';

class UserService {
  UserService(this._api);

  final ApiClient _api;

  Future<AppUser> fetchProfile(String userId) async {
    final json = await _api.get('/users/$userId');
    return AppUser.fromJson(json as Map<String, dynamic>);
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
