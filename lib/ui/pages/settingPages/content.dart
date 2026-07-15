import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/settings.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/ui/models/providers/appProvider.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ContentSetting extends StatefulWidget {
  const ContentSetting({super.key});

  @override
  State<ContentSetting> createState() => _ContentSettingState();
}

class _ContentSettingState extends State<ContentSetting> {
  static const _keys = ['locale', 'showAdultContent', 'blockedGenres'];

  static const _languageNames = {'en': 'English', 'id': 'Bahasa Indonesia'};

  static const _commonGenres = [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Ecchi',
    'Fantasy',
    'Horror',
    'Romance',
    'Sci-Fi',
    'Slice of Life',
    'Sports',
    'Supernatural',
  ];

  Future<void> _write(SettingsModal settings) async {
    await Settings().writeSettings(settings);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final s = currentUserSettings;
    final blocked = s?.blockedGenres ?? [];
    final isDark = currentUserSettings?.darkMode ?? true;

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: buildFluentSettingsBody(
        child: SingleChildScrollView(
          child: Padding(
            padding: pagePadding(context, bottom: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                settingPagesTitleHeader(context, loc.ctContentAndLanguage),

                buildFluentSettingsSectionHeader(loc.ctContentAndLanguage),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: buildFluentSettingsCard(
                    children: [
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.language_rounded,
                        title: loc.ctLanguage,
                        description: _languageNames[s?.locale] ?? _languageNames['en']!,
                        trailing: Icon(Icons.arrow_drop_down, color: appTheme.textSubColor),
                        onTap: () => _showLanguageSheet(s?.locale ?? 'en'),
                      ),
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.no_adult_content_rounded,
                        title: loc.ctShowAdultContent,
                        description: loc.ctRequiresAgeVerification,
                        trailing: Switch(
                          value: s?.showAdultContent ?? false,
                          onChanged: (val) => _toggleAdult(s?.showAdultContent ?? false),
                        ),
                      ),
                    ],
                  ),
                ),

                buildFluentSettingsSectionHeader(loc.ctBlockedGenres),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonGenres.map((g) {
                      final isBlocked = blocked.contains(g);
                      return GestureDetector(
                        onTap: () {
                          final next = List<String>.from(blocked);
                          isBlocked ? next.remove(g) : next.add(g);
                          _write(SettingsModal(blockedGenres: next));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isBlocked ? appTheme.accentColor : appTheme.backgroundSubColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isBlocked) ...[
                                Icon(Icons.block_rounded, size: 14, color: appTheme.onAccent),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                g,
                                style: TextStyle(
                                  color: isBlocked ? appTheme.onAccent : appTheme.textMainColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                resetCategoryButton(context, loc.ctResetContent, () async {
                  await Settings().resetKeys(_keys);
                  if (mounted) setState(() {});
                  floatingSnackBar(loc.ctContentSettingsReset);
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleAdult(bool current) {
    final loc = AppLocalizations.of(context);
    if (current) {
      _write(SettingsModal(showAdultContent: false));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appTheme.modalSheetBackgroundColor,
        title: Text(loc.ctAgeVerification, style: TextStyle(color: appTheme.textMainColor)),
        content: Text(loc.ctAgeVerificationBody,
            style: TextStyle(color: appTheme.textSubColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.ctCancel)),
          TextButton(
            onPressed: () {
              _write(SettingsModal(showAdultContent: true));
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: appTheme.accentColor),
            child: Text(loc.ctIAm18Plus),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(String current) {
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
              child: Text(loc.ctSelectLanguage, style: textStyle().copyWith(fontSize: 22)),
            ),
            ..._languageNames.entries.map((e) => optionTile(
                  label: e.value,
                  selected: e.key == current,
                  onTap: () async {
                    await Settings().writeSettings(SettingsModal(locale: e.key));
                    context.read<AppProvider>().justRefresh();
                    if (mounted) setState(() {});
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
