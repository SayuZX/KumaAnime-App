import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import '../../../../core/auth/providers/auth_provider.dart';
import '../badges/badge_chip.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        Widget avatarWidget;
        if (user.avatar != null && user.avatar!.startsWith('http')) {
          avatarWidget = CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(user.avatar!),
          );
        } else if (user.avatar != null && user.avatar!.startsWith('data:image')) {
          try {
            final base64Str = user.avatar!.split(',').last;
            final bytes = base64Decode(base64Str);
            avatarWidget = CircleAvatar(
              radius: 40,
              backgroundImage: MemoryImage(bytes),
            );
          } catch (_) {
            avatarWidget = const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40));
          }
        } else {
          avatarWidget = const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40));
        }

        final joinedDate = DateFormat.yMMMM().format(user.createdAt);

        return Card(
          elevation: 0,
          color: appTheme.backgroundColor.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatarWidget,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nickname,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Joined $joinedDate',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                      if (user.badges.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.badges.map((b) => BadgeChip(badge: b)).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
