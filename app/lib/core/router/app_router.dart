import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/record_match/record_match_screen.dart';
import '../../features/arena/arena_screen.dart';
import '../providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (authState.isLoading) return null;
      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';
      return null;
    },
    refreshListenable: _AuthStateListenable(ref),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeShell()),
      GoRoute(path: '/record', builder: (context, state) => const RecordMatchScreen()),
      GoRoute(path: '/arena/:arenaId', builder: (context, state) => ArenaScreen(arenaId: state.pathParameters['arenaId']!)),
    ],
  );
});

/// Bridges Riverpod's authStateProvider stream into a Listenable so
/// go_router re-evaluates `redirect` whenever the auth state changes.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen<AsyncValue<User?>>(authStateProvider, (_, __) => notifyListeners());
  }
}
