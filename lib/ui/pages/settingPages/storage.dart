import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/settings.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/clickableItem.dart';
import 'package:kumaanime/ui/models/widgets/toggleItem.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
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
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await CachedNetworkImage.evictFromCache('');
    if (mounted) setState(() {});
    floatingSnackBar("Image cache cleared");
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
              settingPagesTitleHeader(context, "Storage & Cache"),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: appTheme.backgroundSubColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("In-memory image cache",
                        style: TextStyle(color: appTheme.textMainColor, fontSize: 15)),
                    Text(_cacheSize,
                        style: TextStyle(
                            color: appTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              ClickableItem(
                onTap: _clearImageCache,
                label: "Clear image cache",
                description: "Free up memory used by thumbnails",
                suffixIcon: Icon(Icons.delete_outline_rounded, color: appTheme.textMainColor),
              ),
              ClickableItem(
                onTap: _confirmClearAll,
                label: "Clear all local data",
                description: "Reset caches and temporary files",
                suffixIcon: Icon(Icons.cleaning_services_rounded, color: appTheme.textMainColor),
              ),
              _sectionLabel("Max cache size"),
              _slider(
                value: (s?.maxCacheSizeMb ?? 512).toDouble(),
                min: 128,
                max: 2048,
                onChanged: (v) => _write(SettingsModal(maxCacheSizeMb: v.round())),
              ),
              ToggleItem(
                label: "Auto-clear cache on exit",
                value: s?.autoClearCacheOnExit ?? false,
                onTapFunction: () => _write(SettingsModal(autoClearCacheOnExit: !(s?.autoClearCacheOnExit ?? false))),
              ),
              const SizedBox(height: 20),
              resetCategoryButton(context, "Reset storage", () async {
                await Settings().resetKeys(_keys);
                if (mounted) setState(() {});
                floatingSnackBar("Storage settings reset");
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appTheme.modalSheetBackgroundColor,
        title: Text("Clear all local data", style: TextStyle(color: appTheme.textMainColor)),
        content: Text("This clears image and temporary caches. Your settings and history stay.",
            style: TextStyle(color: appTheme.textSubColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              _clearImageCache();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: appTheme.accentColor),
            child: const Text("Clear"),
          ),
        ],
      ),
    );
  }
}
