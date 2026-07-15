import 'dart:io';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/settings.dart';
import 'package:kumaanime/core/data/theme.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/ui/theme/themes.dart';
import 'package:kumaanime/ui/theme/types.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/providers/appProvider.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/themeTransition.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppearanceSetting extends StatefulWidget {
  const AppearanceSetting({super.key});

  @override
  State<AppearanceSetting> createState() => _AppearanceSettingState();
}

class _AppearanceSettingState extends State<AppearanceSetting> {
  int? _currentThemeId;
  bool _isAboveAndroid12 = true;

  @override
  void initState() {
    super.initState();
    getTheme().then((value) {
      if (mounted) setState(() => _currentThemeId = value);
    });
    if (Platform.isAndroid) {
      DeviceInfoPlugin().androidInfo.then((val) => _isAboveAndroid12 = val.version.sdkInt >= 31);
    }
  }

  static const _keys = [
    'accentColorValue',
    'fontFamily',
    'textScale',
    'reduceMotion',
    'listLayout',
    'cardScale',
    'heroBlur',
    'amoledBackground',
  ];

  static const _accentSwatches = [
    0xffCAF979,
    0xff00C897,
    0xffE50914,
    0xff2196F3,
    0xff9C27B0,
    0xffFF9800,
    0xffFF4081,
    0xff4CAF50,
    0xffFFC107,
    0xff00BCD4,
    0xff7C4DFF,
    0xffFFFFFF,
  ];

  static const _fonts = ['NotoSans', 'Rubik', 'Poppins', 'Inter', 'OpenSans', 'NunitoSans'];
  static const _layouts = ['grid', 'list', 'compact'];

