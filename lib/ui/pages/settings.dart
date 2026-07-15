import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/pages/settingPages/account.dart';
import 'package:kumaanime/ui/pages/settingPages/appInfo.dart';
import 'package:kumaanime/ui/pages/settingPages/appearance.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/ui/pages/settingPages/content.dart';
import 'package:kumaanime/ui/pages/settingPages/general.dart';
import 'package:kumaanime/ui/pages/settingPages/notifications.dart';
import 'package:kumaanime/ui/pages/settingPages/playback.dart';
import 'package:kumaanime/ui/pages/settingPages/storage.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class SettingsPage extends StatefulWidget {
  final bool isTab;
  const SettingsPage({super.key, this.isTab = false});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class SettingItem {
  final IconData icon;
  final String label;
  final Widget navigateTo;
  final String description;

  SettingItem({
    required this.icon,
    required this.label,
    required this.navigateTo,
    required this.description,
  });
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final accountGroup = [
      SettingItem(
        icon: HugeIcons.strokeRoundedUser,
        label: loc.settingsAccount,
        description: loc.settingsAccountDesc,
        navigateTo: const AccountSetting(),
      ),
      SettingItem(
        icon: Icons.palette_outlined,
        label: loc.settingsAppearance,
        description: loc.settingsAppearanceDesc,
        navigateTo: const AppearanceSetting(),
      ),
    ];

    final mediaGroup = [
      SettingItem(
        icon: Icons.play_circle_outline_rounded,
        label: loc.settingsPlayback,
        description: loc.settingsPlaybackDesc,
        navigateTo: const PlaybackSetting(),
      ),
      SettingItem(
        icon: HugeIcons.strokeRoundedTranslate,
        label: loc.settingsContent,
        description: loc.settingsContentDesc,
        navigateTo: const ContentSetting(),
      ),
    ];

    final systemGroup = [
      SettingItem(
        icon: HugeIcons.strokeRoundedNotification03,
        label: loc.settingsNotifications,
        description: loc.settingsNotificationsDesc,
        navigateTo: const NotificationSetting(),
      ),
      SettingItem(
        icon: HugeIcons.strokeRoundedDatabase,
        label: loc.settingsStorage,
        description: loc.settingsStorageDesc,
        navigateTo: const StorageSetting(),
      ),
      SettingItem(
        icon: HugeIcons.strokeRoundedSettings01,
        label: loc.settingsGeneral,
        description: loc.settingsGeneralDesc,
        navigateTo: const GeneralSetting(),
      ),
      SettingItem(
        icon: Icons.info_outline_rounded,
        label: loc.settingsAppInfo,
        description: loc.settingsAppInfoDesc,
        navigateTo: const AppInfoSetting(),
      ),
    ];

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      appBar: widget.isTab ? null : settingPagesAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isTab)
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 10),
                child: Text(
                  loc.settingsTitle,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: appTheme.textMainColor,
                  ),
                ),
              ),
            _buildSettingsGroup('ACCOUNT & CUSTOMIZATION', accountGroup),
            _buildSettingsGroup('PREFERENCES & MEDIA', mediaGroup),
            _buildSettingsGroup('SYSTEM & INFO', systemGroup),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<SettingItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                color: appTheme.textSubColor.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: appTheme.backgroundSubColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (currentUserSettings?.darkMode ?? true ? Colors.white : Colors.black)
                    .withValues(alpha: 0.05),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 72,
                endIndent: 16,
                color: (currentUserSettings?.darkMode ?? true ? Colors.white : Colors.black)
                    .withValues(alpha: 0.06),
              ),
              itemBuilder: (context, index) => _buildSettingTile(context, items[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, SettingItem item) {
    final isLight = appTheme.backgroundColor.computeLuminance() > 0.5;
    final iconColor = isLight
        ? Color.alphaBlend(Colors.black.withValues(alpha: 0.42), appTheme.accentColor)
        : appTheme.accentColor;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, anim, anim2) => item.navigateTo,
            transitionDuration: const Duration(milliseconds: 120),
            reverseTransitionDuration: const Duration(milliseconds: 120),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ).then((_) {
          if (mounted) setState(() {});
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: appTheme.accentColor.withValues(alpha: isLight ? 0.22 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: appTheme.textMainColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: appTheme.textSubColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: appTheme.textSubColor.withValues(alpha: 0.6),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
