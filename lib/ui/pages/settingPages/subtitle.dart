import 'dart:io';

import 'package:kumaanime/ui/models/widgets/backButton.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/preferences.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/widgets/player/playerUtils.dart';
import 'package:kumaanime/ui/models/widgets/slider.dart';
import 'package:kumaanime/ui/models/widgets/subtitles/subtitleSettings.dart';
import 'package:kumaanime/ui/models/widgets/subtitles/subtitleText.dart';
import 'package:kumaanime/ui/models/widgets/toggleItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SubtitleSettingPage extends StatefulWidget {
  final bool fromWatchPage;
  const SubtitleSettingPage({super.key, this.fromWatchPage = false});

  @override
  State<SubtitleSettingPage> createState() => _SubtitleSettingPageState();
}

class _SubtitleSettingPageState extends State<SubtitleSettingPage> {
  bool initialised = false;
  bool previewMode = false;
  int ind = 0;
  late SubtitleSettings settings;

  final fonts = ["Rubik", "Poppins", "NotoSans", "NunitoSans", "Inter", "OpenSans"];
  final languages = ["Indonesia", "Jepang", "English"];

  final textColors = [
    Colors.white,
    Colors.yellow,
    Colors.cyan,
    Colors.greenAccent,
    Colors.redAccent,
    Colors.pinkAccent,
  ];

  final strokeColors = [
    Colors.black,
    Colors.grey,
    Colors.white,
    Colors.red,
    Colors.blue,
  ];

