import 'dart:io';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/settings.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/ui/models/bottomSheets/audioOutputSheet.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/player/playerUtils.dart';
import 'package:kumaanime/ui/models/widgets/player/squigglySlider.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/ui/pages/settingPages/subtitle.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlaybackSetting extends StatefulWidget {
  final bool fromWatchPage;

  const PlaybackSetting({super.key, this.fromWatchPage = false});

  @override
  State<PlaybackSetting> createState() => _PlaybackSettingState();
}

class _PlaybackSettingState extends State<PlaybackSetting> {
  static const _keys = [
    'hardwareAcceleration',
    'bufferSizeMs',
    'resumePlayback',
    'autoPlayNext',
    'autoPlayCountdown',
    'playerOrientation',
    'skipDuration',
    'megaSkipDuration',
    'enableMegaSkip',
    'enableSuperSpeeds',
    'doubleTapToSkip',
    'enablePipOnMinimize',
    'autoOpEdSkip',
    'enableHoldToSpeedUp',
    'enablePlayerGestures',
    'seekbarStyle',
  ];

  static const _orientations = ['auto', 'landscape', 'portrait'];

  static const _seekbarStyles = <String, String>{
    'standard': 'Standard',
    'wavy': 'Wavy',
    'thick': 'Thick',
    'circular': 'Circular',
    'simple': 'Simple',
  };

  @override
  void initState() {
    if (widget.fromWatchPage) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.initState();
  }

