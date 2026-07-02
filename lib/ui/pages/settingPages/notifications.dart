import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/settings.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/clickableItem.dart';
import 'package:kumaanime/ui/models/widgets/toggleItem.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class NotificationSetting extends StatefulWidget {
  const NotificationSetting({super.key});

  @override
  State<NotificationSetting> createState() => _NotificationSettingState();
}

class _NotificationSettingState extends State<NotificationSetting> {
  static const _keys = ['notifyNewEpisode', 'notifyNews', 'updateCheckFrequency', 'notifyDownloadComplete'];
  static const _frequencies = ['off', 'daily', 'weekly'];

  Future<void> _write(SettingsModal settings) async {
    await Settings().writeSettings(settings);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final s = currentUserSettings;
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: pagePadding(context, bottom: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              settingPagesTitleHeader(context, loc.ntfNotifications),
              ToggleItem(
                label: loc.ntfNewEpisodeAlerts,
                description: loc.ntfNewEpisodeAlertsDesc,
                value: s?.notifyNewEpisode ?? false,
                onTapFunction: () => _write(SettingsModal(notifyNewEpisode: !(s?.notifyNewEpisode ?? false))),
              ),
              ToggleItem(
                label: loc.ntfAnimeNews,
                description: loc.ntfAnimeNewsDesc,
                value: s?.notifyNews ?? false,
                onTapFunction: () => _write(SettingsModal(notifyNews: !(s?.notifyNews ?? false))),
              ),
              ToggleItem(
                label: loc.ntfDownloadComplete,
                value: s?.notifyDownloadComplete ?? true,
                onTapFunction: () =>
                    _write(SettingsModal(notifyDownloadComplete: !(s?.notifyDownloadComplete ?? true))),
              ),
              ClickableItem(
                onTap: () => _showFrequencySheet(s?.updateCheckFrequency ?? 'off'),
                label: loc.ntfBackgroundUpdateCheck,
                description: (s?.updateCheckFrequency ?? 'off').toUpperCase(),
                suffixIcon: Icon(Icons.arrow_drop_down, color: appTheme.textMainColor),
              ),
              const SizedBox(height: 20),
              resetCategoryButton(context, loc.ntfResetNotifications, () async {
                await Settings().resetKeys(_keys);
                if (mounted) setState(() {});
                floatingSnackBar(loc.ntfNotificationsReset);
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showFrequencySheet(String current) {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(context).padding.bottom + 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 8),
              child: Text(loc.ntfCheckFrequency, style: textStyle().copyWith(fontSize: 22)),
            ),
            ..._frequencies.map((f) => optionTile(
                  label: f.toUpperCase(),
                  selected: f == current,
                  onTap: () {
                    _write(SettingsModal(updateCheckFrequency: f));
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
