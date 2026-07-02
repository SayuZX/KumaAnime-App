import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/settings.dart';
import 'package:kumaanime/core/data/theme.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/ui/theme/themes.dart';
import 'package:kumaanime/ui/models/providers/appProvider.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/toggleItem.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppearanceSetting extends StatefulWidget {
  const AppearanceSetting({super.key});

  @override
  State<AppearanceSetting> createState() => _AppearanceSettingState();
}

class _AppearanceSettingState extends State<AppearanceSetting> {
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
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: pagePadding(context, bottom: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              settingPagesTitleHeader(context, "Appearance"),
              _sectionLabel("Accent Color"),
              _accentGrid(appProvider, s?.accentColorValue),
              _sectionLabel("Font"),
              _fontList(appProvider, s?.fontFamily ?? 'NotoSans'),
              _sectionLabel("Text Size"),
              _scaleSlider(
                value: s?.textScale ?? 1.0,
                min: 0.8,
                max: 1.4,
                onChanged: (v) {
                  _write(SettingsModal(textScale: v));
                  appProvider.justRefresh();
                },
              ),
              _sectionLabel("Anime List Layout"),
              _layoutChips(s?.listLayout ?? 'grid'),
              _sectionLabel("Card Size"),
              _cardSizeChips(s?.cardScale ?? 1.0),
              const SizedBox(height: 8),
              ToggleItem(
                label: "AMOLED pure black",
                description: "Pure black background in dark mode",
                value: s?.amoledBackground ?? false,
                onTapFunction: () {
                  _write(SettingsModal(amoledBackground: !(s?.amoledBackground ?? false)));
                  appProvider.applyThemeMode(appProvider.isDark);
                },
              ),
              ToggleItem(
                label: "Blur hero banners",
                value: s?.heroBlur ?? true,
                onTapFunction: () => _write(SettingsModal(heroBlur: !(s?.heroBlur ?? true))),
              ),
              ToggleItem(
                label: "Reduce motion",
                description: "Disable heavy animations",
                value: s?.reduceMotion ?? false,
                onTapFunction: () => _write(SettingsModal(reduceMotion: !(s?.reduceMotion ?? false))),
              ),
              const SizedBox(height: 20),
              _resetButton(appProvider),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: appTheme.textMainColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
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
    return Column(
      children: _fonts.map((font) {
        final isSelected = font == selected;
        return InkWell(
          onTap: () {
            _write(SettingsModal(fontFamily: font));
            appProvider.justRefresh();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? appTheme.accentColor.withValues(alpha: 0.15) : appTheme.backgroundSubColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? appTheme.accentColor : Colors.transparent),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(font, style: TextStyle(color: appTheme.textMainColor, fontFamily: font, fontSize: 16)),
                Text("Aa Kuma Anime",
                    style: TextStyle(color: appTheme.textSubColor, fontFamily: font, fontSize: 15)),
              ],
            ),
          ),
        );
      }).toList(),
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

  Widget _cardSizeChips(double current) {
    const sizes = {'Small': 0.9, 'Medium': 1.0, 'Large': 1.15};
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

  Widget _layoutChips(String selected) {
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
                  layout[0].toUpperCase() + layout.substring(1),
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

  Widget _resetButton(AppProvider appProvider) {
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
            floatingSnackBar("Theme reset to default");
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: appTheme.accentColor,
            side: BorderSide(color: appTheme.accentColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text("Reset appearance"),
        ),
      ),
    );
  }
}
