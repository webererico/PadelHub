import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../models/match.dart';
import '../../widgets/player_search_field.dart';
import 'widgets/score_stepper.dart';

class RecordMatchScreen extends ConsumerStatefulWidget {
  const RecordMatchScreen({super.key});

  @override
  ConsumerState<RecordMatchScreen> createState() => _RecordMatchScreenState();
}

class _RecordMatchScreenState extends ConsumerState<RecordMatchScreen> {
  MatchFormat _format = MatchFormat.amistosa;
  MatchPlayer? _partner;
  MatchPlayer? _opponent1;
  MatchPlayer? _opponent2;
  final List<(int, int)> _sets = [(6, 4), (3, 6), (10, 8)];
  bool _isSubmitting = false;

  Future<void> _submit() async {
    final myUid = ref.read(authStateProvider).asData?.value?.uid;
    if (myUid == null || _partner == null || _opponent1 == null || _opponent2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione os 4 jogadores da partida.'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(matchServiceProvider).submitMatch(
            format: _format,
            teamAPlayerIds: [myUid, _partner!.id],
            teamBPlayerIds: [_opponent1!.id, _opponent2!.id],
            sets: _sets.map((s) => SetScore(teamA: s.$1, teamB: s.$2)).toList(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Placar enviado! Aguardando confirmação dos adversários.'), backgroundColor: AppColors.success),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível enviar o placar. Tente novamente.'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _updateSet(int index, {int? teamA, int? teamB}) {
    setState(() {
      final current = _sets[index];
      _sets[index] = (teamA ?? current.$1, teamB ?? current.$2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final excludeIds = [
      ref.watch(authStateProvider).asData?.value?.uid,
      _partner?.id,
      _opponent1?.id,
      _opponent2?.id,
    ].whereType<String>().toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Partida')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const _SectionLabel('Formato'),
          const SizedBox(height: 10),
          SegmentedButton<MatchFormat>(
            segments: const [
              ButtonSegment(value: MatchFormat.amistosa, label: Text('Amistosa')),
              ButtonSegment(value: MatchFormat.torneio, label: Text('Torneio')),
              ButtonSegment(value: MatchFormat.americano, label: Text('Americano')),
            ],
            selected: {_format},
            onSelectionChanged: (selection) => setState(() => _format = selection.first),
          ),
          const SizedBox(height: 22),
          const _SectionLabel('Sua dupla'),
          const SizedBox(height: 10),
          PlayerSearchField(
            label: 'Buscar parceiro',
            selected: _partner,
            excludeIds: excludeIds,
            onSelected: (p) => setState(() => _partner = p),
          ),
          const SizedBox(height: 22),
          const _SectionLabel('Adversários'),
          const SizedBox(height: 10),
          PlayerSearchField(
            label: 'Buscar adversário 1',
            selected: _opponent1,
            excludeIds: excludeIds,
            onSelected: (p) => setState(() => _opponent1 = p),
          ),
          const SizedBox(height: 12),
          PlayerSearchField(
            label: 'Buscar adversário 2',
            selected: _opponent2,
            excludeIds: excludeIds,
            onSelected: (p) => setState(() => _opponent2 = p),
          ),
          const SizedBox(height: 22),
          const _SectionLabel('Placar por set'),
          const SizedBox(height: 10),
          for (var i = 0; i < _sets.length; i++) ...[
            SetScoreEntry(
              label: i < 2 ? 'SET ${i + 1}' : 'SUPER TIE-BREAK',
              teamAGames: _sets[i].$1,
              teamBGames: _sets[i].$2,
              highlighted: i == 2,
              onTeamAChanged: (v) => _updateSet(i, teamA: v),
              onTeamBChanged: (v) => _updateSet(i, teamB: v),
            ),
            if (i != _sets.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_outlined, color: AppColors.accent, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Validação cruzada: o placar só entra para o ranking depois que ao menos um adversário confirmar.',
                    style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(_isSubmitting ? 'Enviando...' : 'Enviar para confirmação'),
          ),
        ],
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
