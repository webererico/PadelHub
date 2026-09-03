import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../core/theme/app_colors.dart';
import '../models/match.dart';
import 'app_avatar.dart';

/// Search-as-you-type player picker. Shows a text field until a player is
/// selected, then swaps to a chip with the chosen name and a way to change it.
class PlayerSearchField extends ConsumerStatefulWidget {
  const PlayerSearchField({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.excludeIds = const [],
  });

  final String label;
  final MatchPlayer? selected;
  final ValueChanged<MatchPlayer?> onSelected;

  /// Player ids to hide from results (e.g. players already picked elsewhere
  /// in the form).
  final List<String> excludeIds;

  @override
  ConsumerState<PlayerSearchField> createState() => _PlayerSearchFieldState();
}

class _PlayerSearchFieldState extends ConsumerState<PlayerSearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<MatchPlayer> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);
      final results = await ref.read(userServiceProvider).searchPlayers(query);
      if (!mounted) return;
      setState(() {
        _results = results.where((p) => !widget.excludeIds.contains(p.id)).toList();
        _isSearching = false;
      });
    });
  }

  void _select(MatchPlayer player) {
    setState(() => _results = []);
    _controller.clear();
    widget.onSelected(player);
  }

  void _clear() {
    widget.onSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selected != null) {
      final player = widget.selected!;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            AppAvatar(initials: player.initials, size: 32),
            const SizedBox(width: 10),
            Expanded(child: Text(player.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.textTertiary),
              onPressed: _clear,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
                  )
                : const Icon(Icons.search, color: AppColors.textTertiary),
          ),
        ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final player in _results)
                  ListTile(
                    dense: true,
                    leading: AppAvatar(initials: player.initials, size: 30),
                    title: Text(player.name, style: const TextStyle(fontSize: 13.5)),
                    onTap: () => _select(player),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
