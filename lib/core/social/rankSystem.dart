class RankTier {
  final String name;
  final String emoji;
  final int threshold;

  const RankTier(this.name, this.emoji, this.threshold);
}

class BadgeDef {
  final String id;
  final String name;
  final String emoji;
  final String description;

  const BadgeDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
  });
}

class RankSystem {
  static const List<RankTier> timeRanks = [
    RankTier('Newbie Otaku', '🌱', 0),
    RankTier('Anime Explorer', '🍜', 7),
    RankTier('Seasonal Watcher', '📺', 30),
    RankTier('Otaku', '⭐', 90),
    RankTier('Anime Enthusiast', '🔥', 180),
    RankTier('Senpai', '👑', 365),
    RankTier('Anime Veteran', '🏯', 730),
    RankTier('Anime Legend', '🐉', 1095),
  ];

  static const List<RankTier> activityRanks = [
    RankTier('Newbie', '🌱', 0),
    RankTier('Casual Viewer', '🍜', 10),
    RankTier('Anime Fan', '📺', 100),
    RankTier('Otaku', '🔥', 500),
    RankTier('Senpai', '👑', 1000),
    RankTier('Anime Legend', '🐉', 3000),
  ];

  static const List<BadgeDef> loyaltyBadges = [
    BadgeDef(id: 'member_1m', name: 'Member 1 Bulan', emoji: '🎉', description: 'Terdaftar selama 1 bulan'),
    BadgeDef(id: 'member_1y', name: 'Member 1 Tahun', emoji: '🎂', description: 'Terdaftar selama 1 tahun'),
  ];

  static const List<BadgeDef> specialBadges = [
    BadgeDef(id: 'founding', name: 'Founding Member', emoji: '🏆', description: 'Pengguna awal aplikasi'),
    BadgeDef(id: 'early_supporter', name: 'Early Supporter', emoji: '🌸', description: 'Pendukung awal'),
    BadgeDef(id: 'beta_tester', name: 'Beta Tester', emoji: '🚀', description: 'Ikut menguji versi beta'),
  ];

  static const List<BadgeDef> eventBadges = [];

  static int currentIndex(List<RankTier> ranks, int value) {
    int index = 0;
    for (int i = 0; i < ranks.length; i++) {
      if (value >= ranks[i].threshold) index = i;
    }
    return index;
  }

  static RankTier current(List<RankTier> ranks, int value) => ranks[currentIndex(ranks, value)];

  static RankTier? next(List<RankTier> ranks, int value) {
    final index = currentIndex(ranks, value);
    return index + 1 < ranks.length ? ranks[index + 1] : null;
  }

  static double progress(List<RankTier> ranks, int value) {
    final index = currentIndex(ranks, value);
    if (index + 1 >= ranks.length) return 1.0;
    final start = ranks[index].threshold;
    final end = ranks[index + 1].threshold;
    if (end <= start) return 1.0;
    return ((value - start) / (end - start)).clamp(0.0, 1.0);
  }

  static DateTime timeRankAchievedOn(DateTime createdAt, int ageDays) {
    final tier = current(timeRanks, ageDays);
    return createdAt.add(Duration(days: tier.threshold));
  }

  static List<BadgeDef> earnedBadges({required int ageDays, required Set<String> granted}) {
    final earned = <BadgeDef>[];
    if (ageDays >= 30) earned.add(loyaltyBadges[0]);
    if (ageDays >= 365) earned.add(loyaltyBadges[1]);
    for (final badge in [...specialBadges, ...eventBadges]) {
      if (granted.contains(badge.id)) earned.add(badge);
    }
    return earned;
  }
}
