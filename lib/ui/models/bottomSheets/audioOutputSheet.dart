import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/audio/models/audio_device.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/providers/audio_provider.dart';
import 'package:provider/provider.dart';

class AudioOutputSheet extends StatelessWidget {
  const AudioOutputSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AudioOutputSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final audioProvider = Provider.of<AudioProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 520,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: appTheme.textSubColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Sheet Title Row
          Row(
            children: [
              Icon(HugeIcons.strokeRoundedVolumeHigh, color: appTheme.accentColor, size: 22),
              const SizedBox(width: 10),
              Text(
                loc.audioSettingsTitle,
                style: TextStyle(
                  color: appTheme.textMainColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => audioProvider.resetToDefault(),
                icon: Icon(HugeIcons.strokeRoundedRefresh, size: 14, color: appTheme.accentColor),
                label: Text(
                  loc.audioResetDefault,
                  style: TextStyle(color: appTheme.accentColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Follow Windows Default Switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: appTheme.backgroundSubColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.audioDeviceFollowWindows,
                                style: TextStyle(
                                  color: appTheme.textMainColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: audioProvider.isAutoFollowDefault,
                          activeTrackColor: appTheme.accentColor,
                          onChanged: (val) => audioProvider.setAutoFollowDefault(val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Volume Slider & Mute Row
                  Text(
                    loc.audioVolume,
                    style: TextStyle(
                      color: appTheme.textMainColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: appTheme.backgroundSubColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => audioProvider.toggleMute(),
                          icon: Icon(
                            audioProvider.isMuted || audioProvider.volume == 0
                                ? HugeIcons.strokeRoundedVolumeOff
                                : HugeIcons.strokeRoundedVolumeHigh,
                            color: audioProvider.isMuted ? Colors.redAccent : appTheme.accentColor,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: audioProvider.isMuted ? 0.0 : audioProvider.volume,
                            min: 0.0,
                            max: 1.0,
                            activeColor: appTheme.accentColor,
                            inactiveColor: appTheme.backgroundSubColor,
                            onChanged: (val) => audioProvider.setVolume(val),
                          ),
                        ),
                        Text(
                          "${(audioProvider.isMuted ? 0 : (audioProvider.volume * 100)).toInt()}%",
                          style: TextStyle(
                            color: appTheme.textMainColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Audio Sync Delay Adjuster
                  Text(
                    loc.audioSync,
                    style: TextStyle(
                      color: appTheme.textMainColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: appTheme.backgroundSubColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        Icon(HugeIcons.strokeRoundedTime04, color: appTheme.textSubColor, size: 20),
                        Expanded(
                          child: Slider(
                            value: audioProvider.audioSyncDelayMs.toDouble(),
                            min: -2000.0,
                            max: 2000.0,
                            divisions: 80,
                            activeColor: appTheme.accentColor,
                            inactiveColor: appTheme.backgroundSubColor,
                            onChanged: (val) => audioProvider.setAudioSyncDelay(val.toInt()),
                          ),
                        ),
                        Text(
                          "${audioProvider.audioSyncDelayMs >= 0 ? '+' : ''}${audioProvider.audioSyncDelayMs} ms",
                          style: TextStyle(
                            color: appTheme.textMainColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Devices List Header
                  Text(
                    loc.audioDevice,
                    style: TextStyle(
                      color: appTheme.textMainColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (audioProvider.devices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          loc.audioNoDevices,
                          style: TextStyle(color: appTheme.textSubColor, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: audioProvider.devices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final device = audioProvider.devices[index];
                        final isSelected = audioProvider.selectedDevice?.id == device.id ||
                            (audioProvider.isAutoFollowDefault && device.isDefault);

                        String statusText = loc.audioStatusConnected;
                        if (device.isDefault) {
                          statusText = loc.audioStatusDefault;
                        } else if (device.status == AudioDeviceStatus.disconnected) {
                          statusText = loc.audioStatusDisconnected;
                        }

                        return GestureDetector(
                          onTap: () => audioProvider.selectDevice(device),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? appTheme.accentColor.withValues(alpha: 0.12)
                                  : appTheme.backgroundSubColor.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? appTheme.accentColor
                                    : Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  device.icon,
                                  color: isSelected ? appTheme.accentColor : appTheme.textSubColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device.name,
                                        style: TextStyle(
                                          color: isSelected ? appTheme.accentColor : appTheme.textMainColor,
                                          fontSize: 13.5,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          color: device.isDefault
                                              ? appTheme.accentColor
                                              : appTheme.textSubColor,
                                          fontSize: 11,
                                          fontWeight: device.isDefault ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    HugeIcons.strokeRoundedCheckmarkCircle02,
                                    color: appTheme.accentColor,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
