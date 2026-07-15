import 'dart:io';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/settings.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/sources.dart';
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

  final sources = SourceManager.instance.sources;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: loaded
          ? buildFluentSettingsBody(
              child: SingleChildScrollView(
                child: Padding(
                  padding: pagePadding(context, bottom: true),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      settingPagesTitleHeader(context, loc.generalTitle),

                      buildFluentSettingsSectionHeader("Downloads & Providers"),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: buildFluentSettingsCard(
                          children: [
                            buildFluentSettingsTile(
                              context: context,
                              icon: Icons.folder_open_rounded,
                              title: loc.downloadPath,
                              description: currentUserSettings?.downloadPath ?? '/storage/emulated/0/Download/KumaAnime',
                              trailing: Icon(Icons.navigate_next_rounded, color: appTheme.textSubColor),
                              onTap: () async {
                                String? dir;
                                if (Platform.isWindows) {
                                  dir = await FilePickerWindows().getDirectoryPath();
                                } else if (Platform.isLinux) {
                                  dir = await FilePickerLinux().getDirectoryPath();
                                } else {
                                  dir = await FilePickerIO().getDirectoryPath();
                                }
                                if (dir == null) return;
                                await Settings().writeSettings(SettingsModal(downloadPath: dir));
                                setState(() {});
                                floatingSnackBar(loc.genAllowAllFilesHint);
                              },
                            ),
                            buildFluentSettingsTile(
                              context: context,
                              icon: Icons.speed_rounded,
                              title: loc.fasterDownloading,
                              description: loc.fasterDownloadingDesc,
                              trailing: Switch(
                                value: fasterDownloads,
                                onChanged: (val) {
                                  setState(() {
                                    fasterDownloads = val;
                                  });
                                  writeSettings(SettingsModal(fasterDownloads: val));
                                },
                              ),
                            ),
                            buildFluentSettingsTile(
                              context: context,
                              icon: Icons.queue_play_next_rounded,
                              title: loc.queuedDownloads,
                              description: loc.queuedDownloadsDesc,
                              trailing: Switch(
                                value: useQueuedDownloads,
                                onChanged: (val) {
                                  setState(() {
                                    useQueuedDownloads = val;
                                  });
                                  writeSettings(SettingsModal(useQueuedDownloads: val));
                                },
                              ),
                            ),
                            buildFluentSettingsTile(
                              context: context,
                              icon: Icons.api_rounded,
                              title: loc.defaultProvider,
                              description: (currentUserSettings?.preferredProvider ?? sources.first.identifier).replaceAll('_', ' '),
                              trailing: Icon(Icons.arrow_drop_down, color: appTheme.textSubColor),
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  showDragHandle: true,
                                  isScrollControlled: true,
                                  builder: (context) => _providerSheet(context),
                                );
                              },
                            ),
                            buildFluentSettingsTile(
                              context: context,
                              icon: Icons.extension_rounded,
                              title: loc.manageProviders,
                              description: loc.manageProvidersDesc,
                              trailing: Icon(Icons.navigate_next_rounded, color: appTheme.textSubColor),
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => PluginPage()));
                              },
                            ),
                          ],
                        ),
                      ),

                      buildFluentSettingsSectionHeader("System & Diagnostics"),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: buildFluentSettingsCard(
                          children: [
                            buildFluentSettingsTile(
                              context: context,
                              icon: Icons.bug_report_rounded,
                              title: loc.showErrors,
                              description: "Display diagnostic errors in playback interface",
                              trailing: Switch(
                                value: showErrorsButtonState,
                                onChanged: (val) {
                                  setState(() {
                                    showErrorsButtonState = val;
                                  });
                                  writeSettings(SettingsModal(showErrors: val));
                                },
                              ),
                            ),
                            buildFluentSettingsTile(
                              context: context,
                              icon: Icons.update_rounded,
                              title: loc.receiveBetaUpdates,
                              description: loc.receiveBetaUpdatesDesc,
                              trailing: Switch(
                                value: receivePreReleases,
                                onChanged: (val) {
                                  setState(() {
                                    receivePreReleases = val;
                                  });
                                  writeSettings(SettingsModal(receivePreReleases: val));
                                },
                              ),
                            ),
                            buildFluentSettingsTile(
                              context: context,
                              icon: Icons.receipt_long_rounded,
                              title: loc.enableLogging,
                              description: loc.enableLoggingDesc,
                              trailing: Switch(
                                value: enableLogging,
                                onChanged: (val) {
                                  setState(() {
                                    enableLogging = val;
                                  });
                                  writeSettings(SettingsModal(enableLogging: val));
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
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

}
