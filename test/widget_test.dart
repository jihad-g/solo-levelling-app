import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_leveling/core/models.dart';
import 'package:life_leveling/data/game_repository.dart';
import 'package:life_leveling/main.dart';
import 'package:life_leveling/state/game_controller.dart';
import 'package:life_leveling/ui/theme.dart';

/// Keeps the save in memory so tests never touch the disk.
class MemoryRepository extends GameRepository {
  GameState? saved;
  MemoryRepository();

  @override
  Future<GameState?> load() async => saved;
  @override
  Future<void> save(GameState s) async => saved = s;
  @override
  Future<void> delete() async => saved = null;
}

void main() {
  setUpAll(() => AppTheme.useGoogleFonts = false);

  testWidgets('awakening → name → tracks → weight → daily quest window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final repo = MemoryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          clockProvider.overrideWithValue(() => DateTime(2026, 9, 26, 9)),
        ],
        child: const LifeLevelingApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Will you accept?'), findsOneWidget);
    await tester.tap(find.text('ACCEPT'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Jihad');
    await tester.pump();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.text('Auto Parts'), findsOneWidget);
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '82');
    await tester.pump();
    await tester.tap(find.text('BEGIN'));
    await tester.pumpAndSettle();

    expect(find.text('[ Daily Quest has arrived ]'), findsOneWidget);
    expect(repo.saved!.playerName, 'Jihad');
    expect(repo.saved!.weightKg, 82);
    expect(repo.saved!.activeTracks.length, 8);

    await tester.tap(find.text('ACCEPT'));
    await tester.pumpAndSettle();
    expect(find.text('[ Daily Quest has arrived ]'), findsNothing);
    expect(repo.saved!.pendingReport, isNull);

    // Status window.
    expect(find.text('Jihad'), findsOneWidget);
    expect(find.text('E-Rank Hunter'), findsOneWidget);

    // Tick a daily quest.
    await tester.tap(find.text('Quests'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open on time and walk the stock'));
    await tester.pumpAndSettle();
    expect(repo.saved!.completedToday, ['ap_open']);
    expect(repo.saved!.progress('auto_parts').xp, 30);
  });
}