  Future<void> _write(SettingsModal settings) async {
    await Settings().writeSettings(settings);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = currentUserSettings;
    final appProvider = context.read<AppProvider>();
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: pagePadding(context, bottom: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              settingPagesTitleHeader(context, loc.settingsAppearance),
              _sectionLabel(loc.uiThemeMode),
              _themeModeRow(appProvider),
              _sectionLabel("Visual Customization"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: buildFluentSettingsCard(
                  children: [
                    buildFluentSettingsTile(
                      context: context,
                      icon: Icons.palette_outlined,
                      title: loc.uiMaterialTheme,
                      description: loc.uiMaterialThemeDesc,
                      trailing: Switch(
                        value: s?.materialTheme ?? false,
                        onChanged: (val) async {
                          if (!_isAboveAndroid12) return floatingSnackBar(loc.uiAndroid12Required);
                          await _write(SettingsModal(materialTheme: val));
                          if (val) return appProvider.justRefresh();
                          appProvider.applyThemeMode(appProvider.isDark);
                        },
                      ),
                    ),
                    buildFluentSettingsTile(
                      context: context,
                      icon: Icons.title_rounded,
                      title: loc.uiPreferNativeTitles,
                      trailing: Switch(
                        value: s?.nativeTitle ?? false,
                        onChanged: (val) async {
                          await _write(SettingsModal(nativeTitle: val));
                          appProvider.justRefresh();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              _sectionLabel(loc.uiThemes),
              _themePicker(appProvider),
              _sectionLabel(loc.apAccentColor),
              _accentGrid(appProvider, s?.accentColorValue),
              _sectionLabel(loc.apFont),
              _fontList(appProvider, s?.fontFamily ?? 'NotoSans'),
              _sectionLabel(loc.apTextSize),
              _scaleSlider(
                value: s?.textScale ?? 1.0,
                min: 0.8,
                max: 1.4,
                onChanged: (v) async {
                  await _write(SettingsModal(textScale: v));
                  appProvider.justRefresh();
                },
              ),
              _sectionLabel(loc.apAnimeListLayout),
              _layoutChips(loc, s?.listLayout ?? 'grid'),
              _sectionLabel(loc.apCardSize),
              _cardSizeChips(loc, s?.cardScale ?? 1.0),
              _sectionLabel(loc.uiNavbarTransparency),
              _scaleSlider(
                value: s?.navbarTranslucency ?? 0.6,
                min: 0.0,
                max: 1.0,
                onChanged: (v) async {
                  await _write(SettingsModal(navbarTranslucency: v));
                  appProvider.justRefresh();
                },
              ),
              _sectionLabel("Additional Enhancements"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: buildFluentSettingsCard(
                  children: [
                    buildFluentSettingsTile(
                      context: context,
                      icon: Icons.navigation_rounded,
                      title: loc.apLiquidNavbar,
                      description: loc.apLiquidNavbarDesc,
                      trailing: Switch(
                        value: !(s?.useOldNavbar ?? false),
                        onChanged: (val) async {
                          await _write(SettingsModal(useOldNavbar: !val));
                          appProvider.justRefresh();
                        },
                      ),
                    ),
                    buildFluentSettingsTile(
                      context: context,
                      icon: Icons.brightness_2_rounded,
                      title: loc.apAmoledBlack,
                      description: loc.apAmoledBlackDesc,
                      trailing: Switch(
                        value: s?.amoledBackground ?? false,
                        onChanged: (val) async {
                          await _write(SettingsModal(amoledBackground: val));
                          appProvider.applyThemeMode(appProvider.isDark);
                        },
                      ),
                    ),
                    buildFluentSettingsTile(
                      context: context,
                      icon: Icons.blur_on_rounded,
                      title: loc.apBlurHero,
                      trailing: Switch(
                        value: s?.heroBlur ?? true,
                        onChanged: (val) async {
                          await _write(SettingsModal(heroBlur: val));
                        },
                      ),
                    ),
                    buildFluentSettingsTile(
                      context: context,
                      icon: Icons.motion_photos_off_rounded,
                      title: loc.apReduceMotion,
                      description: loc.apReduceMotionDesc,
                      trailing: Switch(
                        value: s?.reduceMotion ?? false,
                        onChanged: (val) async {
                          await _write(SettingsModal(reduceMotion: val));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _resetButton(loc, appProvider),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeModeRow(AppProvider appProvider) {
    final dark = currentUserSettings?.darkMode ?? true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Builder(
        builder: (buttonContext) => SegmentedButton(
        segments: [
          ButtonSegment(
              value: false,
              icon: Icon(Icons.wb_sunny_rounded, color: !dark ? appTheme.onAccent : appTheme.textMainColor)),
          ButtonSegment(
              value: true,
              icon: Icon(Icons.nights_stay_rounded, color: dark ? appTheme.onAccent : appTheme.textMainColor)),
        ],
        selected: {dark},
        multiSelectionEnabled: false,
        showSelectedIcon: false,
        emptySelectionAllowed: false,
        onSelectionChanged: (val) async {
          await ThemeTransition.run(buttonContext, () async {
            await _write(SettingsModal(darkMode: val.first));
            await appProvider.applyThemeMode(val.first);
          });
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: appTheme.accentColor,
          selectedForegroundColor: appTheme.onAccent,
          foregroundColor: appTheme.textMainColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        ),
      ),
    );
  }

  Widget _themePicker(AppProvider appProvider) {
    return SizedBox(
      height: 92,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: availableThemes.length,
        itemBuilder: (context, index) {
          final ThemeItem item = availableThemes[index];
          final selected = _currentThemeId == item.id;
          return GestureDetector(
            onTap: () async {
              await setTheme(item.id);
              final dark = currentUserSettings?.darkMode ?? true;
              appProvider.applyTheme(dark ? item.theme : item.lightVariant);
              if (mounted) setState(() => _currentThemeId = item.id);
            },
            child: Container(
              width: 84,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appTheme.backgroundSubColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? item.theme.accentColor : Colors.transparent, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: item.theme.accentColor, shape: BoxShape.circle),
                    child: selected ? Icon(Icons.check_rounded, color: item.theme.onAccent, size: 20) : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: appTheme.textMainColor, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 26, right: 20, top: 24, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: appTheme.textSubColor.withValues(alpha: 0.6),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _accentGrid(AppProvider appProvider, int? selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _accentSwatches.map((argb) {
          final isSelected = selected == argb;
          return GestureDetector(
            onTap: () {
              _write(SettingsModal(accentColorValue: argb));
              appProvider.applyAccentColor(argb);
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Color(argb),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? appTheme.textMainColor : Colors.transparent,
                  width: 3,
                ),
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.black, size: 20) : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _fontList(AppProvider appProvider, String selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: buildFluentSettingsCard(
        children: _fonts.map((font) {
          final isSelected = font == selected;
          return buildFluentSettingsTile(
            context: context,
            icon: Icons.font_download_outlined,
            title: font,
            description: "Aa Kuma Anime",
            trailing: isSelected
                ? Icon(Icons.check_rounded, color: appTheme.accentColor, size: 20)
                : null,
            onTap: () {
              _write(SettingsModal(fontFamily: font));
              appProvider.justRefresh();
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _scaleSlider({
    required double value,
    required double min,
    required double max,
    required void Function(double) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) * 10).round(),
            activeColor: appTheme.accentColor,
            label: "${(value * 100).round()}%",
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Text("${(value * 100).round()}%", style: TextStyle(color: appTheme.textSubColor)),
        ),
      ],
    );
  }

  Widget _cardSizeChips(AppLocalizations loc, double current) {
    final sizes = {loc.sizeSmall: 0.9, loc.sizeMedium: 1.0, loc.sizeLarge: 1.15};
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: sizes.entries.map((entry) {
          final selected = (current - entry.value).abs() < 0.03;
          return Expanded(
            child: GestureDetector(
              onTap: () => _write(SettingsModal(cardScale: entry.value)),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? appTheme.accentColor : appTheme.backgroundSubColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: selected ? appTheme.onAccent : appTheme.textMainColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _layoutChips(AppLocalizations loc, String selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _layouts.map((layout) {
          final isSelected = layout == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => _write(SettingsModal(listLayout: layout)),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? appTheme.accentColor : appTheme.backgroundSubColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  {'grid': loc.layoutGrid, 'list': loc.layoutList, 'compact': loc.layoutCompact}[layout] ?? layout,
                  style: TextStyle(
                    color: isSelected ? appTheme.onAccent : appTheme.textMainColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _resetButton(AppLocalizations loc, AppProvider appProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            await Settings().resetKeys(_keys);
            await setTheme(availableThemes[0].id);
            await appProvider.applyThemeMode(appProvider.isDark);
            if (mounted) setState(() {});
            floatingSnackBar(loc.apThemeResetDone);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: appTheme.accentColor,
            side: BorderSide(color: appTheme.accentColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(loc.apResetAppearance),
        ),
      ),
    );
  }
}
