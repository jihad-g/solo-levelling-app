import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content.dart';
import '../../core/models.dart';
import '../../state/game_controller.dart';
import '../dialogs.dart';
import '../theme.dart';
import '../widgets/system_panel.dart';

class QuestsScreen extends ConsumerWidget {
  final GameState state;
  const QuestsScreen({super.key, required this.state});

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    String questId,
  ) async {
    final r = await ref.read(gameControllerProvider.notifier).toggle(questId);
    if (r == null || !context.mounted) return;
    if (r.trackLevelUps.isNotEmpty || r.masterLeveledUp) {
      await showLevelUp(context, r);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = state;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const SystemTitle('DAILY QUESTS'),
        const SizedBox(height: 4),
        const Text(
          'Resets at midnight. Missed dailies cost XP.',
          textAlign: TextAlign.center,
          style: TextStyle(color: SysColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        for (final id in s.activeTracks)
          _TrackQuests(
            title: Content.track(id).name,
            quests: Content.dailiesFor(id),
            state: s,
            onToggle: (q) => _toggle(context, ref, q),
          ),
        const SizedBox(height: 20),
        const SystemTitle('SIDE QUESTS', color: SysColors.purple),
        const SizedBox(height: 4),
        const Text(
          'Extra XP. Never penalized.',
          textAlign: TextAlign.center,
          style: TextStyle(color: SysColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        for (final id in s.activeTracks)
          _TrackQuests(
            title: Content.track(id).name,
            quests: Content.questsFor(id).where((q) => !q.daily).toList(),
            state: s,
            accent: SysColors.purple,
            onToggle: (q) => _toggle(context, ref, q),
          ),
      ],
    );
  }
}

class _TrackQuests extends StatelessWidget {
  final String title;
  final List<QuestDef> quests;
  final GameState state;
  final Color accent;
  final void Function(String questId) onToggle;

  const _TrackQuests({
    required this.title,
    required this.quests,
    required this.state,
    required this.onToggle,
    this.accent = SysColors.cyan,
  });

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) return const SizedBox.shrink();
    final done = quests.where((q) => state.isDone(q.id)).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: SysColors.panel,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: done == quests.length
                ? accent.withValues(alpha: 0.6)
                : SysColors.panelEdge,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.display(size: 17, color: accent),
                    ),
                  ),
                  Text(
                    '$done/${quests.length}',
                    style: const TextStyle(
                      color: SysColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            for (final q in quests)
              CheckboxListTile(
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: state.isDone(q.id),
                onChanged: (_) => onToggle(q.id),
                title: Text(
                  q.title,
                  style: TextStyle(
                    fontSize: 15,
                    color: state.isDone(q.id)
                        ? SysColors.muted
                        : SysColors.text,
                    decoration: state.isDone(q.id)
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                secondary: Text(
                  '+${q.xp}',
                  style: AppTheme.display(size: 16, color: SysColors.gold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
