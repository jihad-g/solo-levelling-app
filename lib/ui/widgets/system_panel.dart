import 'package:flutter/material.dart';

import '../theme.dart';

/// A glowing System window panel.
class SystemPanel extends StatelessWidget {
  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;

  const SystemPanel({
    super.key,
    required this.child,
    this.accent = SysColors.cyan,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: SysColors.panel.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// "[ TITLE ]" in System style.
class SystemTitle extends StatelessWidget {
  final String text;
  final Color color;
  final double size;
  const SystemTitle(
    this.text, {
    super.key,
    this.color = SysColors.cyan,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) => Text(
    '[ $text ]',
    textAlign: TextAlign.center,
    style: AppTheme.display(size: size, color: color, letterSpacing: 2),
  );
}

/// Thin XP bar.
class XpBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  const XpBar({
    super.key,
    required this.value,
    this.color = SysColors.cyan,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: SysColors.panelEdge,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
