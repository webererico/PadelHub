import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../models/super_event.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/pill_chip.dart';

final _eventProvider = FutureProvider.autoDispose.family<SuperEvent, String>((ref, eventId) {
  return ref.watch(eventServiceProvider).fetchEvent(eventId);
});

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(_eventProvider(widget.eventId));
    final myUid = ref.watch(authStateProvider).asData?.value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: event.asData?.value != null ? Text(event.asData!.value.name) : const Text('Evento'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.accent,
          tabs: const [Tab(text: 'Rodadas'), Tab(text: 'Classificação')],
        ),
      ),
      body: event.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (error, stack) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(_eventProvider(widget.eventId)),
            child: const Text('Não foi possível carregar o evento.'),
          ),
        ),
        data: (data) => TabBarView(
          controller: _tabController,
          children: [
            _RoundsTab(event: data, myUid: myUid, eventId: widget.eventId),
            _StandingsTab(event: data),
          ],
        ),
      ),
    );
  }
}

class _RoundsTab extends ConsumerWidget {
  const _RoundsTab({required this.event, required this.myUid, required this.eventId});

  final SuperEvent event;
  final String? myUid;
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          children: [
            PillChip(label: event.format.label, background: AppColors.accent.withValues(alpha: 0.18), foreground: AppColors.accent),
            const SizedBox(width: 8),
            PillChip(label: event.status.label),
            const Spacer(),
            Text('${event.players.length} jogadores', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
        const SizedBox(height: 18),
        for (var roundIndex = 0; roundIndex < event.roundCount; roundIndex++) ...[
          Text('RODADA ${roundIndex + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.textTertiary)),
          const SizedBox(height: 8),
          for (final round in event.roundsAt(roundIndex))
            _RoundCard(round: round, canScore: myUid != null && [...round.teamAPlayerIds, ...round.teamBPlayerIds].contains(myUid), eventId: eventId),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _RoundCard extends ConsumerWidget {
  const _RoundCard({required this.round, required this.canScore, required this.eventId});

  final SuperEventRound round;
  final bool canScore;
  final String eventId;

  Future<void> _openScoreSheet(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<(int, int)>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => _ScoreEntrySheet(round: round),
    );
    if (result == null) return;
    try {
      await ref.read(eventServiceProvider).scoreRound(eventId, round.id, teamAGames: result.$1, teamBGames: result.$2);
      ref.invalidate(_eventProvider(eventId));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar o placar.'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.circular(8)),
              child: Text('Q${round.courtNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(round.teamAPlayerNames.join(' & '), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(round.teamBPlayerNames.join(' & '), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (round.isScored)
              Text('${round.teamAGames} × ${round.teamBGames}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accent))
            else if (canScore)
              // A plain GestureDetector, not OutlinedButton: Material's button
              // here (Row, inside a ListView item) forces an infinite-width
              // layout constraint and crashes — same bug documented on the
              // Arena "Seguir" button (see arena_screen.dart).
              GestureDetector(
                onTap: () => _openScoreSheet(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
                  child: const Text('Lançar', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              )
            else
              const Text('—', style: TextStyle(color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

class _ScoreEntrySheet extends StatefulWidget {
  const _ScoreEntrySheet({required this.round});

  final SuperEventRound round;

  @override
  State<_ScoreEntrySheet> createState() => _ScoreEntrySheetState();
}

class _ScoreEntrySheetState extends State<_ScoreEntrySheet> {
  int _teamA = 6;
  int _teamB = 4;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Placar da rodada (games até 6, sem vantagem)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _GamesPicker(label: widget.round.teamAPlayerNames.join(' & '), value: _teamA, onChanged: (v) => setState(() => _teamA = v))),
              const SizedBox(width: 16),
              Expanded(child: _GamesPicker(label: widget.round.teamBPlayerNames.join(' & '), value: _teamB, onChanged: (v) => setState(() => _teamB = v))),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _teamA == _teamB ? null : () => Navigator.of(context).pop((_teamA, _teamB)),
            child: const Text('Salvar placar'),
          ),
        ],
      ),
    );
  }
}

class _GamesPicker extends StatelessWidget {
  const _GamesPicker({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: value > 0 ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
            SizedBox(width: 36, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
            IconButton(onPressed: value < 6 ? () => onChanged(value + 1) : null, icon: const Icon(Icons.add_circle_outline)),
          ],
        ),
      ],
    );
  }
}

class _StandingsTab extends StatelessWidget {
  const _StandingsTab({required this.event});

  final SuperEvent event;

  @override
  Widget build(BuildContext context) {
    if (event.standings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Nenhuma rodada com placar lançado ainda.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: event.standings.length,
      itemBuilder: (context, index) {
        final s = event.standings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  SizedBox(width: 24, child: Text('${index + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textTertiary))),
                  AppAvatar(initials: _initials(s.name), size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                        Text('${s.roundsWon}/${s.roundsPlayed} rodadas vencidas', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${s.gamesWon} games', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.accent)),
                      Text('saldo ${s.gamesDiff >= 0 ? '+' : ''}${s.gamesDiff}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
