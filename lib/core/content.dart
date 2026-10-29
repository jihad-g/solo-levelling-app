/// The 8 tracks and every quest with its XP. Tune numbers here.
library;

class TrackDef {
  final String id;
  final String name;
  final String blurb;

  /// XP base for the level curve (see XpEngine.xpToNext).
  final int base;

  /// Hobbies: the streak counts any completed quest instead of all dailies.
  final bool streakOnAnyQuest;

  const TrackDef({
    required this.id,
    required this.name,
    required this.blurb,
    required this.base,
    this.streakOnAnyQuest = false,
  });
}

class QuestDef {
  final String id;
  final String trackId;
  final String title;
  final int xp;
  final bool daily;

  /// XP lost when a daily is missed. Side quests never penalize.
  final int missPenalty;

  const QuestDef({
    required this.id,
    required this.trackId,
    required this.title,
    required this.xp,
    this.daily = false,
    int? missPenalty,
  }) : missPenalty = daily ? (missPenalty ?? Content.defaultMissPenalty) : 0;
}

class Content {
  Content._();

  static const int defaultMissPenalty = 5;

  /// At most this many missed days are scored after a long absence.
  static const int maxMissedDaysScored = 7;

  static const List<TrackDef> tracks = [
    TrackDef(
      id: 'auto_parts',
      name: 'Auto Parts',
      blurb: 'The shop, 9am to 11pm',
      base: 100,
    ),
    TrackDef(
      id: 'private_label',
      name: 'Private Label',
      blurb: 'Your own ignition coil brand',
      base: 60,
    ),
    TrackDef(
      id: 'repair_shop',
      name: 'Repair Shop',
      blurb: 'Building the modern repair shop',
      base: 60,
    ),
    TrackDef(
      id: 'car_business',
      name: 'Car Business',
      blurb: 'Copart / IAAI imports to Libya',
      base: 45,
    ),
    TrackDef(
      id: 'printing_3d',
      name: '3D Printing',
      blurb: 'The printing partnership',
      base: 45,
    ),
    TrackDef(
      id: 'mind',
      name: 'Mind',
      blurb: 'Focus, calm, learning',
      base: 45,
    ),
    TrackDef(id: 'body', name: 'Body', blurb: 'Strength and health', base: 40),
    TrackDef(
      id: 'hobbies',
      name: 'Hobbies',
      blurb: 'Things you do for fun',
      base: 40,
      streakOnAnyQuest: true,
    ),
  ];

