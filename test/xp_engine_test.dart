import 'package:flutter_test/flutter_test.dart';
import 'package:life_leveling/core/xp_engine.dart';

void main() {
  group('xpToNext', () {
    test('base × (1 + level × 0.25), rounded', () {
      expect(XpEngine.xpToNext(100, 1), 125);
      expect(XpEngine.xpToNext(100, 2), 150);
      expect(XpEngine.xpToNext(40, 1), 50);
      expect(XpEngine.xpToNext(45, 1), 56); // 56.25
      expect(XpEngine.xpToNext(45, 2), 68); // 67.5 rounds up
      expect(XpEngine.xpToNext(60, 3), 105);
    });
  });

  group('addXp', () {
    test('stays in level below the threshold', () {
      final p = XpEngine.addXp(const TrackProgress(), 49, 40);
      expect(p.level, 1);
      expect(p.xp, 49);
    });

    test('levels up and carries the rest', () {
      final p = XpEngine.addXp(const TrackProgress(), 55, 40);
      expect(p.level, 2);
      expect(p.xp, 5);
    });

    test('can roll over several levels at once', () {
      // base 40: L1→2 needs 50, L2→3 needs 60. 115 = 50 + 60 + 5.
      final p = XpEngine.addXp(const TrackProgress(), 115, 40);
      expect(p.level, 3);
      expect(p.xp, 5);
    });

    test('keeps streak fields', () {
      final p = XpEngine.addXp(
        const TrackProgress(streak: 4, bestStreak: 9),
        10,
        40,
      );
      expect(p.streak, 4);
      expect(p.bestStreak, 9);
    });
  });

  group('removeXp', () {
    test('drops XP within a level', () {
      final p = XpEngine.removeXp(const TrackProgress(level: 3, xp: 20), 5);
      expect(p.level, 3);
      expect(p.xp, 15);
    });

    test('never goes below 0 and never loses a level', () {
      final p = XpEngine.removeXp(const TrackProgress(level: 3, xp: 2), 5);
      expect(p.level, 3);
      expect(p.xp, 0);
    });
  });

  group('multipliers', () {
    test('stack', () {
      expect(XpEngine.totalMultiplier([1.5, 2]), 3.0);
      expect(XpEngine.applyMultipliers(20, [1.5, 2]), 60);
    });

    test('cap at 4x total', () {
      expect(XpEngine.totalMultiplier([2, 2, 2]), 4.0);
      expect(XpEngine.applyMultipliers(25, [3, 3]), 100);
    });

    test('none means 1x', () {
      expect(XpEngine.totalMultiplier(const []), 1.0);
    });
  });

  group('master level', () {
    test('1 + sum(level − 1) ÷ 4, floored', () {
      expect(XpEngine.rawMasterLevel([1, 1, 1, 1]), 1);
      expect(XpEngine.rawMasterLevel([2, 2, 2, 1]), 1);
      expect(XpEngine.rawMasterLevel([2, 2, 2, 2]), 2);
      expect(XpEngine.rawMasterLevel([5, 4, 1, 1]), 2);
    });

    test('balance gate at 10 caps at 9 when a track is below 3', () {
      // Sum of (level − 1) = 37 → raw 10, but one track sits at 2.
      final levels = [20, 18, 2];
      expect(XpEngine.rawMasterLevel(levels), 10);
      expect(XpEngine.masterLevel(levels), 9);
      expect(XpEngine.blockingGate(levels)?.masterLevel, 10);
    });

    test('gate passes when every track meets it', () {
      final levels = [19, 18, 3];
      expect(XpEngine.masterLevel(levels), 10);
      expect(XpEngine.blockingGate(levels), isNull);
    });

    test('gate at 20 needs every track at 7', () {
      // Sum 82 → raw 21. Lowest 6 → capped at 19.
      expect(XpEngine.masterLevel([40, 39, 6]), 19);
      expect(XpEngine.masterLevel([39, 39, 7]), 21);
    });

    test('no tracks is level 1', () {
      expect(XpEngine.masterLevel(const []), 1);
    });
  });

  test('hunter rank boundaries', () {
    expect(XpEngine.hunterRank(1), 'E');
    expect(XpEngine.hunterRank(9), 'E');
    expect(XpEngine.hunterRank(10), 'D');
    expect(XpEngine.hunterRank(24), 'D');
    expect(XpEngine.hunterRank(25), 'C');
    expect(XpEngine.hunterRank(44), 'C');
    expect(XpEngine.hunterRank(45), 'B');
    expect(XpEngine.hunterRank(69), 'B');
    expect(XpEngine.hunterRank(70), 'A');
    expect(XpEngine.hunterRank(99), 'A');
    expect(XpEngine.hunterRank(100), 'S');
    expect(XpEngine.hunterRank(149), 'S');
    expect(XpEngine.hunterRank(150), 'National');
  });
}
