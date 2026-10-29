import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/game_logic.dart';
import '../core/models.dart';
import '../data/game_repository.dart';

final repositoryProvider = Provider<GameRepository>((ref) => GameRepository());

/// The clock, overridable in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The game. `null` data means the player hasn't been awakened yet.
final gameControllerProvider =
    AsyncNotifierProvider<GameController, GameState?>(GameController.new);

class GameController extends AsyncNotifier<GameState?> {
  Timer? _midnight;

  GameRepository get _repo => ref.read(repositoryProvider);
  Day _today() => Day.fromDateTime(ref.read(clockProvider)());

  @override
  Future<GameState?> build() async {
    ref.onDispose(() => _midnight?.cancel());
    final saved = await _repo.load();
    if (saved == null) return null;
    final r = GameLogic.rollover(saved, _today());
    if (r.rolledOver) await _repo.save(r.state);
    _scheduleMidnight();
    return r.state;
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = ref.read(clockProvider)();
    final next = DateTime(now.year, now.month, now.day + 1, 0, 0, 2);
    _midnight = Timer(next.difference(now), () {
      checkDay();
      _scheduleMidnight();
    });
  }

  Future<void> _set(GameState s) async {
    state = AsyncData(s);
    await _repo.save(s);
  }

  Future<void> awaken({
    required String name,
    required List<String> tracks,
    required double? weightKg,
  }) async {
    final s = GameLogic.newGame(
      playerName: name,
      activeTracks: tracks,
      weightKg: weightKg,
      today: _today(),
    );
    // The first day opens with the Daily Quest window too.
    await _set(
      s.copyWith(
        pendingReport: DayReport(newDay: s.today, daysScored: 0, daysAway: 0),
      ),
    );
    _scheduleMidnight();
  }

  /// Ticks or un-ticks a quest. Runs the daily reset first, so a quest
  /// ticked after midnight counts for the new day.
  Future<ToggleResult?> toggle(String questId) async {
    await checkDay();
    final s = state.value;
    if (s == null) return null;
    final r = GameLogic.toggleQuest(s, questId);
    await _set(r.state);
    return r;
  }

  /// Daily reset check. Called at midnight and when the app is resumed.
  Future<void> checkDay() async {
    final s = state.value;
    if (s == null) return;
    final r = GameLogic.rollover(s, _today());
    if (r.rolledOver) await _set(r.state);
  }

  Future<void> dismissReport() async {
    final s = state.value;
    if (s == null || s.pendingReport == null) return;
    await _set(s.copyWith(clearReport: true));
  }

  Future<void> updateWeight(double kg) async {
    final s = state.value;
    if (s == null) return;
    await _set(s.copyWith(weightKg: kg));
  }

  /// Wipes the save and returns to the Awakening.
  Future<void> resetAll() async {
    _midnight?.cancel();
    await _repo.delete();
    state = const AsyncData(null);
  }
}
