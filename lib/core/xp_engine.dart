/// All leveling math for Life Leveling. Pure Dart, no Flutter imports.
library;

/// A track's progress: its level and the XP collected inside that level.
class TrackProgress {
  final int level;
  final int xp;
  final int streak;
  final int bestStreak;

  const TrackProgress({
    this.level = 1,
    this.xp = 0,
    this.streak = 0,
    this.bestStreak = 0,
  });

  TrackProgress copyWith({int? level, int? xp, int? streak, int? bestStreak}) =>
      TrackProgress(
        level: level ?? this.level,
        xp: xp ?? this.xp,
        streak: streak ?? this.streak,
        bestStreak: bestStreak ?? this.bestStreak,
      );

  Map<String, dynamic> toJson() => {
    'level': level,
    'xp': xp,
    'streak': streak,
    'bestStreak': bestStreak,
  };

  factory TrackProgress.fromJson(Map<String, dynamic> j) => TrackProgress(
    level: (j['level'] as num?)?.toInt() ?? 1,
    xp: (j['xp'] as num?)?.toInt() ?? 0,
    streak: (j['streak'] as num?)?.toInt() ?? 0,
    bestStreak: (j['bestStreak'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      other is TrackProgress &&
      other.level == level &&
      other.xp == xp &&
      other.streak == streak &&
      other.bestStreak == bestStreak;

  @override
  int get hashCode => Object.hash(level, xp, streak, bestStreak);

  @override
  String toString() =>
      'TrackProgress(L$level, $xp xp, streak $streak, best $bestStreak)';
}

/// A balance gate: reaching [masterLevel] needs every active track at
/// [minTrackLevel] or higher.
class BalanceGate {
  final int masterLevel;
  final int minTrackLevel;
  const BalanceGate(this.masterLevel, this.minTrackLevel);
}

class XpEngine {
  XpEngine._();

  static const double maxMultiplier = 4.0;

  static const List<BalanceGate> gates = [
    BalanceGate(10, 3),
    BalanceGate(20, 7),
    BalanceGate(30, 12),
    BalanceGate(50, 20),
    BalanceGate(100, 40),
  ];

  /// XP needed to go from [level] to level + 1: base × (1 + level × 0.25).
  static int xpToNext(int base, int level) =>
      (base * (1 + level * 0.25)).round();

  /// Adds [amount] XP (may be 0) and rolls over as many levels as it fills.
  static TrackProgress addXp(TrackProgress p, int amount, int base) {
    if (amount <= 0) return p;
    var level = p.level;
    var xp = p.xp + amount;
    while (xp >= xpToNext(base, level)) {
      xp -= xpToNext(base, level);
      level++;
    }
    return p.copyWith(level: level, xp: xp);
  }

  /// Removes XP. XP can drop to 0 within a level but never below: a level
  /// is never lost.
  static TrackProgress removeXp(TrackProgress p, int amount) {
    if (amount <= 0) return p;
    final xp = p.xp - amount;
    return p.copyWith(xp: xp < 0 ? 0 : xp);
  }

  /// Multipliers stack (multiply) but the total is capped at 4x.
  static double totalMultiplier(Iterable<double> multipliers) {
    var total = 1.0;
    for (final m in multipliers) {
      total *= m;
    }
    return total > maxMultiplier ? maxMultiplier : total;
  }

  static int applyMultipliers(int xp, Iterable<double> multipliers) =>
      (xp * totalMultiplier(multipliers)).round();

  /// Master Level before gates: 1 + (sum of (track level − 1)) ÷ 4, floored.
  static int rawMasterLevel(Iterable<int> trackLevels) {
    var sum = 0;
    for (final l in trackLevels) {
      sum += l - 1;
    }
    return 1 + sum ~/ 4;
  }

  /// Master Level with balance gates applied. The first gate whose track
  /// requirement isn't met caps the Master Level just below it.
  static int masterLevel(Iterable<int> activeTrackLevels) {
    final gate = blockingGate(activeTrackLevels);
    if (gate != null) return gate.masterLevel - 1;
    final levels = activeTrackLevels.toList();
    return levels.isEmpty ? 1 : rawMasterLevel(levels);
  }

  /// The gate currently holding the Master Level back, if any.
  static BalanceGate? blockingGate(Iterable<int> activeTrackLevels) {
    final levels = activeTrackLevels.toList();
    if (levels.isEmpty) return null;
    final raw = rawMasterLevel(levels);
    final lowest = levels.reduce((a, b) => a < b ? a : b);
    for (final g in gates) {
      if (raw >= g.masterLevel && lowest < g.minTrackLevel) return g;
    }
    return null;
  }

  /// Hunter Rank by Master Level.
  static String hunterRank(int masterLevel) {
    if (masterLevel >= 150) return 'National';
    if (masterLevel >= 100) return 'S';
    if (masterLevel >= 70) return 'A';
    if (masterLevel >= 45) return 'B';
    if (masterLevel >= 25) return 'C';
    if (masterLevel >= 10) return 'D';
    return 'E';
  }
}
