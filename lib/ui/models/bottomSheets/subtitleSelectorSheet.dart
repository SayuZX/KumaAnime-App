import 'package:flutter/material.dart';
import 'package:kumaanime/controllers/subtitle_controller.dart';
import 'package:kumaanime/ui/pages/settingPages/subtitle.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/ui/models/widgets/player/playerUtils.dart';
import 'package:kumaanime/ui/models/providers/playerProvider.dart';
import 'package:flutter/services.dart';

class SubtitleSelectorSheet extends StatelessWidget {
  final SubtitleController controller;
  final PlayerProvider playerProvider;
  final VoidCallback onSettingsChanged;

  const SubtitleSelectorSheet({
    super.key,
    required this.controller,
    required this.playerProvider,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      color: appTheme.textMainColor,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: appTheme.modalSheetBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Subtitle (Beta)",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: appTheme.textMainColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => const SubtitleSettingPage(fromWatchPage: true),
                    ),
                  ).then((_) {
                    onSettingsChanged();
                    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                    SystemChrome.setPreferredOrientations(watchPreferredOrientations());
                  });
                },
                icon: Icon(Icons.settings_outlined, color: appTheme.accentColor),
                tooltip: "Pengaturan Subtitle",
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLanguageTile(
            context: context,
            label: "Off",
            isSelected: controller.selectedTrack == null,
            onTap: () {
              controller.changeTrack(null);
              if (playerProvider.state.showSubs) {
                playerProvider.toggleSubs();
              }
              Navigator.pop(context);
            },
            textStyle: textStyle,
          ),
          const Divider(height: 24, color: Colors.white24),
          if (controller.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.availableTracks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  "Subtitle tidak tersedia untuk episode ini",
                  style: theme.textTheme.bodyMedium?.copyWith(color: appTheme.textSubColor),
                ),
              ),
            )
          else
            ...controller.availableTracks.map((track) {
              final isSelected = controller.selectedTrack?.url == track.url;
              return _buildLanguageTile(
                context: context,
                label: track.language,
                subtitle: track.format.toUpperCase(),
                isSelected: isSelected,
                onTap: () {
                  controller.changeTrack(track);
                  if (!playerProvider.state.showSubs) {
                    playerProvider.toggleSubs();
                  }
                  Navigator.pop(context);
                },
                textStyle: textStyle,
              );
            }),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildLanguageTile({
    required BuildContext context,
    required String label,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    TextStyle? textStyle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? appTheme.accentColor.withValues(alpha: 0.15) : appTheme.backgroundSubColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? appTheme.accentColor : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        title: Text(
          label,
          style: textStyle?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: appTheme.textSubColor, fontSize: 12),
              )
            : null,
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: appTheme.accentColor)
            : Icon(Icons.circle_outlined, color: appTheme.textSubColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
