import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/social/rankSystem.dart';
import 'package:kumaanime/core/social/socialService.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AccountSetting extends StatefulWidget {
  const AccountSetting({super.key});

  @override
  State<AccountSetting> createState() => _AccountSettingState();
}

class _AccountSettingState extends State<AccountSetting> {
  static const _avatars = ['😺', '🦊', '🐼', '🐯', '🐧', '🐨', '🦁', '🐸', '🐙', '👾', '🍥', '⭐'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              settingPagesTitleHeader(context, "Account"),
              _communityProfileCard(),
              _rankSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _communityProfileCard() {
    final social = SocialService.instance;
    final avatar = social.avatar;
    final nickname = social.nickname;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: Text("Community Profile", style: textStyle().copyWith(fontSize: 24)),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: appTheme.accentColor.withValues(alpha: 0.2),
                  backgroundImage: avatar.startsWith('http') ? NetworkImage(avatar) : null,
                  child: avatar.startsWith('http')
                      ? null
                      : Text(
                          avatar.isNotEmpty ? avatar : (nickname.isNotEmpty ? nickname[0].toUpperCase() : "?"),
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
                      Text(nickname,
                          style: TextStyle(color: appTheme.textMainColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        social.isReady ? "Nama tampil di komentar & like" : "Fitur sosial tidak tersedia",
                        style: TextStyle(color: appTheme.textSubColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: social.isReady ? _editProfile : null,
                  icon: Icon(Icons.edit_rounded, color: appTheme.accentColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editProfile() {
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
          padding: EdgeInsets.only(left: 20, right: 20, top: 6, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Edit Profil", style: textStyle().copyWith(fontSize: 22)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLength: 24,
                style: TextStyle(color: appTheme.textMainColor),
                decoration: InputDecoration(
                  labelText: "Username",
                  labelStyle: TextStyle(color: appTheme.textSubColor),
                  filled: true,
                  fillColor: appTheme.backgroundSubColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: uploading
                      ? null
                      : () async {
                          final picked =
                              await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 100);
                          if (picked == null) return;
                          setSheet(() => uploading = true);
                          final url = await social.uploadAvatar(picked.path);
                          if (!mounted) return;
                          if (url != null) {
                            Navigator.pop(ctx);
                            setState(() {});
                            floatingSnackBar("Foto profil diperbarui");
                          } else {
                            setSheet(() => uploading = false);
                            floatingSnackBar("Gagal mengunggah foto");
                          }
                        },
                  icon: uploading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: appTheme.accentColor),
                        )
                      : const Icon(Icons.photo_library_rounded),
                  label: Text(uploading ? "Mengunggah..." : "Upload foto (maks 2MB)"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: appTheme.accentColor,
                    side: BorderSide(color: appTheme.accentColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text("Atau pilih ikon", style: TextStyle(color: appTheme.textMainColor, fontWeight: FontWeight.bold)),
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
                        color: isSelected ? appTheme.accentColor.withValues(alpha: 0.18) : appTheme.backgroundSubColor,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: appTheme.accentColor, width: 2) : null,
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
                    await social.saveProfile(nickname: name.isEmpty ? social.nickname : name, avatar: selected);
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    setState(() {});
                    floatingSnackBar("Profil disimpan");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.accentColor,
                    foregroundColor: appTheme.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Simpan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rankSection() {
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
            child: Text("Rank & Pencapaian", style: textStyle().copyWith(fontSize: 24)),
          ),
          _rankTile(
            emoji: timeRank.emoji,
            title: timeRank.name,
            subtitle: "Tercapai ${_formatDate(achieved)}",
            progress: RankSystem.progress(RankSystem.timeRanks, ageDays),
            footer: timeNext != null
                ? "Menuju ${timeNext.emoji} ${timeNext.name} • ${timeNext.threshold - ageDays} hari lagi"
                : "Rank waktu tertinggi tercapai 🎉",
          ),
          const SizedBox(height: 14),
          _rankTile(
            emoji: activityRank.emoji,
            title: activityRank.name,
            subtitle: "$episodes episode ditonton",
            progress: RankSystem.progress(RankSystem.activityRanks, episodes),
            footer: activityNext != null
                ? "Menuju ${activityNext.emoji} ${activityNext.name} • ${activityNext.threshold - episodes} episode lagi"
                : "Rank aktivitas tertinggi tercapai 🎉",
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text("Badge", style: TextStyle(color: appTheme.textMainColor, fontSize: 16, fontWeight: FontWeight.bold)),
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

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }
}
