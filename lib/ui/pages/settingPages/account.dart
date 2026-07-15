import 'dart:convert';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/social/rankSystem.dart';
import 'package:kumaanime/core/social/socialService.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hugeicons/hugeicons.dart';

class AccountSetting extends StatefulWidget {
  const AccountSetting({super.key});

  @override
  State<AccountSetting> createState() => _AccountSettingState();
}

class _AccountSettingState extends State<AccountSetting> {
  static const _avatars = [
    '😺',
    '🦊',
    '🐼',
    '🐯',
    '🐧',
    '🐨',
    '🦁',
    '🐸',
    '🐙',
    '👾',
    '🍥',
    '⭐'
  ];

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
              _communityProfileCard(),
              _rankSection(),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _avatarImage(String avatar) {
    if (avatar.startsWith('data:'))
      return MemoryImage(base64Decode(avatar.split(',').last));
    if (avatar.startsWith('http')) return NetworkImage(avatar);
    return null;
  }

  Widget _communityProfileCard() {
    final loc = AppLocalizations.of(context);
    final social = SocialService.instance;
    final avatar = social.avatar;
    final nickname = social.nickname;
    final isDark = currentUserSettings?.darkMode ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              loc.accountCommunityProfile.toUpperCase(),
              style: TextStyle(
                color: appTheme.textSubColor.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appTheme.backgroundSubColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: appTheme.accentColor.withValues(alpha: 0.2),
                  backgroundImage: _avatarImage(avatar),
                  child: _avatarImage(avatar) != null
                      ? null
                      : Text(
                          avatar.isNotEmpty
                              ? avatar
                              : (nickname.isNotEmpty
                                  ? nickname[0].toUpperCase()
                                  : "?"),
                          style: TextStyle(
                            color: appTheme.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: avatar.isNotEmpty ? 26 : 20,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: TextStyle(
                          color: appTheme.textMainColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        social.isReady
                            ? loc.accountNameShownHint
                            : loc.accountSocialUnavailable,
                        style: TextStyle(
                          color: appTheme.textSubColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: social.isReady ? _editProfile : null,
                  icon: Icon(
                    HugeIcons.strokeRoundedEdit02,
                    color: appTheme.accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editProfile() {
    final loc = AppLocalizations.of(context);
    final social = SocialService.instance;
    final controller = TextEditingController(text: social.nickname);
    String selected = social.avatar;
    bool uploading = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 6,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.accountEditProfile,
                  style: textStyle().copyWith(fontSize: 22)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLength: 24,
                style: TextStyle(color: appTheme.textMainColor),
                decoration: InputDecoration(
                  labelText: loc.accountUsername,
                  labelStyle: TextStyle(color: appTheme.textSubColor),
                  filled: true,
                  fillColor: appTheme.backgroundSubColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: uploading
                      ? null
                      : () async {
                          try {
                            final picked = await ImagePicker().pickImage(
                                source: ImageSource.gallery, imageQuality: 100);
                            if (picked == null) return;
                            setSheet(() => uploading = true);
                            final url = await social.uploadAvatar(picked.path);
                            if (!mounted) return;
                            if (url != null) {
                              Navigator.pop(ctx);
                              setState(() {});
                              floatingSnackBar(loc.accountPhotoUpdated);
                            } else {
                              setSheet(() => uploading = false);
                              floatingSnackBar(loc.accountPhotoUploadFailed);
                            }
                          } catch (e) {
                            if (mounted) setSheet(() => uploading = false);
                            floatingSnackBar(
                                loc.accountGalleryError(e.toString()));
                          }
                        },
                  icon: uploading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: appTheme.accentColor),
                        )
                      : const Icon(Icons.photo_library_rounded),
                  label: Text(uploading
                      ? loc.accountUploading
                      : loc.accountUploadPhoto),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: appTheme.accentColor,
                    side: BorderSide(color: appTheme.accentColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(loc.accountOrPickIcon,
                  style: TextStyle(
                      color: appTheme.textMainColor,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _avatars.map((emoji) {
                  final isSelected = selected == emoji;
                  return GestureDetector(
                    onTap: () => setSheet(() => selected = emoji),
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? appTheme.accentColor.withValues(alpha: 0.18)
                            : appTheme.backgroundSubColor,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: appTheme.accentColor, width: 2)
                            : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    await social.saveProfile(
                        nickname: name.isEmpty ? social.nickname : name,
                        avatar: selected);
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    setState(() {});
                    floatingSnackBar(loc.accountProfileSaved);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.accentColor,
                    foregroundColor: appTheme.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(loc.accountSave,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rankSection() {
    final loc = AppLocalizations.of(context);
    final social = SocialService.instance;
    if (!social.isReady || social.accountCreatedAt == null)
      return const SizedBox.shrink();

    final ageDays = social.accountAgeDays;
    final episodes = social.episodesWatched;

    final timeRank = RankSystem.current(RankSystem.timeRanks, ageDays);
    final timeNext = RankSystem.next(RankSystem.timeRanks, ageDays);
    final activityRank = RankSystem.current(RankSystem.activityRanks, episodes);
    final activityNext = RankSystem.next(RankSystem.activityRanks, episodes);
    final achieved =
        RankSystem.timeRankAchievedOn(social.accountCreatedAt!, ageDays);
    final badges = RankSystem.earnedBadges(
        ageDays: ageDays, granted: social.grantedBadges);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              loc.accountRankTitle.toUpperCase(),
              style: TextStyle(
                color: appTheme.textSubColor.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _rankTile(
            emoji: timeRank.emoji,
            title: timeRank.name,
            subtitle: loc.accountRankAchievedOn(_formatDate(achieved, loc)),
            progress: RankSystem.progress(RankSystem.timeRanks, ageDays),
            footer: timeNext != null
                ? loc.accountRankTimeNext(
                    timeNext.emoji, timeNext.name, timeNext.threshold - ageDays)
                : loc.accountRankTimeMax,
          ),
          const SizedBox(height: 14),
          _rankTile(
            emoji: activityRank.emoji,
            title: activityRank.name,
            subtitle: loc.accountEpisodesWatched(episodes),
            progress: RankSystem.progress(RankSystem.activityRanks, episodes),
            footer: activityNext != null
                ? loc.accountRankActivityNext(activityNext.emoji,
                    activityNext.name, activityNext.threshold - episodes)
                : loc.accountRankActivityMax,
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 8),
              child: Text(
                loc.accountBadge.toUpperCase(),
                style: TextStyle(
                  color: appTheme.textSubColor.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: badges.map(_badgeChip).toList()),
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
    final isDark = currentUserSettings?.darkMode ?? true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appTheme.backgroundSubColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        ),
      ),
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
                        style: TextStyle(
                            color: appTheme.textMainColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: appTheme.textSubColor, fontSize: 12)),
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
          Text(footer,
              style: TextStyle(color: appTheme.textSubColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _badgeChip(BadgeDef badge) {
    final isDark = currentUserSettings?.darkMode ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: appTheme.backgroundSubColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(badge.name,
              style: TextStyle(color: appTheme.textMainColor, fontSize: 13)),
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
