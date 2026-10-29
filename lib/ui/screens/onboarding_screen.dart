import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content.dart';
import '../../state/game_controller.dart';
import '../theme.dart';
import '../widgets/system_panel.dart';

/// Awakening → name → tracks → weight.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final _name = TextEditingController();
  final _weight = TextEditingController();
  final Set<String> _tracks = Content.allTrackIds.toSet();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
    1 => _name.text.trim().isNotEmpty,
    2 => _tracks.isNotEmpty,
    3 => _weight.text.trim().isEmpty || _parsedWeight != null,
    _ => true,
  };

  double? get _parsedWeight {
    final v = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    return (v != null && v > 20 && v < 400) ? v : null;
  }

  Future<void> _next() async {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    setState(() => _busy = true);
    await ref
        .read(gameControllerProvider.notifier)
        .awaken(
          name: _name.text.trim(),
          tracks: [
            for (final id in Content.allTrackIds)
              if (_tracks.contains(id)) id,
          ],
          weightKg: _parsedWeight,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_step > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: SysColors.muted),
                    onPressed: () => setState(() => _step--),
                  ),
                )
              else
                const SizedBox(height: 48),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(context),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _canContinue && !_busy ? _next : null,
                child: Text(switch (_step) {
                  0 => 'ACCEPT',
                  3 => 'BEGIN',
                  _ => 'CONTINUE',
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 0:
        return Center(
          child: SystemPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SystemTitle('NOTIFICATION'),
                const SizedBox(height: 20),
                Text(
                  'You have acquired the qualifications to be a Player.',
                  textAlign: TextAlign.center,
                  style: AppTheme.display(size: 22),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Real tasks become quests. Quests give XP. '
                  'Your tracks level up and feed one Master Level.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SysColors.muted),
                ),
                const SizedBox(height: 20),
                Text(
                  'Will you accept?',
                  style: AppTheme.display(size: 20, color: SysColors.gold),
                ),
              ],
            ),
          ),
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const SystemTitle('Register Player Name'),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: AppTheme.display(size: 24),
              decoration: const InputDecoration(hintText: 'Name'),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _canContinue ? _next() : null,
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SystemTitle('Choose Your Tracks'),
            const SizedBox(height: 6),
            const Text(
              'Every active track must keep up for the Master Level to pass '
              'its balance gates.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SysColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final t in Content.tracks)
                    CheckboxListTile(
                      value: _tracks.contains(t.id),
                      onChanged: (v) => setState(
                        () => v == true
                            ? _tracks.add(t.id)
                            : _tracks.remove(t.id),
                      ),
                      title: Text(t.name, style: AppTheme.display(size: 19)),
                      subtitle: Text(
                        t.blurb,
                        style: const TextStyle(color: SysColors.muted),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const SystemTitle('Body Measurement'),
            const SizedBox(height: 8),
            const Text(
              'Starting weight, for the Body track. Optional.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SysColors.muted),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: AppTheme.display(size: 24),
              decoration: const InputDecoration(
                hintText: 'e.g. 82',
                suffixText: 'kg',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        );
    }
  }
}
