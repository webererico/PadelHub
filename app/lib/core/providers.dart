import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network/api_client.dart';
import '../services/auth_service.dart';
import '../services/arena_service.dart';
import '../services/match_service.dart';
import '../services/ranking_service.dart';
import '../services/user_service.dart';

/// Base URL of the deployed Cloud Functions API in front of Cloud SQL.
/// Override with --dart-define=API_BASE_URL=... per environment.
const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://us-central1-padelhub-prod.cloudfunctions.net/api',
);

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(baseUrl: _apiBaseUrl));

final matchServiceProvider = Provider<MatchService>((ref) => MatchService(ref.watch(apiClientProvider)));

final rankingServiceProvider = Provider<RankingService>((ref) => RankingService(ref.watch(apiClientProvider)));

final arenaServiceProvider = Provider<ArenaService>((ref) => ArenaService(ref.watch(apiClientProvider)));

final userServiceProvider = Provider<UserService>((ref) => UserService(ref.watch(apiClientProvider)));