  @override
  void dispose() {
    if (widget.fromWatchPage) {
      SystemChrome.setPreferredOrientations(watchPreferredOrientations());
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    super.dispose();
  }

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
      body: buildFluentSettingsBody(
        child: SingleChildScrollView(
          child: Padding(
            padding: pagePadding(context, bottom: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                settingPagesTitleHeader(context, loc.pbPlayback),

                buildFluentSettingsSectionHeader(loc.pbPlayback),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: buildFluentSettingsCard(
                    children: [
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.volume_up_rounded,
                        title: loc.audioSettingsTitle,
                        description: loc.audioDevice,
                        onTap: () => AudioOutputSheet.show(context),
                      ),
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.bolt_rounded,
                        title: loc.pbHardwareAcceleration,
                        description: loc.pbHardwareAccelerationDesc,
                        trailing: Switch(
                          value: s?.hardwareAcceleration ?? true,
                          onChanged: (val) => _write(SettingsModal(hardwareAcceleration: val)),
                        ),
                      ),
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.history_rounded,
                        title: loc.pbResumePlayback,
                        description: loc.pbResumePlaybackDesc,
                        trailing: Switch(
                          value: s?.resumePlayback ?? true,
                          onChanged: (val) => _write(SettingsModal(resumePlayback: val)),
                        ),
                      ),
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.play_arrow_rounded,
                        title: loc.pbAutoPlayNext,
                        trailing: Switch(
                          value: s?.autoPlayNext ?? true,
                          onChanged: (val) => _write(SettingsModal(autoPlayNext: val)),
                        ),
                      ),
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.timer_rounded,
                        title: "${loc.pbAutoPlayCountdown}: ${(s?.autoPlayCountdown ?? 10)}s",
                        trailing: SizedBox(
                          width: 140,
                          child: _slider(
                            value: (s?.autoPlayCountdown ?? 10).toDouble(),
                            min: 3,
                            max: 30,
                            unit: "s",
                            onChanged: (v) => _write(SettingsModal(autoPlayCountdown: v.round())),
                          ),
                        ),
                      ),
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.speed_rounded,
                        title: "${loc.pbBufferSize}: ${((s?.bufferSizeMs ?? 120000) / 1000).round()}s",
                        trailing: SizedBox(
                          width: 140,
                          child: _slider(
                            value: ((s?.bufferSizeMs ?? 120000) / 1000),
                            min: 30,
                            max: 300,
                            unit: "s",
                            onChanged: (v) => _write(SettingsModal(bufferSizeMs: (v * 1000).round())),
                          ),
                        ),
                      ),
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.screen_rotation_rounded,
                        title: loc.pbScreenOrientation,
                        description: (s?.playerOrientation ?? 'auto').toUpperCase(),
                        trailing: Icon(Icons.arrow_drop_down, color: appTheme.textSubColor),
                        onTap: () => _showOrientationSheet(s?.playerOrientation ?? 'auto'),
                      ),
                    ],
                  ),
                ),

                buildFluentSettingsSectionHeader(loc.plrPlayer),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: buildFluentSettingsCard(
                    children: [
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.subtitles_rounded,
                        title: loc.plrSubtitleSettings,
                        description: loc.plrCustomizeSubtitles,
                        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: appTheme.textSubColor),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => SubtitleSettingPage()));
                        },
                      ),
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.linear_scale_rounded,
                        title: loc.plrSeekbarStyle,
                        description: _seekbarStyles[currentUserSettings?.seekbarStyle ?? 'standard'] ?? 'Standard',
                        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: appTheme.textSubColor),
                        onTap: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _showSeekbarStyleDialog(loc, currentUserSettings?.seekbarStyle ?? 'standard');
                          });
                        },
                      ),
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.skip_next_rounded,
                        title: loc.plrAutoOpEdSkip,
                        description: loc.plrAutoOpEdSkipDesc,
                        trailing: Switch(
                          value: s?.autoOpEdSkip ?? false,
                          onChanged: (val) => _write(SettingsModal(autoOpEdSkip: val)),
                        ),
                      ),
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.double_arrow_rounded,
                        title: loc.plrShowSkipButton,
                        description: loc.plrShowSkipButtonDesc(s?.megaSkipDuration ?? 85),
                        trailing: Switch(
                          value: s?.enableMegaSkip ?? true,
                          onChanged: (val) => _write(SettingsModal(enableMegaSkip: val)),
                        ),
                      ),
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.forward_10_rounded,
                        title: "${loc.plrSkipDuration}: ${(s?.skipDuration ?? 15)}s",
                        trailing: SizedBox(
                          width: 140,
                          child: _slider(
                            value: (s?.skipDuration ?? 15).toDouble(),
                            min: 5,
                            max: 50,
                            unit: "s",
                            onChanged: (v) => _write(SettingsModal(skipDuration: v.round())),
                          ),
                        ),
                      ),
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.forward_30_rounded,
                        title: "${loc.plrMegaSkipDuration}: ${(s?.megaSkipDuration ?? 85)}s",
                        trailing: SizedBox(
                          width: 140,
                          child: _slider(
                            value: (s?.megaSkipDuration ?? 85).toDouble(),
                            min: 20,
                            max: 150,
                            unit: "s",
                            onChanged: (v) => _write(SettingsModal(megaSkipDuration: v.round())),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                buildFluentSettingsSectionHeader("Controls & Gestures"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: buildFluentSettingsCard(
                    children: [
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.touch_app_rounded,
                        title: loc.plrHoldToSpeedUp,
                        description: loc.plrHoldToSpeedUpDesc,
                        trailing: Switch(
                          value: s?.enableHoldToSpeedUp ?? true,
                          onChanged: (val) => _write(SettingsModal(enableHoldToSpeedUp: val)),
                        ),
                      ),
                      if (Platform.isAndroid || Platform.isIOS) ...[
                        buildFluentSettingsTile(
                          context: context,
                          icon: Icons.gesture_rounded,
                          title: loc.plrPlayerGestures,
                          description: loc.plrPlayerGesturesDesc,
                          trailing: Switch(
                            value: s?.enablePlayerGestures ?? false,
                            onChanged: (val) => _write(SettingsModal(enablePlayerGestures: val)),
                          ),
                        ),
                        buildFluentSettingsTile(
                          context: context,
                          icon: Icons.ads_click_rounded,
                          title: loc.plrDoubleTapToSeek,
                          description: loc.plrDoubleTapToSeekDesc(s?.skipDuration ?? 10),
                          trailing: Switch(
                            value: s?.doubleTapToSkip ?? true,
                            onChanged: (val) => _write(SettingsModal(doubleTapToSkip: val)),
                          ),
                        ),
                      ],
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.fast_forward_rounded,
                        title: loc.plrEnableSuperSpeeds,
                        description: loc.plrEnableSuperSpeedsDesc,
                        trailing: Switch(
                          value: s?.enableSuperSpeeds ?? false,
                          onChanged: (val) => _write(SettingsModal(enableSuperSpeeds: val)),
                        ),
                      ),
                      buildFluentSettingsTile(
                        context: context,
                        icon: Icons.picture_in_picture_alt_rounded,
                        title: loc.plrAutoPip,
                        description: loc.plrAutoPipDesc,
                        trailing: Switch(
                          value: s?.enablePipOnMinimize ?? false,
                          onChanged: (val) => _write(SettingsModal(enablePipOnMinimize: val)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                resetCategoryButton(context, loc.pbResetPlayback, () async {
                  await Settings().resetKeys(_keys);
                  if (mounted) setState(() {});
                  floatingSnackBar(loc.pbPlaybackReset);
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _slider({
    required double value,
    required double min,
    required double max,
    required String unit,
    required void Function(double) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: appTheme.accentColor,
            label: "${value.round()}$unit",
            divisions: (max - min).round(),
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Text("${value.round()}$unit", style: TextStyle(color: appTheme.textSubColor)),
        ),
      ],
    );
  }

  void _showOrientationSheet(String current) {
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
              child: Text(loc.pbScreenOrientation, style: textStyle().copyWith(fontSize: 22)),
            ),
            ..._orientations.map((o) => optionTile(
                  label: o.toUpperCase(),
                  selected: o == current,
                  onTap: () {
                    _write(SettingsModal(playerOrientation: o));
                    Navigator.pop(context);
                  },
                )),
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
        content: SizedBox(
          width: 300,
          child: Column(
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
          _write(SettingsModal(seekbarStyle: styleKey));
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
                  child: SeekbarStylePreview(
                    style: seekbarStyleFromString(styleKey),
                    activeColor: appTheme.accentColor,
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
}
