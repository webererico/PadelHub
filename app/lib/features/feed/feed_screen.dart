import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_avatar.dart';
import 'widgets/match_card.dart';

final feedProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(matchServiceProvider).fetchFeed();
});

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    final matchService = ref.watch(matchServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_tennis, color: AppColors.accent, size: 22),
            SizedBox(width: 8),
            Text('PadelHub'),
          ],
        ),
        actions: const [
          Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
          SizedBox(width: 12),
          _AccountMenu(),
          SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(feedProvider.future),
        child: feed.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          error: (error, stack) => _FeedError(onRetry: () => ref.invalidate(feedProvider)),
          data: (matches) {
            if (matches.isEmpty) {
              return const _EmptyFeed();
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: matches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) => MatchCard(match: matches[index], matchService: matchService),
            );
          },
        ),
      ),
    );
  }
}

class _AccountMenu extends ConsumerWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    final initials = _initialsFor(user?.displayName ?? user?.email);

    return PopupMenuButton<String>(
      tooltip: 'Conta',
      offset: const Offset(0, 44),
      color: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'logout') {
          ref.read(authServiceProvider).signOut();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: AppColors.danger),
              SizedBox(width: 10),
              Text('Sair'),
            ],
          ),
        ),
      ],
      child: AppAvatar(initials: initials, size: 32),
    );
  }

  static String _initialsFor(String? source) {
    final trimmed = source?.trim() ?? '';
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: const [
        SizedBox(height: 80),
        Icon(Icons.sports_tennis, color: AppColors.textTertiary, size: 48),
        SizedBox(height: 16),
        Text(
          'Nenhuma partida por aqui ainda. Registre a sua primeira e comece a subir no ranking.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, color: AppColors.textTertiary, size: 40),
          const SizedBox(height: 12),
          const Text('Não foi possível carregar o feed.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
