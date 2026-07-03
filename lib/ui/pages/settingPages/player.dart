import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/settings.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/ui/models/widgets/slider.dart';
import 'package:kumaanime/ui/models/widgets/toggleItem.dart';
import 'package:kumaanime/ui/models/widgets/player/playerUtils.dart';
import 'package:kumaanime/ui/models/widgets/player/squigglySlider.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/ui/pages/settingPages/subtitle.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlayerSetting extends StatefulWidget {
  final bool fromWatchPage;
  const PlayerSetting({super.key, this.fromWatchPage = false});

  @override
  State<PlayerSetting> createState() => PlayerSettingState();
}

class PlayerSettingState extends State<PlayerSetting> {
  @override
  void initState() {
    if (widget.fromWatchPage) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.initState();
    readSettings();
  }

  int? skipDuration;
  int? megaSkipDuration;

  late double skipDurationSliderValue;
  late double megaSkipDurationSliderValue;

  bool loaded = false;

  late bool enableSuperSpeeds;
  late bool doubleTapToSkip;
  late bool enablePipOnMinimize;
  late bool autoOpEdSkip;
  late bool enableHoldToSpeedUp;
  late bool enablePlayerGestures;
  late bool enableMegaSkip;

  Future<void> readSettings() async {
    final settings = await Settings().getSettings();
    loaded = true;
    setState(() {
      skipDuration = settings.skipDuration ?? 15;
      megaSkipDuration = settings.megaSkipDuration ?? 85;
      enableMegaSkip = settings.enableMegaSkip ?? true;
      skipDurationSliderValue = skipDuration!.toDouble();
      megaSkipDurationSliderValue = megaSkipDuration!.toDouble();
      enableSuperSpeeds = settings.enableSuperSpeeds ?? false;
      doubleTapToSkip = settings.doubleTapToSkip ?? true;
      enablePipOnMinimize = settings.enablePipOnMinimize ?? false;
      autoOpEdSkip = settings.autoOpEdSkip ?? false;
      enableHoldToSpeedUp = settings.enableHoldToSpeedUp ?? true;
      enablePlayerGestures = settings.enablePlayerGestures ?? false;
    });
  }

  Future<void> writeSettings(SettingsModal settings) async {
    await Settings().writeSettings(settings);
    setState(() {
      readSettings();
    });
  }

