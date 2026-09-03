import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network/api_client.dart';
import '../services/auth_service.dart';
import '../services/arena_service.dart';
import '../services/event_service.dart';
import '../services/match_service.dart';
import '../services/ranking_service.dart';
import '../services/user_service.dart';

/// Base URL of the API. Defaults to a path relative to wherever the app
/// itself is served (Firebase Hosting rewrites `/api/**` to the Cloud
/// Function — see firebase.json), so no project/region needs hardcoding.
/// Override for local dev: --dart-define=API_BASE_URL=http://localhost:5001/<project>/<region>/api
const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '/api');

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(baseUrl: _apiBaseUrl));

/// Ensures a Postgres `users` row exists for the signed-in Firebase user.
/// Watch this once from an authenticated screen (HomeShell) — it re-fires
/// whenever the signed-in uid changes, including on a fresh app boot with
/// an already-persisted session.
final ensureProfileProvider = FutureProvider.autoDispose<void>((ref) async {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return;
  await ref.watch(userServiceProvider).ensureProfile();
});

final matchServiceProvider = Provider<MatchService>((ref) => MatchService(ref.watch(apiClientProvider)));

final rankingServiceProvider = Provider<RankingService>((ref) => RankingService(ref.watch(apiClientProvider)));

final arenaServiceProvider = Provider<ArenaService>((ref) => ArenaService(ref.watch(apiClientProvider)));

final userServiceProvider = Provider<UserService>((ref) => UserService(ref.watch(apiClientProvider)));

final eventServiceProvider = Provider<EventService>((ref) => EventService(ref.watch(apiClientProvider)));
