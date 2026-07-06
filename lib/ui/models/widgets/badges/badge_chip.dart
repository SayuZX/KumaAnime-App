import 'package:flutter/material.dart';
import '../../../../core/auth/models/user_badge.dart';

class BadgeChip extends StatelessWidget {
  final UserBadge badge;
  final bool showLabel;

  const BadgeChip({
    super.key,
    required this.badge,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.displayLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badge.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badge.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              badge.icon,
              size: 14,
              color: badge.color,
            ),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                badge.displayLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: badge.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
