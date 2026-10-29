/// GameState and its JSON form.
library;

import 'xp_engine.dart';

/// A calendar day with no time part, stored as 'yyyy-MM-dd'.
class Day implements Comparable<Day> {
  final int year;
  final int month;
  final int day;

  const Day(this.year, this.month, this.day);

  factory Day.fromDateTime(DateTime t) => Day(t.year, t.month, t.day);

  factory Day.parse(String s) {
    final parts = s.split('-').map(int.parse).toList();
    return Day(parts[0], parts[1], parts[2]);
  }

  DateTime get _utc => DateTime.utc(year, month, day);

  /// Whole days from this day to [other] (positive when [other] is later).
  /// Uses UTC so daylight saving can't shift the count.
  int daysUntil(Day other) => other._utc.difference(_utc).inDays;

  Day addDays(int n) => Day.fromDateTime(_utc.add(Duration(days: n)));

  @override
  int compareTo(Day other) => _utc.compareTo(other._utc);

  bool isAfter(Day other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is Day &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}

/// What happened at the last daily reset, shown in the
/// "[ Daily Quest has arrived ]" window.
class DayReport {
  final Day newDay;

  /// How many past days were scored (1 normally, up to 7 after an absence).
  final int daysScored;

  /// Total days since the last open, including ones not scored.
  final int daysAway;

  /// XP actually lost per track (after the never-below-zero clamp).
  final Map<String, int> xpLost;

  /// Tracks that completed their dailies on the scored day(s) and grew a streak.
  final List<String> streaksKept;

  /// Tracks whose streak was reset to 0.
  final List<String> streaksBroken;

  const DayReport({
    required this.newDay,
    required this.daysScored,
    required this.daysAway,
    this.xpLost = const {},
    this.streaksKept = const [],
    this.streaksBroken = const [],
  });

  int get totalXpLost => xpLost.values.fold(0, (a, b) => a + b);

  Map<String, dynamic> toJson() => {
    'newDay': newDay.toString(),
    'daysScored': daysScored,
    'daysAway': daysAway,
    'xpLost': xpLost,
    'streaksKept': streaksKept,
    'streaksBroken': streaksBroken,
  };

  factory DayReport.fromJson(Map<String, dynamic> j) => DayReport(
    newDay: Day.parse(j['newDay'] as String),
    daysScored: (j['daysScored'] as num).toInt(),
    daysAway:
        (j['daysAway'] as num?)?.toInt() ?? (j['daysScored'] as num).toInt(),
    xpLost: (j['xpLost'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    ),
    streaksKept: List<String>.from(j['streaksKept'] as List? ?? const []),
    streaksBroken: List<String>.from(j['streaksBroken'] as List? ?? const []),
  );
}

class GameState {
  static const int schemaVersion = 1;

  final String playerName;
  final double? weightKg;
  final List<String> activeTracks;

  /// Live progress, including today's completed quests.
  final Map<String, TrackProgress> tracks;

  /// Progress as it was when today started. Today's progress is always
  /// replayed from this, so un-ticking a quest undoes it exactly.
  final Map<String, TrackProgress> dayStartTracks;

  final Day today;

  /// Quest ids completed today, in the order they were ticked.
  final List<String> completedToday;

  /// Set at each daily reset; cleared once the window has been shown.
  final DayReport? pendingReport;

  final Day startedOn;

  const GameState({
    required this.playerName,
    required this.weightKg,
    required this.activeTracks,
    required this.tracks,
    required this.dayStartTracks,
    required this.today,
    required this.completedToday,
    required this.startedOn,
    this.pendingReport,
  });

  GameState copyWith({
    String? playerName,
    double? weightKg,
    List<String>? activeTracks,
    Map<String, TrackProgress>? tracks,
    Map<String, TrackProgress>? dayStartTracks,
    Day? today,
    List<String>? completedToday,
    DayReport? pendingReport,
    bool clearReport = false,
  }) => GameState(
    playerName: playerName ?? this.playerName,
    weightKg: weightKg ?? this.weightKg,
    activeTracks: activeTracks ?? this.activeTracks,
    tracks: tracks ?? this.tracks,
    dayStartTracks: dayStartTracks ?? this.dayStartTracks,
    today: today ?? this.today,
    completedToday: completedToday ?? this.completedToday,
    startedOn: startedOn,
    pendingReport: clearReport ? null : (pendingReport ?? this.pendingReport),
  );

  TrackProgress progress(String trackId) =>
      tracks[trackId] ?? const TrackProgress();

  List<int> get activeLevels =>
      activeTracks.map((id) => progress(id).level).toList();

  int get masterLevel => XpEngine.masterLevel(activeLevels);

  String get hunterRank => XpEngine.hunterRank(masterLevel);

  bool isDone(String questId) => completedToday.contains(questId);

  static Map<String, dynamic> _tracksToJson(Map<String, TrackProgress> m) =>
      m.map((k, v) => MapEntry(k, v.toJson()));

  static Map<String, TrackProgress> _tracksFromJson(Object? o) =>
      (o as Map<String, dynamic>? ?? {}).map(
        (k, v) =>
            MapEntry(k, TrackProgress.fromJson(v as Map<String, dynamic>)),
      );

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'playerName': playerName,
    'weightKg': weightKg,
    'activeTracks': activeTracks,
    'tracks': _tracksToJson(tracks),
    'dayStartTracks': _tracksToJson(dayStartTracks),
    'today': today.toString(),
    'completedToday': completedToday,
    'startedOn': startedOn.toString(),
    'pendingReport': pendingReport?.toJson(),
  };

  factory GameState.fromJson(Map<String, dynamic> j) => GameState(
    playerName: j['playerName'] as String? ?? 'Player',
    weightKg: (j['weightKg'] as num?)?.toDouble(),
    activeTracks: List<String>.from(j['activeTracks'] as List),
    tracks: _tracksFromJson(j['tracks']),
    dayStartTracks: _tracksFromJson(j['dayStartTracks']),
    today: Day.parse(j['today'] as String),
    completedToday: List<String>.from(j['completedToday'] as List? ?? const []),
    startedOn: Day.parse((j['startedOn'] ?? j['today']) as String),
    pendingReport: j['pendingReport'] == null
        ? null
        : DayReport.fromJson(j['pendingReport'] as Map<String, dynamic>),
  );
}
