import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../models/super_event.dart';
import '../../widgets/pill_chip.dart';

final _eventsProvider = FutureProvider.autoDispose((ref) => ref.watch(eventServiceProvider).fetchEvents());

class EventsListScreen extends ConsumerWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(_eventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super 8/12'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/events/new')),
        ],
      ),
      body: events.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (error, stack) => Center(
          child: TextButton(onPressed: () => ref.invalidate(_eventsProvider), child: const Text('Não foi possível carregar os eventos.')),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Nenhum Super 8/12 criado ainda.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => context.push('/events/new'), child: const Text('Criar Super 8/12')),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final event = list[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    onTap: () => context.push('/events/${event.id}'),
                    title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${event.playerCount} jogadores', style: const TextStyle(color: AppColors.textSecondary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PillChip(label: event.format.label, background: AppColors.accent.withValues(alpha: 0.18), foreground: AppColors.accent),
                        const SizedBox(width: 6),
                        PillChip(label: event.status.label),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
