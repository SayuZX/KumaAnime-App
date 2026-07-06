import 'dart:convert';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/social/rankSystem.dart';
import 'package:kumaanime/core/social/socialService.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:kumaanime/core/auth/providers/auth_provider.dart';
import 'package:kumaanime/ui/models/widgets/profile/profile_card.dart';
import 'package:kumaanime/ui/models/widgets/dialogs/account_linking_dialog.dart';
import 'package:kumaanime/core/auth/services/account_linking_service.dart';

class AccountSetting extends StatefulWidget {
  const AccountSetting({super.key});

  @override
  State<AccountSetting> createState() => _AccountSettingState();
}

class _AccountSettingState extends State<AccountSetting> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              settingPagesTitleHeader(context, loc.accountTitle),
              _authSection(),
              _rankSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _authSection() {
    final loc = AppLocalizations.of(context);
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          margin: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: Text('Authentication', style: textStyle().copyWith(fontSize: 24)),
              ),
              const ProfileCard(),
              const SizedBox(height: 16),
              if (authProvider.isAnonymous)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleLogin(authProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appTheme.accentColor,
                      foregroundColor: appTheme.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(loc.authLoginContributor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _handleLogout(authProvider),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(loc.authLogout, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogin(AuthProvider auth) async {
    final strategy = await showAccountLinkingDialog(context);
    if (strategy == null || strategy == LinkStrategy.continueAsGuest) return;

    try {
      await auth.loginWithAuth0();
      await auth.linkAccount(strategy);
      if (mounted) floatingSnackBar('Successfully logged in!');
    } catch (e) {
      if (mounted) floatingSnackBar('Login failed: $e');
    }
  }

  Future<void> _handleLogout(AuthProvider auth) async {
    try {
      await auth.logout();
      if (mounted) floatingSnackBar('Logged out successfully.');
    } catch (e) {
      if (mounted) floatingSnackBar('Logout failed: $e');
    }
  }

  Widget _rankSection() {
    final loc = AppLocalizations.of(context);
    final social = SocialService.instance;
    if (!social.isReady || social.accountCreatedAt == null) return const SizedBox.shrink();

    final ageDays = social.accountAgeDays;
    final episodes = social.episodesWatched;

    final timeRank = RankSystem.current(RankSystem.timeRanks, ageDays);
    final timeNext = RankSystem.next(RankSystem.timeRanks, ageDays);
    final activityRank = RankSystem.current(RankSystem.activityRanks, episodes);
    final activityNext = RankSystem.next(RankSystem.activityRanks, episodes);
    final achieved = RankSystem.timeRankAchievedOn(social.accountCreatedAt!, ageDays);
    final badges = RankSystem.earnedBadges(ageDays: ageDays, granted: social.grantedBadges);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: Text(loc.accountRankTitle, style: textStyle().copyWith(fontSize: 24)),
          ),
          _rankTile(
            emoji: timeRank.emoji,
            title: timeRank.name,
            subtitle: loc.accountRankAchievedOn(_formatDate(achieved, loc)),
            progress: RankSystem.progress(RankSystem.timeRanks, ageDays),
            footer: timeNext != null
                ? loc.accountRankTimeNext(timeNext.emoji, timeNext.name, timeNext.threshold - ageDays)
                : loc.accountRankTimeMax,
          ),
          const SizedBox(height: 14),
          _rankTile(
            emoji: activityRank.emoji,
            title: activityRank.name,
            subtitle: loc.accountEpisodesWatched(episodes),
            progress: RankSystem.progress(RankSystem.activityRanks, episodes),
            footer: activityNext != null
                ? loc.accountRankActivityNext(activityNext.emoji, activityNext.name, activityNext.threshold - episodes)
                : loc.accountRankActivityMax,
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(loc.accountBadge, style: TextStyle(color: appTheme.textMainColor, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: badges.map(_badgeChip).toList()),
          ],
        ],
      ),
    );
  }

  Widget _rankTile({
    required String emoji,
    required String title,
    required String subtitle,
    required double progress,
    required String footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(color: appTheme.textMainColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: appTheme.textSubColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: appTheme.backgroundColor,
              valueColor: AlwaysStoppedAnimation(appTheme.accentColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(footer, style: TextStyle(color: appTheme.textSubColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _badgeChip(BadgeDef badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(badge.name, style: TextStyle(color: appTheme.textMainColor, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, AppLocalizations loc) {
    final months = [
      loc.accountMonthJan,
      loc.accountMonthFeb,
      loc.accountMonthMar,
      loc.accountMonthApr,
      loc.accountMonthMay,
      loc.accountMonthJun,
      loc.accountMonthJul,
      loc.accountMonthAug,
      loc.accountMonthSep,
      loc.accountMonthOct,
      loc.accountMonthNov,
      loc.accountMonthDec,
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }
}
