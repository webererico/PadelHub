import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import 'arena_screen.dart';

final _myClubIdProvider = FutureProvider.autoDispose((ref) async {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return null;
  final user = await ref.watch(userServiceProvider).fetchProfile(uid);
  return user.clubId;
});

/// Resolves the signed-in player's own club before showing its Arena screen —
/// the bottom-nav "Arenas" tab has no arenaId to hand ArenaScreen up front.
class MyArenaTab extends ConsumerWidget {
  const MyArenaTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubId = ref.watch(_myClubIdProvider);

    return clubId.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.accent))),
      error: (error, stack) => Scaffold(
        body: Center(
          child: TextButton(onPressed: () => ref.invalidate(_myClubIdProvider), child: const Text('Não foi possível carregar sua arena.')),
        ),
      ),
      data: (id) {
        if (id == null) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Você ainda não tem um clube favorito. Adicione um no seu perfil para ver o ranking interno e quem está jogando agora.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          );
        }
        return ArenaScreen(arenaId: id);
      },
    );
  }
}
