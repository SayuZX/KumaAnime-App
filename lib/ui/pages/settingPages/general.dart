import 'dart:io';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/settings.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/sources.dart';
import 'package:kumaanime/ui/models/widgets/clickableItem.dart';
import 'package:kumaanime/ui/models/widgets/toggleItem.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/ui/pages/settingPages/plugin.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class GeneralSetting extends StatefulWidget {
  const GeneralSetting({super.key});

  @override
  State<GeneralSetting> createState() => _GeneralSettingState();
}

class _GeneralSettingState extends State<GeneralSetting> {
  @override
  initState() {
    readSettings().then((val) => setState(() {
          loaded = true;
        }));
    super.initState();
  }

  Future<void> readSettings() async {
    final settings = await Settings().getSettings();
    setState(() {
      showErrorsButtonState = settings.showErrors!;
      receivePreReleases = settings.receivePreReleases!;
      fasterDownloads = settings.fasterDownloads!;
      useQueuedDownloads = settings.useQueuedDownloads!;
      enableLogging = settings.enableLogging!;
      dnsProvider = settings.dnsProvider ?? 'off';
    });
  }

  Future<void> writeSettings(SettingsModal settings) async {
    await Settings().writeSettings(settings);
    setState(() {
      readSettings();
    });
  }

  bool loaded = false;
  bool showErrorsButtonState = false;
  bool receivePreReleases = false;
  bool fasterDownloads = false;
  bool useQueuedDownloads = false;
  bool enableDiscordPresence = false;
  bool enableLogging = false;
  String dnsProvider = 'auto';

  static const Map<String, String> _dnsOptions = {
    'auto': 'Automatic',
    'cloudflare': 'Cloudflare (1.1.1.1)',
    'google': 'Google (8.8.8.8)',
    'quad9': 'Quad9 (9.9.9.9)',
    'adguard': 'AdGuard (94.140.14.14)',
    'opendns': 'OpenDNS (208.67.222.222)',
    'dnssb': 'DNS.SB (185.222.222.222)',
    'off': 'Off',
  };

  final sources = SourceManager.instance.sources;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: loaded
          ? SingleChildScrollView(
              child: Padding(
                padding: pagePadding(context, bottom: true),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    settingPagesTitleHeader(context, loc.generalTitle),
                    ToggleItem(
                      label: loc.showErrors,
                      value: showErrorsButtonState,
                      onTapFunction: () {
                        setState(() {
                          showErrorsButtonState = !showErrorsButtonState;
                        });
                        writeSettings(SettingsModal(showErrors: showErrorsButtonState));
                      },
                    ),
                    ToggleItem(
                      label: loc.receiveBetaUpdates,
                      value: receivePreReleases,
                      onTapFunction: () {
                        setState(() {
                          receivePreReleases = !receivePreReleases;
                        });
                        writeSettings(SettingsModal(receivePreReleases: receivePreReleases));
                      },
                      description: loc.receiveBetaUpdatesDesc,
                    ),
                    ToggleItem(
                        label: loc.fasterDownloading,
                        value: fasterDownloads,
                        onTapFunction: () {
                          setState(() {
                            fasterDownloads = !fasterDownloads;
                          });
                          writeSettings(SettingsModal(fasterDownloads: fasterDownloads));
                        },
                        description: loc.fasterDownloadingDesc),
                    ToggleItem(
                        label: loc.queuedDownloads,
                        value: useQueuedDownloads,
                        description: loc.queuedDownloadsDesc,
                        onTapFunction: () {
                          setState(() {
                            useQueuedDownloads = !useQueuedDownloads;
                            writeSettings(SettingsModal(useQueuedDownloads: useQueuedDownloads));
                          });
                        }),
                    InkWell(
                      onTap: () async {
                        String? dir;
                        if (Platform.isWindows) {
                          dir = await FilePickerWindows().getDirectoryPath();
                        } else if(Platform.isLinux) {
                          dir = await FilePickerLinux().getDirectoryPath();
                        } else {
                          dir = await FilePickerIO().getDirectoryPath();
                        }
                        if (dir == null) return;
                        print("Path set to: $dir");
                        await Settings().writeSettings(SettingsModal(downloadPath: dir));
                        setState(() {});
                        floatingSnackBar("might need to provide 'allow access to all files' while downloading!");
                      },
                      child: Container(
                        padding: EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.downloadPath,
                                  style: textStyle(),
                                ),
                                Text(
                                  currentUserSettings?.downloadPath ?? '/storage/emulated/0/Download/KumaAnime',
                                  style: textStyle().copyWith(color: appTheme.textSubColor, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            Icon(Icons.navigate_next_rounded)
                          ],
                        ),
                      ),
                    ),
                    ClickableItem(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          showDragHandle: true,
                          isScrollControlled: true,
                          builder: (context) => _providerSheet(context),
                        );
                      },
                      label: loc.defaultProvider,
                      description:
                          (currentUserSettings?.preferredProvider ?? sources.first.identifier).replaceAll('_', ' '),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    ClickableItem(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => PluginPage()));
                      },
                      label: loc.manageProviders,
                      description: loc.manageProvidersDesc,
                      suffixIcon: Icon(Icons.navigate_next_rounded),
                    ),
                    ToggleItem(
                      onTapFunction: () {
                        setState(() {
                          enableLogging = !enableLogging;
                        });
                        writeSettings(SettingsModal(enableLogging: enableLogging));
                      },
                      label: loc.enableLogging,
                      description: loc.enableLoggingDesc,
                      value: enableLogging,
                    ),
                    ClickableItem(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          showDragHandle: true,
                          isScrollControlled: true,
                          backgroundColor: appTheme.modalSheetBackgroundColor,
                          builder: (context) => _dnsSheet(context),
                        );
                      },
                      label: "Secure DNS",
                      description: _dnsOptions[dnsProvider] ?? 'Off',
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    )
                  ],
                ),
              ),
            )
          : Container(),
    );
  }

  StatefulBuilder _providerSheet(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setcState) => Container(
        padding: const EdgeInsets.only(
          top: 10,
          left: 20,
          right: 20,
        ),
        margin: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                AppLocalizations.of(context).selectProvider,
                style: textStyle().copyWith(fontSize: 23),
                textAlign: TextAlign.left,
              ),
            ),
            ListView.builder(
                shrinkWrap: true,
                itemCount: sources.length,
                itemBuilder: (context, index) {
                  final activeProvider = currentUserSettings?.preferredProvider ?? sources.first.identifier;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: sources[index].identifier == activeProvider
                          ? appTheme.accentColor
                          : appTheme.backgroundSubColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          await writeSettings(SettingsModal(preferredProvider: sources[index].identifier));
                          setState(() {});
                          setcState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          child: Text(
                            sources[index].name,
                            style: textStyle().copyWith(
                              color: sources[index].identifier == activeProvider
                                  ? appTheme.onAccent
                                  : appTheme.textMainColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }

  Widget _dnsSheet(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setSheet) => Container(
        padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
        margin: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text("Secure DNS", style: textStyle().copyWith(fontSize: 23)),
            ),
            ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: _dnsOptions.entries.map((entry) {
                final selected = entry.key == dnsProvider;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: selected ? appTheme.accentColor : appTheme.backgroundSubColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        await writeSettings(SettingsModal(dnsProvider: entry.key));
                        setState(() {});
                        setSheet(() {});
                        if (mounted) Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Text(
                          entry.value,
                          style: textStyle().copyWith(
                            fontSize: 16,
                            color: selected ? appTheme.onAccent : appTheme.textMainColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