  final backgroundColors = [
    Colors.black,
    Colors.grey,
    Colors.blueGrey,
    Colors.indigo,
    Colors.transparent,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.fromWatchPage) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    readSubSettings();
  }

  @override
  void dispose() {
    if (widget.fromWatchPage) {
      SystemChrome.setPreferredOrientations(watchPreferredOrientations());
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void readSubSettings() async {
    UserPreferences.getUserPreferences().then((value) {
      setState(() {
        settings = value.subtitleSettings ?? const SubtitleSettings();
        initialised = true;
      });
    });
  }

  Future<void> saveSubSettings() async {
    await UserPreferences.saveUserPreferences(UserPreferencesModal(subtitleSettings: settings));
  }

  List<String> _sentences(AppLocalizations loc) => [
        loc.subSample1,
        loc.subSample2,
        loc.subSample3,
      ];

  String getSentence(int index, AppLocalizations loc) {
    return _sentences(loc)[index];
  }

  TextStyle subTextStyle() {
    return TextStyle(
      fontSize: (Platform.isWindows || Platform.isLinux) ? settings.fontSize * 1.5 : settings.fontSize,
      fontFamily: settings.fontFamily ?? "Rubik",
      color: settings.textColor.withValues(alpha: settings.opacity),
      fontWeight: settings.bold ? FontWeight.w700 : FontWeight.w500,
      fontFamilyFallback: const ["Poppins"],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return PopScope(
      canPop: !previewMode,
      onPopInvokedWithResult: (didPop, result) {
        if (previewMode) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeRight,
            DeviceOrientation.landscapeLeft
          ]);
          setState(() {
            previewMode = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: appTheme.backgroundColor,
        body: previewMode
            ? _preview()
            : Padding(
                padding: MediaQuery.paddingOf(context),
                child: !initialised
                    ? const KumaBackButton(size: 35)
                    : Column(
                        children: [
                          Row(
                            children: [
                              const KumaBackButton(size: 35),
                              const SizedBox(width: 10),
                              Text(
                                "Pengaturan Subtitle",
                                style: TextStyle(
                                  color: appTheme.textMainColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Stack(
                            children: [
                              Container(
                                alignment: Alignment.bottomCenter,
                                padding: EdgeInsets.only(top: 20, bottom: settings.bottomMargin),
                                color: Colors.black26,
                                constraints: const BoxConstraints(minHeight: 170),
                                margin: const EdgeInsets.only(bottom: 20),
                                child: Container(
                                  width: MediaQuery.of(context).size.width / 1.6,
                                  alignment: Alignment.bottomCenter,
                                  child: SubtitleText(
                                    text: getSentence(ind, loc),
                                    style: subTextStyle(),
                                    strokeColor: settings.strokeColor,
                                    strokeWidth: settings.strokeWidth,
                                    backgroundColor: settings.backgroundColor,
                                    backgroundTransparency: settings.backgroundTransparency,
                                    enableShadows: settings.enableShadows,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: IconButton(
                                  onPressed: () {
                                    SystemChrome.setPreferredOrientations([
                                      DeviceOrientation.landscapeRight,
                                      DeviceOrientation.landscapeLeft
                                    ]);
                                    setState(() {
                                      previewMode = true;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.only(bottom: 40),
                              shrinkWrap: true,
                              children: [
                                _sectionTitle("Bahasa Default"),
                                _languageSelector(),
                                const SizedBox(height: 16),
                                _sectionTitle("Warna Teks"),
                                _colorRow(textColors, settings.textColor, (c) {
                                  setState(() => settings = settings.copyWith(textColor: c));
                                  saveSubSettings();
                                }),
                                const SizedBox(height: 16),
                                _sectionTitle("Warna Outline"),
                                _colorRow(strokeColors, settings.strokeColor, (c) {
                                  setState(() => settings = settings.copyWith(strokeColor: c));
                                  saveSubSettings();
                                }),
                                const SizedBox(height: 16),
                                _sectionTitle("Warna Background"),
                                _colorRow(backgroundColors, settings.backgroundColor, (c) {
                                  setState(() => settings = settings.copyWith(backgroundColor: c));
                                  saveSubSettings();
                                }),
                                const SizedBox(height: 16),
                                _itemTitle(loc.subFontFamily),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  height: 220,
                                  child: GridView(
                                    padding: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 2,
                                      mainAxisExtent: 75,
                                    ),
                                    children: [
                                      for (var i = 0; i < fonts.length; i++)
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              settings = settings.copyWith(fontFamily: fonts[i]);
                                            });
                                            saveSubSettings();
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              color: settings.fontFamily == fonts[i]
                                                  ? appTheme.accentColor
                                                  : appTheme.backgroundSubColor,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Center(
                                              child: Text(
                                                fonts[i],
                                                style: TextStyle(
                                                    color: settings.fontFamily == fonts[i]
                                                        ? appTheme.onAccent
                                                        : appTheme.textMainColor,
                                                    fontFamily: fonts[i]),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                ToggleItem(
                                    label: loc.subBold,
                                    value: settings.bold,
                                    onTapFunction: () {
                                      setState(() {
                                        settings = settings.copyWith(bold: !settings.bold);
                                        saveSubSettings();
                                      });
                                    }),
                                ToggleItem(
                                    label: loc.subShadows,
                                    value: settings.enableShadows,
                                    onTapFunction: () {
                                      setState(() {
                                        settings = settings.copyWith(enableShadows: !settings.enableShadows);
                                        saveSubSettings();
                                      });
                                    }),
                                _itemTitle(loc.subFontSize),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                                  child: CustomSlider(
                                    value: settings.fontSize,
                                    onChanged: (val) {
                                      setState(() {
                                        settings = settings.copyWith(fontSize: val);
                                      });
                                    },
                                    onDragEnd: (value) {
                                      saveSubSettings();
                                    },
                                    min: 15,
                                    max: 30,
                                    divisions: (30 - 15),
                                  ),
                                ),
                                _itemTitle("Opacity Teks"),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                                  child: CustomSlider(
                                    value: settings.opacity,
                                    onChanged: (val) {
                                      setState(() {
                                        settings = settings.copyWith(opacity: val);
                                      });
                                    },
                                    onDragEnd: (value) {
                                      saveSubSettings();
                                    },
                                    min: 0.0,
                                    max: 1.0,
                                    divisions: 10,
                                  ),
                                ),
                                _itemTitle(loc.subStrokeWidth),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                                  child: CustomSlider(
                                    value: settings.strokeWidth,
                                    onChanged: (val) {
                                      setState(() {
                                        settings = settings.copyWith(strokeWidth: double.parse(val.toStringAsFixed(2)));
                                      });
                                    },
                                    onDragEnd: (value) {
                                      saveSubSettings();
                                    },
                                    min: 0,
                                    max: 6,
                                    divisions: 12,
                                  ),
                                ),
                                _itemTitle(loc.subBackgroundOpacity),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                                  child: CustomSlider(
                                    value: settings.backgroundTransparency,
                                    onChanged: (val) {
                                      setState(() {
                                        settings = settings.copyWith(
                                            backgroundTransparency: double.parse(val.toStringAsFixed(2)));
                                      });
                                    },
                                    onDragEnd: (value) {
                                      saveSubSettings();
                                    },
                                    min: 0,
                                    max: 1,
                                    divisions: 10,
                                  ),
                                ),
                                _itemTitle("Sinkronisasi Kecepatan (Offset Delay)"),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                                  child: CustomSlider(
                                    value: settings.offset,
                                    onChanged: (val) {
                                      setState(() {
                                        settings = settings.copyWith(offset: double.parse(val.toStringAsFixed(1)));
                                      });
                                    },
                                    onDragEnd: (value) {
                                      saveSubSettings();
                                    },
                                    min: -5.0,
                                    max: 5.0,
                                    divisions: 100,
                                  ),
                                ),
                                _itemTitle(loc.subBottomMargin),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20, right: 20),
                                  child: CustomSlider(
                                    value: settings.bottomMargin,
                                    onChanged: (val) {
                                      setState(() {
                                        settings =
                                            settings.copyWith(bottomMargin: double.parse(val.toStringAsFixed(2)));
                                      });
                                    },
                                    onDragEnd: (value) {
                                      saveSubSettings();
                                    },
                                    min: 0,
                                    max: 50,
                                    divisions: 50,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _preview() {
    final loc = AppLocalizations.of(context);
    return Stack(children: [
      Container(
        alignment: Alignment.bottomCenter,
        padding: EdgeInsets.only(top: 20, bottom: settings.bottomMargin),
        color: Colors.black26,
        height: MediaQuery.of(context).size.height,
        child: Container(
          margin: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
          width: MediaQuery.of(context).size.width / 1.6,
          alignment: Alignment.bottomCenter,
          child: SubtitleText(
            text: getSentence(ind, loc),
            style: subTextStyle(),
            strokeColor: settings.strokeColor,
            strokeWidth: settings.strokeWidth,
            backgroundColor: settings.backgroundColor,
            backgroundTransparency: settings.backgroundTransparency,
            enableShadows: settings.enableShadows,
          ),
        ),
      ),
      Container(
        alignment: Alignment.topRight,
        margin: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top,
            right: MediaQuery.paddingOf(context).right + 10,
            left: MediaQuery.paddingOf(context).left + 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.subPreviewMode,
                  style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
                ),
                IconButton(
                    onPressed: () {
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                        DeviceOrientation.landscapeRight,
                        DeviceOrientation.landscapeLeft
                      ]);
                      setState(() {
                        previewMode = false;
                      });
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    )),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _sentences(loc).length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                return Container(
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        ind = index;
                      });
                    },
                    icon: Text("${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                        )),
                  ),
                );
              },
            )
          ],
        ),
      ),
    ]);
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: appTheme.textMainColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _languageSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        children: languages.map((lang) {
          final isSelected = settings.defaultLanguage == lang;
          return ChoiceChip(
            label: Text(lang),
            selected: isSelected,
            onSelected: (val) {
              if (val) {
                setState(() => settings = settings.copyWith(defaultLanguage: lang));
                saveSubSettings();
              }
            },
            selectedColor: appTheme.accentColor,
            labelStyle: TextStyle(
              color: isSelected ? appTheme.onAccent : appTheme.textMainColor,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _colorRow(List<Color> colors, Color selectedColor, ValueChanged<Color> onSelected) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = selectedColor == color || (color == Colors.transparent && selectedColor.a == 0);
          return GestureDetector(
            onTap: () => onSelected(color),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? (color == Colors.white ? Colors.black54 : Colors.white)
                      : Colors.grey.withValues(alpha: 0.3),
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: color == Colors.white ? Colors.black87 : Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Center _itemTitle(String title) => Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20, top: 10),
          child: Text(title, style: TextStyle(color: appTheme.textMainColor, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
      );
}
