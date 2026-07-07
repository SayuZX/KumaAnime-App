import 'package:flutter/material.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/misc.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class BetaAnnouncementDialog extends StatelessWidget {
  final String version;

  const BetaAnnouncementDialog({
    super.key,
    required this.version,
  });

  static Future<void> showBetaAnnouncementDialogIfNeeded(
      BuildContext context, String currentVersion) async {
    // Check if the version contains 'beta' (case-insensitive)
    if (!currentVersion.toLowerCase().contains('beta')) {
      return;
    }

    final dynamic savedVersion = await getMiscVal("beta_banner_shown_version");

    if (savedVersion == null || savedVersion != currentVersion) {
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => BetaAnnouncementDialog(version: currentVersion),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: appTheme.modalSheetBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      icon: Icon(
        Icons.rocket_launch_outlined,
        color: appTheme.accentColor,
        size: 40,
      ),
      title: Text(
        loc.betaAnnouncementTitle,
        style: TextStyle(
          color: appTheme.textMainColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.betaAnnouncementBody,
              style: TextStyle(
                color: appTheme.textSubColor,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Version: $version",
              style: TextStyle(
                color: appTheme.textSubColor.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowButtonSpacing: 8,
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                await storeMiscVal("beta_banner_shown_version", version);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.accentColor,
                foregroundColor: appTheme.onAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                loc.betaAnnouncementContinue,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await storeMiscVal("beta_banner_shown_version", version);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: appTheme.textSubColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                loc.betaAnnouncementDontShow,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
