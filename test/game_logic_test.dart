import 'package:flutter_test/flutter_test.dart';
import 'package:life_leveling/core/content.dart';
import 'package:life_leveling/core/game_logic.dart';
import 'package:life_leveling/core/models.dart';
import 'package:life_leveling/core/xp_engine.dart';

const day1 = Day(2026, 9, 26);

GameState game({List<String>? tracks}) => GameLogic.newGame(
  playerName: 'Jihad',
  activeTracks: tracks ?? Content.allTrackIds,
  weightKg: 80,
  today: day1,
);

GameState withProgress(GameState s, String track, TrackProgress p) {
  final t = {...s.tracks, track: p};
  return s.copyWith(tracks: t, dayStartTracks: t);
}

GameState tickAll(GameState s, Iterable<String> ids) {
  for (final id in ids) {
    s = GameLogic.toggleQuest(s, id).state;
  }
  return s;
}

void main() {
  group('content', () {
    test('every quest belongs to a real track', () {
      for (final q in Content.quests) {
        expect(
          Content.tracks.any((t) => t.id == q.trackId),
          isTrue,
          reason: q.id,
        );
      }
    });

    test('quest ids are unique', () {
      final ids = Content.quests.map((q) => q.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every track has at least one daily', () {
      for (final t in Content.tracks) {
        expect(Content.dailiesFor(t.id), isNotEmpty, reason: t.id);
      }
    });

    test('penalties follow the rules', () {
      expect(Content.quest('ap_open')!.missPenalty, 5);
      expect(Content.quest('mi_meditate')!.missPenalty, 3);
      for (final q in Content.dailiesFor('hobbies')) {
        expect(q.missPenalty, 0);
      }
      for (final q in Content.quests.where((q) => !q.daily)) {
        expect(q.missPenalty, 0, reason: q.id);
      }
    });

    test('Repair Shop has its setup-step daily worth 20 XP', () {
      final d = Content.dailiesFor('repair_shop');
      expect(d.map((q) => q.id), contains('rs_step'));
      expect(Content.quest('rs_step')!.xp, 20);
    });
  });

  group('toggleQuest', () {
    test('ticking adds XP, un-ticking removes it exactly', () {
      var s = game();
      s = GameLogic.toggleQuest(s, 'ap_open').state;
      expect(s.progress('auto_parts').xp, 30);
      expect(s.isDone('ap_open'), isTrue);
      s = GameLogic.toggleQuest(s, 'ap_open').state;
      expect(s.progress('auto_parts').xp, 0);
      expect(s.isDone('ap_open'), isFalse);
    });

    test('reports a level-up and undoes it on un-tick', () {
      // Body base 40 → 50 XP to level 2.
      var s = withProgress(game(), 'body', const TrackProgress(xp: 40));
      final r = GameLogic.toggleQuest(s, 'bo_move'); // +25
      expect(r.trackLevelUps, ['body']);
      expect(r.state.progress('body').level, 2);
      expect(r.state.progress('body').xp, 15);

      s = GameLogic.toggleQuest(r.state, 'bo_move').state;
      expect(s.progress('body').level, 1);
      expect(s.progress('body').xp, 40);
    });

    test('ignores quests of inactive tracks', () {
      final s = game(tracks: ['mind']);
      final r = GameLogic.toggleQuest(s, 'ap_open');
      expect(r.state.completedToday, isEmpty);
    });

    test('ignores unknown quest ids', () {
      final s = game();
      expect(GameLogic.toggleQuest(s, 'nope').state.completedToday, isEmpty);
    });

    test('reports a Master Level up', () {
      // One track: master = 1 + (level − 1) ÷ 4. Level 4 → 5 makes it 2.
      var s = game(tracks: ['body']);
      s = withProgress(s, 'body', const TrackProgress(level: 4, xp: 70));
      // Body L4 needs 80. +25 → level 5.
      final r = GameLogic.toggleQuest(s, 'bo_move');
      expect(r.masterLevelBefore, 1);
      expect(r.masterLevelAfter, 2);
      expect(r.masterLeveledUp, isTrue);
    });
  });

  group('rollover', () {
    test('does nothing on the same day', () {
      final s = game();
      final r = GameLogic.rollover(s, day1);
      expect(r.rolledOver, isFalse);
      expect(identical(r.state, s), isTrue);
    });

    test('missed dailies cost 5 XP each, meditation 3, hobbies 0', () {
      var s = game(tracks: ['auto_parts', 'mind', 'hobbies']);
      s = withProgress(s, 'auto_parts', const TrackProgress(level: 2, xp: 100));
      s = withProgress(s, 'mind', const TrackProgress(level: 2, xp: 100));
      s = withProgress(s, 'hobbies', const TrackProgress(level: 2, xp: 100));
      final r = GameLogic.rollover(s, day1.addDays(1));
      expect(r.state.progress('auto_parts').xp, 85); // 3 dailies × 5
      expect(r.state.progress('mind').xp, 92); // meditate 3 + read 5
      expect(r.state.progress('hobbies').xp, 100);
      expect(r.report!.xpLost, {'auto_parts': 15, 'mind': 8});
    });

    test('penalty never costs a level', () {
      var s = game(tracks: ['auto_parts']);
      s = withProgress(s, 'auto_parts', const TrackProgress(level: 4, xp: 3));
      final r = GameLogic.rollover(s, day1.addDays(1));
      expect(r.state.progress('auto_parts').level, 4);
      expect(r.state.progress('auto_parts').xp, 0);
      expect(r.report!.xpLost['auto_parts'], 3);
    });

    test('completed dailies grow the streak and skip the penalty', () {
      var s = game(tracks: ['mind']);
      s = tickAll(s, ['mi_meditate', 'mi_read']);
      final r = GameLogic.rollover(s, day1.addDays(1));
      final p = r.state.progress('mind');
      expect(p.streak, 1);
      expect(p.bestStreak, 1);
      expect(p.xp, 35);
      expect(r.report!.xpLost, isEmpty);
      expect(r.report!.streaksKept, ['mind']);
    });

    test('side quests alone do not keep a streak', () {
      var s = game(tracks: ['mind']);
      s = withProgress(
        s,
        'mind',
        const TrackProgress(streak: 3, bestStreak: 3),
      );
      s = tickAll(s, ['mi_learn', 'mi_read']);
      final r = GameLogic.rollover(s, day1.addDays(1));
      expect(r.state.progress('mind').streak, 0);
      expect(r.state.progress('mind').bestStreak, 3);
      expect(r.report!.streaksBroken, ['mind']);
    });

    test('hobbies streak counts any hobbies quest', () {
      var s = game(tracks: ['hobbies']);
      s = tickAll(s, ['ho_new']);
      final r = GameLogic.rollover(s, day1.addDays(1));
      expect(r.state.progress('hobbies').streak, 1);
    });

    test('starts a fresh day', () {
      var s = game();
      s = tickAll(s, ['ap_open']);
      final r = GameLogic.rollover(s, day1.addDays(1));
      expect(r.state.today, day1.addDays(1));
      expect(r.state.completedToday, isEmpty);
      expect(r.state.dayStartTracks, r.state.tracks);
      expect(r.state.pendingReport, isNotNull);
      // Yesterday's XP is locked in: ticking again on the new day adds more.
      final t = GameLogic.toggleQuest(r.state, 'ap_open').state;
      expect(t.progress('auto_parts').xp, 20 + 30); // 30 − 5 − 5, then +30
    });

    test('scores at most 7 missed days after a long absence', () {
      var s = game(tracks: ['auto_parts']);
      s = withProgress(s, 'auto_parts', const TrackProgress(level: 5, xp: 200));
      final r = GameLogic.rollover(s, day1.addDays(30));
      expect(r.report!.daysAway, 30);
      expect(r.report!.daysScored, 7);
      expect(r.state.progress('auto_parts').xp, 200 - 7 * 15);
    });

    test('two days away scores both days', () {
      var s = game(tracks: ['mind']);
      s = tickAll(s, ['mi_meditate', 'mi_read']); // xp 35, streak kept day 1
      final r = GameLogic.rollover(s, day1.addDays(2));
      expect(r.report!.daysScored, 2);
      // Day 2 missed: −8, streak broken after growing to 1.
      expect(r.state.progress('mind').xp, 27);
      expect(r.state.progress('mind').streak, 0);
      expect(r.state.progress('mind').bestStreak, 1);
      expect(r.report!.streaksBroken, ['mind']);
      expect(r.report!.streaksKept, isEmpty);
    });

    test('month and year boundaries', () {
      expect(const Day(2026, 12, 31).addDays(1), const Day(2027, 1, 1));
      expect(const Day(2026, 3, 28).daysUntil(const Day(2026, 4, 2)), 5);
    });
  });

  test('daily progress counts active tracks only', () {
    var s = game(tracks: ['mind', 'body']);
    s = tickAll(s, ['mi_read', 'bo_water', 'bo_sleep']);
    expect(GameLogic.dailyProgress(s), (2, 4));
  });

  test('JSON round trip', () {
    var s = game();
    s = tickAll(s, ['ap_open', 'bo_move']);
    s = GameLogic.rollover(s, day1.addDays(1)).state;
    s = tickAll(s, ['mi_read']);
    final back = GameState.fromJson(s.toJson());
    expect(back.toJson(), s.toJson());
    expect(back.pendingReport!.newDay, day1.addDays(1));
  });
}
