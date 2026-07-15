import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/settings.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/clickableItem.dart';
import 'package:kumaanime/ui/models/widgets/toggleItem.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class StorageSetting extends StatefulWidget {
  const StorageSetting({super.key});

  @override
  State<StorageSetting> createState() => _StorageSettingState();
}

class _StorageSettingState extends State<StorageSetting> {
  static const _keys = ['maxCacheSizeMb', 'autoClearCacheOnExit'];

  Future<void> _write(SettingsModal settings) async {
    await Settings().writeSettings(settings);
    if (mounted) setState(() {});
  }

  String get _cacheSize {
    final bytes = PaintingBinding.instance.imageCache.currentSizeBytes;
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  Future<void> _clearImageCache() async {
    final loc = AppLocalizations.of(context);
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await CachedNetworkImage.evictFromCache('');
    if (mounted) setState(() {});
    floatingSnackBar(loc.stgImageCacheCleared);
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
              settingPagesTitleHeader(context, loc.stgStorageCache),

              buildFluentSettingsSectionHeader(loc.stgStorageCache),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: buildFluentSettingsCard(
                  children: [
                    buildFluentSettingsTile(
                      context: context,
                      icon: Icons.storage_rounded,
                      title: loc.stgInMemoryImageCache,
                      description: "Current RAM usage of loaded images",
                      trailing: Text(
                        _cacheSize,
                        style: TextStyle(
                          color: appTheme.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    buildFluentSettingsTile(
                      context: context,
                      icon: Icons.delete_outline_rounded,
                      title: loc.stgClearImageCache,
                      description: loc.stgClearImageCacheDesc,
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: appTheme.textSubColor),
                      onTap: _clearImageCache,
                    ),
                    buildFluentSettingsTile(
                      context: context,
                      icon: Icons.cleaning_services_rounded,
                      title: loc.stgClearAllLocalData,
                      description: loc.stgClearAllLocalDataDesc,
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: appTheme.textSubColor),
                      onTap: _confirmClearAll,
                    ),
                    buildFluentSettingsTile(
                      context: context,
                      icon: Icons.sd_storage_rounded,
                      title: "${loc.stgMaxCacheSize}: ${(s?.maxCacheSizeMb ?? 512).round()} MB",
                      trailing: SizedBox(
                        width: 140,
                        child: _slider(
                          value: (s?.maxCacheSizeMb ?? 512).toDouble(),
                          min: 128,
                          max: 2048,
                          onChanged: (v) => _write(SettingsModal(maxCacheSizeMb: v.round())),
                        ),
                      ),
                    ),
                    buildFluentSettingsTile(
                      context: context,
                      icon: Icons.autorenew_rounded,
                      title: loc.stgAutoClearCacheOnExit,
                      description: "Clear temporary images automatically on app exit",
                      trailing: Switch(
                        value: s?.autoClearCacheOnExit ?? false,
                        onChanged: (val) => _write(SettingsModal(autoClearCacheOnExit: val)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              resetCategoryButton(context, loc.stgResetStorage, () async {
                await Settings().resetKeys(_keys);
                if (mounted) setState(() {});
                floatingSnackBar(loc.stgStorageReset);
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slider({required double value, required double min, required double max, required void Function(double) onChanged}) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: appTheme.accentColor,
            label: "${value.round()} MB",
            divisions: ((max - min) / 64).round(),
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Text("${value.round()} MB", style: TextStyle(color: appTheme.textSubColor)),
        ),
      ],
    );
  }

  void _confirmClearAll() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appTheme.modalSheetBackgroundColor,
        title: Text(loc.stgClearAllLocalData, style: TextStyle(color: appTheme.textMainColor)),
        content: Text(loc.stgClearAllLocalDataConfirm,
            style: TextStyle(color: appTheme.textSubColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.stgCancel)),
          TextButton(
            onPressed: () {
              _clearImageCache();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: appTheme.accentColor),
            child: Text(loc.stgClear),
          ),
        ],
      ),
    );
  }
}
