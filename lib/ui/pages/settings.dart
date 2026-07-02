import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/pages/settingPages/account.dart';
import 'package:kumaanime/ui/pages/settingPages/appInfo.dart';
import 'package:kumaanime/ui/pages/settingPages/appearance.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/ui/pages/settingPages/general.dart';
import 'package:kumaanime/ui/pages/settingPages/player.dart';
import 'package:kumaanime/ui/pages/settingPages/ui.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

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
    final settingItems = [
      SettingItem(
          icon: Icons.account_circle,
          label: loc.settingsAccount,
          description: loc.settingsAccountDesc,
          navigateTo: AccountSetting()),
      SettingItem(
          icon: Icons.brush_rounded, label: loc.settingsUi, description: loc.settingsUiDesc, navigateTo: ThemeSetting()),
      SettingItem(
          icon: Icons.palette_outlined,
          label: "Appearance",
          description: "Accent, font, text size & layout",
          navigateTo: AppearanceSetting()),
      SettingItem(
          icon: Icons.play_circle_fill_rounded,
          label: loc.settingsPlayer,
          description: loc.settingsPlayerDesc,
          navigateTo: PlayerSetting()),
      SettingItem(
          icon: Icons.tune_rounded,
          label: loc.settingsGeneral,
          description: loc.settingsGeneralDesc,
          navigateTo: GeneralSetting()),
      SettingItem(
          icon: Icons.info_outline_rounded,
          label: loc.settingsAppInfo,
          description: loc.settingsAppInfoDesc,
          navigateTo: AppInfoSetting())
    ];
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      appBar: settingPagesAppBar(context),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(left: MediaQuery.of(context).padding.left),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 24),
                child: Text(
                  loc.settingsTitle,
                  style: TextStyle(
                    fontFamily: "Rubik",
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: appTheme.textMainColor,
                  ),
                ),
              ),
              ...settingItems.map((item) => _settingTile(context, item)),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingTile(BuildContext context, SettingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: appTheme.backgroundSubColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: appTheme.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: appTheme.accentColor, size: 22),
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
                          fontFamily: "NotoSans",
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: appTheme.textMainColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: TextStyle(fontFamily: "NunitoSans", fontSize: 13, color: appTheme.textSubColor),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: appTheme.textSubColor, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
