import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../state/game_controller.dart';
import '../dialogs.dart';
import '../theme.dart';
import 'quests_screen.dart';
import 'status_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final GameState state;
  const HomeScreen({super.key, required this.state});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;
  bool _reportOpen = false;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(gameControllerProvider.notifier).checkDay(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _maybeShowReport(GameState s) {
    final report = s.pendingReport;
    if (report == null || _reportOpen) return;
    _reportOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDailyQuestArrived(context, report, s);
      await ref.read(gameControllerProvider.notifier).dismissReport();
      _reportOpen = false;
    });
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SysColors.panel,
        title: Text('Reset everything?', style: AppTheme.display(size: 20)),
        content: const Text(
          'All levels, XP and streaks will be deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset', style: TextStyle(color: SysColors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(gameControllerProvider.notifier).resetAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    _maybeShowReport(s);
    return Scaffold(
      appBar: AppBar(
        title: const Text('THE SYSTEM'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: SysColors.muted),
            onSelected: (v) {
              if (v == 'reset') _confirmReset();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'reset', child: Text('Reset all progress')),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          StatusScreen(state: s),
          QuestsScreen(state: s),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Status',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Quests',
          ),
        ],
      ),
    );
  }
}
