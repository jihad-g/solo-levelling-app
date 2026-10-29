/// Quest toggling, daily rollover, penalties and streaks. Pure Dart.
library;

import 'content.dart';
import 'models.dart';
import 'xp_engine.dart';

/// The result of ticking or un-ticking a quest.
class ToggleResult {
  final GameState state;

  /// Tracks whose level went up because of this toggle.
  final List<String> trackLevelUps;

  final int masterLevelBefore;
  final int masterLevelAfter;

  const ToggleResult(
    this.state,
    this.trackLevelUps,
    this.masterLevelBefore,
    this.masterLevelAfter,
  );

  bool get masterLeveledUp => masterLevelAfter > masterLevelBefore;
}

/// The result of a daily reset check.
class RolloverResult {
  final GameState state;
  final DayReport? report;
  const RolloverResult(this.state, this.report);
  bool get rolledOver => report != null;
}

class GameLogic {
  GameLogic._();

  static GameState newGame({
    required String playerName,
    required List<String> activeTracks,
    required double? weightKg,
    required Day today,
  }) {
    final fresh = {for (final id in activeTracks) id: const TrackProgress()};
    return GameState(
      playerName: playerName,
      weightKg: weightKg,
      activeTracks: List.unmodifiable(activeTracks),
      tracks: fresh,
      dayStartTracks: fresh,
      today: today,
      completedToday: const [],
      startedOn: today,
    );
  }

  /// Rebuilds today's progress from the start-of-day snapshot plus the
  /// quests completed today, in order.
  static Map<String, TrackProgress> replayDay(
    Map<String, TrackProgress> dayStart,
    List<String> completed,
  ) {
    final result = Map<String, TrackProgress>.from(dayStart);
    for (final qid in completed) {
      final q = Content.quest(qid);
      if (q == null) continue;
      final base = Content.track(q.trackId).base;
      final p = result[q.trackId] ?? const TrackProgress();
      result[q.trackId] = XpEngine.addXp(p, q.xp, base);
    }
    return result;
  }

  static ToggleResult toggleQuest(GameState s, String questId) {
    final q = Content.quest(questId);
    if (q == null || !s.activeTracks.contains(q.trackId)) {
      return ToggleResult(s, const [], s.masterLevel, s.masterLevel);
    }
    final completed = List<String>.from(s.completedToday);
    if (!completed.remove(questId)) completed.add(questId);

    final tracks = replayDay(s.dayStartTracks, completed);
    final next = s.copyWith(tracks: tracks, completedToday: completed);

    final ups = <String>[
      for (final id in s.activeTracks)
        if (next.progress(id).level > s.progress(id).level) id,
    ];
    return ToggleResult(next, ups, s.masterLevel, next.masterLevel);
  }

  /// Scores one finished day for every active track: missed-daily penalties
  /// and streaks. [completed] is the list of quests done that day.
  static Map<String, TrackProgress> scoreDay(
    Map<String, TrackProgress> tracks,
    List<String> activeTracks,
    List<String> completed, {
    Map<String, int>? xpLost,
    Set<String>? kept,
    Set<String>? broken,
  }) {
    final result = Map<String, TrackProgress>.from(tracks);
    final done = completed.toSet();
    for (final id in activeTracks) {
      final def = Content.track(id);
      var p = result[id] ?? const TrackProgress();
      final dailies = Content.dailiesFor(id);

      var penalty = 0;
      for (final d in dailies) {
        if (!done.contains(d.id)) penalty += d.missPenalty;
      }
      if (penalty > 0) {
        final before = p.xp;
        p = XpEngine.removeXp(p, penalty);
        final lost = before - p.xp;
        if (lost > 0 && xpLost != null) {
          xpLost[id] = (xpLost[id] ?? 0) + lost;
        }
      }

      final streakDone = def.streakOnAnyQuest
          ? Content.questsFor(id).any((q) => done.contains(q.id))
          : dailies.isNotEmpty && dailies.every((d) => done.contains(d.id));
      if (streakDone) {
        final streak = p.streak + 1;
        p = p.copyWith(
          streak: streak,
          bestStreak: streak > p.bestStreak ? streak : p.bestStreak,
        );
        kept?.add(id);
        broken?.remove(id);
      } else {
        if (p.streak > 0) broken?.add(id);
        kept?.remove(id);
        p = p.copyWith(streak: 0);
      }
      result[id] = p;
    }
    return result;
  }

  /// Runs the daily reset if [now] is a later day than the saved one.
  /// The saved day is scored with what was completed; any further missed
  /// days are scored as empty, up to 7 scored days in total.
  static RolloverResult rollover(GameState s, Day now) {
    if (!now.isAfter(s.today)) return RolloverResult(s, null);

    final daysAway = s.today.daysUntil(now);
    final xpLost = <String, int>{};
    final kept = <String>{};
    final broken = <String>{};

    var tracks = scoreDay(
      s.tracks,
      s.activeTracks,
      s.completedToday,
      xpLost: xpLost,
      kept: kept,
      broken: broken,
    );

    final extra = (daysAway - 1).clamp(0, Content.maxMissedDaysScored - 1);
    for (var i = 0; i < extra; i++) {
      tracks = scoreDay(
        tracks,
        s.activeTracks,
        const [],
        xpLost: xpLost,
        kept: kept,
        broken: broken,
      );
    }

    final report = DayReport(
      newDay: now,
      daysScored: 1 + extra,
      daysAway: daysAway,
      xpLost: xpLost,
      streaksKept: [
        for (final id in s.activeTracks)
          if (kept.contains(id)) id,
      ],
      streaksBroken: [
        for (final id in s.activeTracks)
          if (broken.contains(id)) id,
      ],
    );

    final next = s.copyWith(
      tracks: tracks,
      dayStartTracks: tracks,
      today: now,
      completedToday: const [],
      pendingReport: report,
    );
    return RolloverResult(next, report);
  }

  /// Daily-quest progress for today: (done, total) over active tracks.
  static (int, int) dailyProgress(GameState s) {
    var done = 0;
    var total = 0;
    for (final id in s.activeTracks) {
      for (final d in Content.dailiesFor(id)) {
        total++;
        if (s.isDone(d.id)) done++;
      }
    }
    return (done, total);
  }
}
