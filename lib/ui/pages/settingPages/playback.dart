import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/settings.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/clickableItem.dart';
import 'package:kumaanime/ui/models/widgets/player/playerUtils.dart';
import 'package:kumaanime/ui/models/widgets/player/squigglySlider.dart';
import 'package:kumaanime/ui/models/widgets/toggleItem.dart';
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
      body: SingleChildScrollView(
        child: Padding(
          padding: pagePadding(context, bottom: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              settingPagesTitleHeader(context, loc.pbPlayback),
              ToggleItem(
                label: loc.pbHardwareAcceleration,
                description: loc.pbHardwareAccelerationDesc,
                value: s?.hardwareAcceleration ?? true,
                onTapFunction: () => _write(SettingsModal(hardwareAcceleration: !(s?.hardwareAcceleration ?? true))),
              ),
              ToggleItem(
                label: loc.pbResumePlayback,
                description: loc.pbResumePlaybackDesc,
                value: s?.resumePlayback ?? true,
                onTapFunction: () => _write(SettingsModal(resumePlayback: !(s?.resumePlayback ?? true))),
              ),
              ToggleItem(
                label: loc.pbAutoPlayNext,
                value: s?.autoPlayNext ?? true,
                onTapFunction: () => _write(SettingsModal(autoPlayNext: !(s?.autoPlayNext ?? true))),
              ),
              _sectionLabel(loc.pbAutoPlayCountdown),
              _slider(
                value: (s?.autoPlayCountdown ?? 10).toDouble(),
                min: 3,
                max: 30,
                unit: "s",
                onChanged: (v) => _write(SettingsModal(autoPlayCountdown: v.round())),
              ),
              _sectionLabel(loc.pbBufferSize),
              _slider(
                value: ((s?.bufferSizeMs ?? 120000) / 1000),
                min: 30,
                max: 300,
                unit: "s",
                onChanged: (v) => _write(SettingsModal(bufferSizeMs: (v * 1000).round())),
              ),
              ClickableItem(
                onTap: () => _showOrientationSheet(s?.playerOrientation ?? 'auto'),
                label: loc.pbScreenOrientation,
                description: (s?.playerOrientation ?? 'auto').toUpperCase(),
                suffixIcon: Icon(Icons.arrow_drop_down, color: appTheme.textMainColor),
              ),
              _sectionLabel(loc.plrPlayer),
              _sectionLabel(loc.plrSkipDuration),
              _slider(
                value: (s?.skipDuration ?? 15).toDouble(),
                min: 5,
                max: 50,
                unit: "s",
                onChanged: (v) => _write(SettingsModal(skipDuration: v.round())),
              ),
              _sectionLabel(loc.plrMegaSkipDuration),
              _slider(
                value: (s?.megaSkipDuration ?? 85).toDouble(),
                min: 20,
                max: 150,
                unit: "s",
                onChanged: (v) => _write(SettingsModal(megaSkipDuration: v.round())),
              ),
              ToggleItem(
                label: loc.plrShowSkipButton,
                description: loc.plrShowSkipButtonDesc(s?.megaSkipDuration ?? 85),
                value: s?.enableMegaSkip ?? true,
                onTapFunction: () => _write(SettingsModal(enableMegaSkip: !(s?.enableMegaSkip ?? true))),
              ),
              ClickableItem(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => SubtitleSettingPage()));
                },
                label: loc.plrSubtitleSettings,
                description: loc.plrCustomizeSubtitles,
                suffixIcon: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: appTheme.textSubColor),
              ),
              ClickableItem(
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _showSeekbarStyleDialog(loc, currentUserSettings?.seekbarStyle ?? 'standard');
                  });
                },
                label: loc.plrSeekbarStyle,
                description: _seekbarStyles[currentUserSettings?.seekbarStyle ?? 'standard'] ?? 'Standard',
                suffixIcon: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: appTheme.textSubColor),
              ),
              ToggleItem(
                label: loc.plrEnableSuperSpeeds,
                description: loc.plrEnableSuperSpeedsDesc,
                value: s?.enableSuperSpeeds ?? false,
                onTapFunction: () => _write(SettingsModal(enableSuperSpeeds: !(s?.enableSuperSpeeds ?? false))),
              ),
              ToggleItem(
                label: loc.plrDoubleTapToSeek,
                description: loc.plrDoubleTapToSeekDesc(s?.skipDuration ?? 10),
                value: s?.doubleTapToSkip ?? true,
                mobileOnly: true,
                onTapFunction: () => _write(SettingsModal(doubleTapToSkip: !(s?.doubleTapToSkip ?? true))),
              ),
              ToggleItem(
                label: loc.plrAutoPip,
                description: loc.plrAutoPipDesc,
                value: s?.enablePipOnMinimize ?? false,
                onTapFunction: () => _write(SettingsModal(enablePipOnMinimize: !(s?.enablePipOnMinimize ?? false))),
              ),
              ToggleItem(
                label: loc.plrAutoOpEdSkip,
                description: loc.plrAutoOpEdSkipDesc,
                value: s?.autoOpEdSkip ?? false,
                onTapFunction: () => _write(SettingsModal(autoOpEdSkip: !(s?.autoOpEdSkip ?? false))),
              ),
              ToggleItem(
                label: loc.plrHoldToSpeedUp,
                description: loc.plrHoldToSpeedUpDesc,
                value: s?.enableHoldToSpeedUp ?? true,
                onTapFunction: () => _write(SettingsModal(enableHoldToSpeedUp: !(s?.enableHoldToSpeedUp ?? true))),
              ),
              ToggleItem(
                label: loc.plrPlayerGestures,
                description: loc.plrPlayerGesturesDesc,
                value: s?.enablePlayerGestures ?? false,
                mobileOnly: true,
                onTapFunction: () => _write(SettingsModal(enablePlayerGestures: !(s?.enablePlayerGestures ?? false))),
              ),
              const SizedBox(height: 20),
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
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 18, bottom: 4),
      child: Text(text,
          style: TextStyle(color: appTheme.textMainColor, fontSize: 16, fontWeight: FontWeight.bold)),
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
