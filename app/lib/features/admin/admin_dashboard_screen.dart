import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../models/arena.dart';

final _arenasProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(arenaServiceProvider).fetchAllArenas();
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arenas = ref.watch(_arenasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Painel Admin')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const _SectionLabel('Cadastrar arena'),
          const SizedBox(height: 10),
          const _CreateArenaForm(),
          const SizedBox(height: 28),
          const _SectionLabel('Arenas cadastradas'),
          const SizedBox(height: 10),
          arenas.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
            ),
            error: (error, stack) => TextButton(
              onPressed: () => ref.invalidate(_arenasProvider),
              child: const Text('Não foi possível carregar as arenas. Tentar novamente.'),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const Text('Nenhuma arena cadastrada ainda.', style: TextStyle(color: AppColors.textSecondary));
              }
              return Column(children: [for (final arena in list) _ArenaRow(arena: arena)]);
            },
          ),
        ],
      ),
    );
  }
}

class _CreateArenaForm extends ConsumerStatefulWidget {
  const _CreateArenaForm();

  @override
  ConsumerState<_CreateArenaForm> createState() => _CreateArenaFormState();
}

class _CreateArenaFormState extends ConsumerState<_CreateArenaForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _courtCountController = TextEditingController(text: '1');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _courtCountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(arenaServiceProvider).createArena(
            name: _nameController.text.trim(),
            city: _cityController.text.trim(),
            state: _stateController.text.trim(),
            courtCount: int.tryParse(_courtCountController.text.trim()) ?? 1,
          );
      ref.invalidate(_arenasProvider);
      _nameController.clear();
      _cityController.clear();
      _stateController.clear();
      _courtCountController.text = '1';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arena cadastrada!'), backgroundColor: AppColors.success),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível cadastrar a arena.'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome do clube'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 2,
                      decoration: const InputDecoration(labelText: 'UF', counterText: ''),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _courtCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Número de quadras'),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  return (n == null || n < 1) ? 'Informe um número válido' : null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? 'Cadastrando...' : 'Cadastrar arena'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArenaRow extends StatelessWidget {
  const _ArenaRow({required this.arena});

  final Arena arena;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(arena.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${arena.city}, ${arena.state}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text('${arena.courtCount} quadras', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
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
