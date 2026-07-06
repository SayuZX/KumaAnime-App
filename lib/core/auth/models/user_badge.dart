import 'package:flutter/material.dart';

enum UserBadge {
  betaTester('BETA_TESTER', 'Beta Tester', Color(0xFF9C27B0), Icons.bug_report),
  contributor('CONTRIBUTOR', 'Contributor', Color(0xFF4CAF50), Icons.code),
  developer('DEVELOPER', 'Developer', Color(0xFF2196F3), Icons.terminal),
  translator('TRANSLATOR', 'Translator', Color(0xFFFF9800), Icons.translate),
  moderator('MODERATOR', 'Moderator', Color(0xFFF44336), Icons.shield),
  earlySupporter('EARLY_SUPPORTER', 'Early Supporter', Color(0xFFE91E63), Icons.favorite),
  vip('VIP', 'VIP', Color(0xFFFFD700), Icons.star),
  donator('DONATOR', 'Donator', Color(0xFF00BCD4), Icons.volunteer_activism);

  final String firestoreKey;
  final String displayLabel;
  final Color color;
  final IconData icon;

  const UserBadge(this.firestoreKey, this.displayLabel, this.color, this.icon);

  static UserBadge? fromString(String key) {
    try {
      return UserBadge.values.firstWhere((b) => b.firestoreKey == key);
    } catch (_) {
      return null;
    }
  }

  static List<UserBadge> fromList(List<dynamic>? keys) {
    if (keys == null) return [];
    return keys
        .map((k) => fromString(k.toString()))
        .whereType<UserBadge>()
        .toList();
  }
}
