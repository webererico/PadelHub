import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../models/match.dart';
import '../../models/super_event.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/player_search_field.dart';

final _myProfileProvider = FutureProvider.autoDispose((ref) async {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return null;
  return ref.watch(userServiceProvider).fetchProfile(uid);
});

/// Player-picker + name form for a Super 8/12 event: the signed-in player is
/// always the first participant, others are added one at a time via search
/// until the format's exact roster size (8 or 12) is reached.
class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _nameController = TextEditingController();
  EventFormat _format = EventFormat.super8;
  final List<MatchPlayer> _players = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _removePlayer(String id) {
    setState(() => _players.removeWhere((p) => p.id == id));
  }

  Future<void> _submit(String myUid) async {
    final name = _nameController.text.trim();
    final playerIds = [myUid, ..._players.map((p) => p.id)];
    if (name.isEmpty || playerIds.length != _format.playerCount) return;

    setState(() => _isSubmitting = true);
    try {
      final event = await ref.read(eventServiceProvider).createEvent(
            name: name,
            format: _format,
            playerIds: playerIds,
          );
      if (mounted) context.pushReplacement('/events/${event.id}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível criar o evento. Tente novamente.'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(authStateProvider).asData?.value?.uid;
    final myProfile = ref.watch(_myProfileProvider);

    final total = _players.length + 1;
    final excludeIds = [if (myUid != null) myUid, ..._players.map((p) => p.id)];

    return Scaffold(
      appBar: AppBar(title: const Text('Criar Super 8/12')),
      body: myProfile.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (_, __) => const Center(child: Text('Não foi possível carregar seu perfil.')),
        data: (me) {
          if (me == null || myUid == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              const _SectionLabel('Nome do evento'),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Ex.: Super 8 de sábado'),
              ),
              const SizedBox(height: 22),
              const _SectionLabel('Formato'),
              const SizedBox(height: 10),
              SegmentedButton<EventFormat>(
                segments: const [
                  ButtonSegment(value: EventFormat.super8, label: Text('Super 8 (8 jogadores)')),
                  ButtonSegment(value: EventFormat.super12, label: Text('Super 12 (12 jogadores)')),
                ],
                selected: {_format},
                onSelectionChanged: (selection) => setState(() {
                  _format = selection.first;
                  if (_players.length + 1 > _format.playerCount) {
                    _players.removeRange(_format.playerCount - 1, _players.length);
                  }
                }),
              ),
              const SizedBox(height: 22),
              _SectionLabel('Jogadores ($total/${_format.playerCount})'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PlayerChip(name: '${me.name} (você)', removable: false),
                  for (final player in _players) _PlayerChip(name: player.name, removable: true, onRemove: () => _removePlayer(player.id)),
                ],
              ),
              if (total < _format.playerCount) ...[
                const SizedBox(height: 14),
                PlayerSearchField(
                  label: 'Adicionar jogador',
                  selected: null,
                  excludeIds: excludeIds,
                  onSelected: (p) {
                    if (p != null) setState(() => _players.add(p));
                  },
                ),
              ],
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.groups_outlined, color: AppColors.accent, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'O app gera automaticamente o rodízio completo: cada jogador forma dupla com todos os outros exatamente uma vez.',
                        style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_isSubmitting || total != _format.playerCount || _nameController.text.trim().isEmpty)
                    ? null
                    : () => _submit(myUid),
                child: Text(_isSubmitting ? 'Criando...' : 'Gerar rodízio'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.textTertiary),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({required this.name, required this.removable, this.onRemove});

  final String name;
  final bool removable;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();
    return Container(
      padding: EdgeInsets.only(left: 6, right: removable ? 4 : 12, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppAvatar(initials: initials, size: 24),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          if (removable)
            IconButton(
              icon: const Icon(Icons.close, size: 14, color: AppColors.textTertiary),
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.only(left: 4),
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
