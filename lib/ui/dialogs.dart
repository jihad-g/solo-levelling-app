import 'package:flutter/material.dart';

import '../core/content.dart';
import '../core/game_logic.dart';
import '../core/models.dart';
import 'theme.dart';
import 'widgets/system_panel.dart';

/// Opens a System window: a thin line draws across, then the window
/// unfolds vertically from it.
Future<void> showSystemWindow(
  BuildContext context, {
  required String title,
  required Widget body,
  Color accent = SysColors.cyan,
  String button = 'OK',
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 520),
    pageBuilder: (ctx, _, _) => SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Material(
            type: MaterialType.transparency,
            child: SystemPanel(
              accent: accent,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SystemTitle(title, color: accent),
                  const SizedBox(height: 16),
                  Flexible(child: SingleChildScrollView(child: body)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        button,
                        style: AppTheme.display(size: 18, color: accent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final line = CurvedAnimation(
        parent: anim,
        curve: const Interval(0, 0.45, curve: Curves.easeOut),
      );
      final unfold = CurvedAnimation(
        parent: anim,
        curve: const Interval(0.4, 1, curve: Curves.easeOutCubic),
      );
      return Opacity(
        opacity: line.value,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            line.value,
            0.02 + 0.98 * unfold.value,
            1,
          ),
          child: child,
        ),
      );
    },
  );
}

Widget _line(String text, {Color color = SysColors.text, bool bold = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );

String _names(List<String> ids) =>
    ids.map((id) => Content.track(id).name).join(', ');

Future<void> showDailyQuestArrived(
  BuildContext context,
  DayReport report,
  GameState state,
) {
  final (_, total) = GameLogic.dailyProgress(state);
  final body = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _line('A new day has begun, ${state.playerName}.', bold: true),
      _line(
        '$total daily quests are waiting across '
        '${state.activeTracks.length} tracks.',
      ),
      if (report.daysScored > 0) ...[
        const SizedBox(height: 12),
        if (report.daysAway > report.daysScored)
          _line(
            'You were away ${report.daysAway} days. '
            'Only the last ${report.daysScored} were scored.',
            color: SysColors.muted,
          ),
        if (report.xpLost.isEmpty)
          _line('No penalties. Every daily was cleared.', color: SysColors.cyan)
        else ...[
          _line(
            'Penalty for missed dailies:',
            color: SysColors.red,
            bold: true,
          ),
          for (final e in report.xpLost.entries)
            _line(
              '  ${Content.track(e.key).name}  −${e.value} XP',
              color: SysColors.red,
            ),
        ],
        if (report.streaksKept.isNotEmpty)
          _line(
            'Streaks grown: ${_names(report.streaksKept)}',
            color: SysColors.gold,
          ),
        if (report.streaksBroken.isNotEmpty)
          _line(
            'Streaks lost: ${_names(report.streaksBroken)}',
            color: SysColors.muted,
          ),
      ],
      const SizedBox(height: 12),
      _line(
        'Failing to complete daily quests will result in a penalty.',
        color: SysColors.muted,
      ),
    ],
  );
  return showSystemWindow(
    context,
    title: 'Daily Quest has arrived',
    body: body,
    button: 'ACCEPT',
  );
}

Future<void> showLevelUp(BuildContext context, ToggleResult r) {
  final s = r.state;
  final body = Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      for (final id in r.trackLevelUps)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '${Content.track(id).name}  →  Lv. ${s.progress(id).level}',
            style: AppTheme.display(size: 22, color: SysColors.gold),
          ),
        ),
      if (r.masterLeveledUp) ...[
        const SizedBox(height: 12),
        Text(
          'MASTER LEVEL ${r.masterLevelAfter}',
          style: AppTheme.display(size: 30, color: SysColors.purple),
        ),
        Text(
          'Rank ${s.hunterRank}',
          style: AppTheme.display(size: 18, color: SysColors.muted),
        ),
      ],
    ],
  );
  return showSystemWindow(
    context,
    title: 'Level Up!',
    body: body,
    accent: SysColors.gold,
  );
}
