import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/settings.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/clickableItem.dart';
import 'package:kumaanime/ui/models/widgets/toggleItem.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';

class PlaybackSetting extends StatefulWidget {
  const PlaybackSetting({super.key});

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
  ];

  static const _orientations = ['auto', 'landscape', 'portrait'];

  Future<void> _write(SettingsModal settings) async {
    await Settings().writeSettings(settings);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = currentUserSettings;
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: pagePadding(context, bottom: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              settingPagesTitleHeader(context, "Playback"),
              ToggleItem(
                label: "Hardware acceleration",
                description: "Use GPU decoding when available",
                value: s?.hardwareAcceleration ?? true,
                onTapFunction: () => _write(SettingsModal(hardwareAcceleration: !(s?.hardwareAcceleration ?? true))),
              ),
              ToggleItem(
                label: "Resume playback",
                description: "Continue from the last watched position",
                value: s?.resumePlayback ?? true,
                onTapFunction: () => _write(SettingsModal(resumePlayback: !(s?.resumePlayback ?? true))),
              ),
              ToggleItem(
                label: "Auto-play next episode",
                value: s?.autoPlayNext ?? true,
                onTapFunction: () => _write(SettingsModal(autoPlayNext: !(s?.autoPlayNext ?? true))),
              ),
              _sectionLabel("Auto-play countdown"),
              _slider(
                value: (s?.autoPlayCountdown ?? 10).toDouble(),
                min: 3,
                max: 30,
                unit: "s",
                onChanged: (v) => _write(SettingsModal(autoPlayCountdown: v.round())),
              ),
              _sectionLabel("Buffer size"),
              _slider(
                value: ((s?.bufferSizeMs ?? 120000) / 1000),
                min: 30,
                max: 300,
                unit: "s",
                onChanged: (v) => _write(SettingsModal(bufferSizeMs: (v * 1000).round())),
              ),
              ClickableItem(
                onTap: () => _showOrientationSheet(s?.playerOrientation ?? 'auto'),
                label: "Screen orientation",
                description: (s?.playerOrientation ?? 'auto').toUpperCase(),
                suffixIcon: Icon(Icons.arrow_drop_down, color: appTheme.textMainColor),
              ),
              const SizedBox(height: 20),
              resetCategoryButton(context, "Reset playback", () async {
                await Settings().resetKeys(_keys);
                if (mounted) setState(() {});
                floatingSnackBar("Playback settings reset");
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
          style: TextStyle(color: appTheme.textMainColor, fontFamily: "Rubik", fontSize: 16, fontWeight: FontWeight.bold)),
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
              child: Text("Screen orientation", style: textStyle().copyWith(fontSize: 22)),
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
}