  static const List<QuestDef> quests = [
    // Auto Parts
    QuestDef(
      id: 'ap_open',
      trackId: 'auto_parts',
      title: 'Open on time and walk the stock',
      xp: 30,
      daily: true,
    ),
    QuestDef(
      id: 'ap_sales',
      trackId: 'auto_parts',
      title: "Log today's sales and cash",
      xp: 25,
      daily: true,
    ),
    QuestDef(
      id: 'ap_follow',
      trackId: 'auto_parts',
      title: 'Follow up one supplier or customer',
      xp: 20,
      daily: true,
    ),
    QuestDef(
      id: 'ap_restock',
      trackId: 'auto_parts',
      title: 'Place a restock order',
      xp: 40,
    ),
    QuestDef(
      id: 'ap_shelf',
      trackId: 'auto_parts',
      title: 'Reorganize one shelf section',
      xp: 30,
    ),
    QuestDef(
      id: 'ap_deal',
      trackId: 'auto_parts',
      title: 'Negotiate a better price with a supplier',
      xp: 60,
    ),

    // Private Label
    QuestDef(
      id: 'pl_work',
      trackId: 'private_label',
      title: '30 minutes on the coil brand',
      xp: 25,
      daily: true,
    ),
    QuestDef(
      id: 'pl_quote',
      trackId: 'private_label',
      title: 'Get a quote from a manufacturer',
      xp: 50,
    ),
    QuestDef(
      id: 'pl_pack',
      trackId: 'private_label',
      title: 'Improve the label or packaging',
      xp: 40,
    ),
    QuestDef(
      id: 'pl_post',
      trackId: 'private_label',
      title: 'Post brand content online',
      xp: 30,
    ),

    // Repair Shop
    QuestDef(
      id: 'rs_step',
      trackId: 'repair_shop',
      title: 'One setup step (research, visit, budget)',
      xp: 20,
      daily: true,
    ),
    QuestDef(
      id: 'rs_equip',
      trackId: 'repair_shop',
      title: 'Price one piece of equipment',
      xp: 30,
    ),
    QuestDef(
      id: 'rs_place',
      trackId: 'repair_shop',
      title: 'Visit a possible location',
      xp: 50,
    ),
    QuestDef(
      id: 'rs_hire',
      trackId: 'repair_shop',
      title: 'Talk to a mechanic you might hire',
      xp: 40,
    ),

    // Car Business
    QuestDef(
      id: 'cb_scan',
      trackId: 'car_business',
      title: 'Scan Copart / IAAI listings',
      xp: 20,
      daily: true,
    ),
    QuestDef(
      id: 'cb_bid',
      trackId: 'car_business',
      title: 'Place a bid',
      xp: 40,
    ),
    QuestDef(
      id: 'cb_ship',
      trackId: 'car_business',
      title: 'Update shipping and customs tracker',
      xp: 25,
    ),
    QuestDef(
      id: 'cb_sell',
      trackId: 'car_business',
      title: 'Sell a car',
      xp: 100,
    ),

    // 3D Printing
    QuestDef(
      id: 'pr_check',
      trackId: 'printing_3d',
      title: 'Check in on the print queue / partner',
      xp: 15,
      daily: true,
    ),
    QuestDef(
      id: 'pr_job',
      trackId: 'printing_3d',
      title: 'Finish a print job',
      xp: 35,
    ),
    QuestDef(
      id: 'pr_model',
      trackId: 'printing_3d',
      title: 'Design a new part model',
      xp: 45,
    ),

    // Mind
    QuestDef(
      id: 'mi_meditate',
      trackId: 'mind',
      title: 'Meditate 10 minutes',
      xp: 15,
      daily: true,
      missPenalty: 3,
    ),
    QuestDef(
      id: 'mi_read',
      trackId: 'mind',
      title: 'Read 10 pages',
      xp: 20,
      daily: true,
    ),
    QuestDef(
      id: 'mi_learn',
      trackId: 'mind',
      title: 'Learn something new for 30 minutes',
      xp: 30,
    ),

    // Body
    QuestDef(
      id: 'bo_move',
      trackId: 'body',
      title: 'Workout or 30 minute walk',
      xp: 25,
      daily: true,
    ),
    QuestDef(
      id: 'bo_water',
      trackId: 'body',
      title: 'Drink 2 liters of water',
      xp: 10,
      daily: true,
    ),
    QuestDef(id: 'bo_sleep', trackId: 'body', title: 'Sleep 7 hours', xp: 15),
    QuestDef(id: 'bo_weigh', trackId: 'body', title: 'Weigh in', xp: 10),

    // Hobbies (dailies never penalize here)
    QuestDef(
      id: 'ho_time',
      trackId: 'hobbies',
      title: '20 minutes on a hobby',
      xp: 20,
      daily: true,
      missPenalty: 0,
    ),
    QuestDef(
      id: 'ho_new',
      trackId: 'hobbies',
      title: 'Try something new',
      xp: 30,
    ),
  ];

  static final Map<String, TrackDef> _trackById = {
    for (final t in tracks) t.id: t,
  };
  static final Map<String, QuestDef> _questById = {
    for (final q in quests) q.id: q,
  };

  static TrackDef track(String id) => _trackById[id]!;
  static QuestDef? quest(String id) => _questById[id];

  static List<QuestDef> questsFor(String trackId) =>
      quests.where((q) => q.trackId == trackId).toList();

  static List<QuestDef> dailiesFor(String trackId) =>
      quests.where((q) => q.trackId == trackId && q.daily).toList();

  static List<String> get allTrackIds => tracks.map((t) => t.id).toList();
}