  Set selectedQualitySet = {};

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Container(
          padding: pagePadding(context, bottom: true),
          child: loaded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    settingPagesTitleHeader(context, loc.plrPlayer),
                    Container(
                      // padding: EdgeInsets.only(left: 20, right: 20, top: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          item(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    loc.plrSkipDuration,
                                    style: textStyle(),
                                  ),
                                ),
                                SliderTheme(
                                  data: SliderThemeData(
                                    thumbColor: appTheme.accentColor,
                                    activeTrackColor: appTheme.accentColor,
                                    inactiveTrackColor: appTheme.textSubColor,
                                    valueIndicatorShape: RoundedSliderValueIndicator(height: 30, width: 35, radius: 5),
                                    valueIndicatorTextStyle: TextStyle(
                                      color: appTheme.backgroundColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    valueIndicatorColor: appTheme.accentColor,
                                    trackHeight: 13,
                                    trackShape: MarginedTrack(),
                                    thumbShape: RoundedRectangularThumbShape(width: 10, radius: 5),
                                    activeTickMarkColor: appTheme.backgroundColor,
                                  ),
                                  child: Slider(
                                    onChanged: (val) {
                                      setState(() {
                                        skipDurationSliderValue = val;
                                      });
                                    },
                                    onChangeEnd: (val) {
                                      writeSettings(SettingsModal(skipDuration: skipDurationSliderValue.toInt()));
                                    },
                                    value: skipDurationSliderValue,
                                    divisions: 9,
                                    label: skipDurationSliderValue.round().toString(),
                                    max: 50,
                                    min: 5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          item(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    loc.plrMegaSkipDuration,
                                    style: textStyle(),
                                  ),
                                ),
                                SliderTheme(
                                  data: SliderThemeData(
                                    thumbColor: appTheme.accentColor,
                                    activeTrackColor: appTheme.accentColor,
                                    inactiveTrackColor: appTheme.textSubColor,
                                    valueIndicatorShape: RoundedSliderValueIndicator(height: 30, width: 40, radius: 5),
                                    valueIndicatorTextStyle: TextStyle(
                                      color: appTheme.backgroundColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    valueIndicatorColor: appTheme.accentColor,
                                    trackHeight: 13,
                                    thumbShape: RoundedRectangularThumbShape(width: 10, radius: 5),
                                    trackShape: MarginedTrack(),
                                    activeTickMarkColor: appTheme.backgroundColor,
                                  ),
                                  child: Slider(
                                    onChanged: (val) {
                                      setState(() {
                                        megaSkipDurationSliderValue = val;
                                      });
                                    },
                                    onChangeEnd: (val) {
                                      writeSettings(
                                          SettingsModal(megaSkipDuration: megaSkipDurationSliderValue.toInt()));
                                    },
                                    value: megaSkipDurationSliderValue,
                                    divisions: 26,
                                    label: megaSkipDurationSliderValue.round().toString(),
                                    max: 150,
                                    min: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ToggleItem(
                            label: loc.plrShowSkipButton,
                            description: loc.plrShowSkipButtonDesc(megaSkipDuration ?? 85),
                            value: enableMegaSkip,
                            onTapFunction: () {
                              enableMegaSkip = !enableMegaSkip;
                              writeSettings(SettingsModal(enableMegaSkip: enableMegaSkip));
                            },
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) => SubtitleSettingPage()));
                            },
                            child: item(
                              // padding: EdgeInsets.only(top: 10, bottom: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.plrSubtitleSettings,
                                        style: textStyle(),
                                      ),
                                      Text(
                                        loc.plrCustomizeSubtitles,
                                        style: textStyle().copyWith(color: appTheme.textSubColor, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded)
                                ],
                              ),
                            ),
                          ),
                          _seekbarStylePicker(loc),
                          ToggleItem(
                              label: loc.plrEnableSuperSpeeds,
                              value: enableSuperSpeeds,
                              description: loc.plrEnableSuperSpeedsDesc,
                              onTapFunction: () {
                                enableSuperSpeeds = !enableSuperSpeeds;
                                writeSettings(SettingsModal(enableSuperSpeeds: enableSuperSpeeds));
                              }),
                            ToggleItem(
                              onTapFunction: () {
                                doubleTapToSkip = !doubleTapToSkip;
                                writeSettings(SettingsModal(doubleTapToSkip: doubleTapToSkip));
                              },
                              label: loc.plrDoubleTapToSeek,
                              description: loc.plrDoubleTapToSeekDesc(skipDuration ?? 10),
                              value: doubleTapToSkip,
                              mobileOnly: true,
                            ),
                          ToggleItem(
                            label: loc.plrAutoPip,
                            description: loc.plrAutoPipDesc,
                            value: enablePipOnMinimize,
                            onTapFunction: () {
                              enablePipOnMinimize = !enablePipOnMinimize;
                              writeSettings(SettingsModal(enablePipOnMinimize: enablePipOnMinimize));
                            },
                          ),
                          ToggleItem(
                            label: loc.plrAutoOpEdSkip,
                            description: loc.plrAutoOpEdSkipDesc,
                            value: autoOpEdSkip,
                            onTapFunction: () {
                              autoOpEdSkip = !autoOpEdSkip;
                              writeSettings(SettingsModal(autoOpEdSkip: autoOpEdSkip));
                            },
                          ),
                          ToggleItem(
                            onTapFunction: () {
                              enableHoldToSpeedUp = !enableHoldToSpeedUp;
                              writeSettings(SettingsModal(enableHoldToSpeedUp: enableHoldToSpeedUp));
                            },
                            label: loc.plrHoldToSpeedUp,
                            description: loc.plrHoldToSpeedUpDesc,
                            value: enableHoldToSpeedUp,
                          ),
                          ToggleItem(
                            onTapFunction: () {
                              enablePlayerGestures = !enablePlayerGestures;
                              writeSettings(SettingsModal(enablePlayerGestures: enablePlayerGestures));
                            },
                            label: loc.plrPlayerGestures,
                            description: loc.plrPlayerGesturesDesc,
                            value: enablePlayerGestures,
                            mobileOnly: true,
                            )
                        ],
                      ),
                    )
                  ],
                )
              : Container(),
        ),
      ),
    );
  }

  static const _seekbarStyles = <String, String>{
    'standard': 'Standard',
    'wavy': 'Wavy',
    'thick': 'Thick',
    'circular': 'Circular',
    'simple': 'Simple',
  };

  Widget _seekbarStylePicker(AppLocalizations loc) {
    final current = currentUserSettings?.seekbarStyle ?? 'standard';

    return InkWell(
      onTap: () => _showSeekbarStyleDialog(loc, current),
      child: item(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.plrSeekbarStyle, style: textStyle()),
                Text(
                  _seekbarStyles[current] ?? 'Standard',
                  style: textStyle().copyWith(color: appTheme.textSubColor, fontSize: 12),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios_rounded),
          ],
        ),
      ),
    );
  }

  void _showSeekbarStyleDialog(AppLocalizations loc, String current) {
    final rows = <List<MapEntry<String, String>>>[];
    final entries = _seekbarStyles.entries.toList();
    for (var i = 0; i < entries.length; i += 3) {
      rows.add(entries.sublist(i, (i + 3).clamp(0, entries.length)));
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: appTheme.modalSheetBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: rows.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  ...row.map(
                    (entry) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _styleOptionCard(dialogContext, entry.key, entry.value, current == entry.key),
                      ),
                    ),
                  ),
                  ...List.generate(3 - row.length, (index) => const Expanded(child: SizedBox())),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(loc.stgCancel, style: TextStyle(color: appTheme.accentColor)),
          ),
        ],
      ),
    );
  }

  Widget _styleOptionCard(BuildContext dialogContext, String styleKey, String label, bool selected) {
    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        onTap: () {
          writeSettings(SettingsModal(seekbarStyle: styleKey));
          Navigator.of(dialogContext).pop();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? appTheme.accentColor : appTheme.textSubColor.withValues(alpha: 0.3),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: IgnorePointer(
                    child: StyledSeekBar(
                      style: seekbarStyleFromString(styleKey),
                      value: 0.5,
                      max: 1,
                      isPlaying: true,
                      activeColor: appTheme.accentColor,
                    ),
                  ),
                ),
              ),
              Text(
                label,
                style: textStyle().copyWith(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? appTheme.accentColor : appTheme.textMainColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container item({required Widget child}) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
      child: child,
    );
  }

  @override
  void dispose() {
    if (widget.fromWatchPage) {
      SystemChrome.setPreferredOrientations(watchPreferredOrientations());
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }
}
