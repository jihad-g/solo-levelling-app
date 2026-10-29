import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content.dart';
import '../../core/game_logic.dart';
import '../../core/models.dart';
import '../../core/xp_engine.dart';
import '../../state/game_controller.dart';
import '../theme.dart';
import '../widgets/system_panel.dart';

class StatusScreen extends ConsumerWidget {
  final GameState state;
  const StatusScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = state;
    final (done, total) = GameLogic.dailyProgress(s);
    final gate = XpEngine.blockingGate(s.activeLevels);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SystemPanel(
          child: Column(
            children: [
              const SystemTitle('STATUS'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('NAME'),
                        Text(
                          s.playerName,
                          style: AppTheme.display(size: 22),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _label('RANK'),
                        Text(
                          '${s.hunterRank}-Rank Hunter',
                          style: AppTheme.display(
                            size: 20,
                            color: SysColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _label('MASTER LEVEL'),
                      Text(
                        '${s.masterLevel}',
                        style: AppTheme.display(
                          size: 56,
                          color: SysColors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _label('DAILY QUESTS'),
                  Text(
                    '$done / $total',
                    style: AppTheme.display(
                      size: 16,
                      color: done == total ? SysColors.cyan : SysColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              XpBar(value: total == 0 ? 0 : done / total),
              if (gate != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Balance gate: Master Level ${gate.masterLevel} needs every '
                  'track at Lv. ${gate.minTrackLevel}.',
                  style: const TextStyle(color: SysColors.red, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final id in s.activeTracks) ...[
          _TrackCard(state: s, trackId: id),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

Widget _label(String text) => Text(
  text,
  style: const TextStyle(
    color: SysColors.muted,
    fontSize: 11,
    letterSpacing: 1.5,
  ),
);

class _TrackCard extends ConsumerWidget {
  final GameState state;
  final String trackId;
  const _TrackCard({required this.state, required this.trackId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final def = Content.track(trackId);
    final p = state.progress(trackId);
    final need = XpEngine.xpToNext(def.base, p.level);
    final isBody = trackId == 'body';

    return Material(
      color: SysColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: SysColors.panelEdge),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isBody ? () => _editWeight(context, ref) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(def.name, style: AppTheme.display(size: 19)),
                  ),
                  if (p.streak > 0) ...[
                    const Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: SysColors.gold,
                    ),
                    Text(
                      ' ${p.streak}',
                      style: AppTheme.display(size: 15, color: SysColors.gold),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    'Lv. ${p.level}',
                    style: AppTheme.display(size: 19, color: SysColors.cyan),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              XpBar(value: p.xp / need),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isBody
                          ? (state.weightKg == null
                                ? 'Tap to set weight'
                                : 'Weight ${_fmt(state.weightKg!)} kg')
                          : def.blurb,
                      style: const TextStyle(
                        color: SysColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${p.xp} / $need XP',
                    style: const TextStyle(
                      color: SysColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Future<void> _editWeight(BuildContext context, WidgetRef ref) async {
    final c = TextEditingController(
      text: state.weightKg == null ? '' : _fmt(state.weightKg!),
    );
    final kg = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SysColors.panel,
        title: Text('Weight', style: AppTheme.display(size: 20)),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'kg'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
              Navigator.pop(ctx, (v != null && v > 20 && v < 400) ? v : null);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    c.dispose();
    if (kg != null) {
      await ref.read(gameControllerProvider.notifier).updateWeight(kg);
    }
  }
}
