import 'dart:convert';
import 'dart:io';

import 'package:kumaanime/core/anime/downloader/downloadManager.dart';
import 'package:kumaanime/core/anime/providers/providerDetails.dart';
import 'package:kumaanime/core/anime/providers/types.dart';
import 'package:kumaanime/core/app/logging.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/commons/extractQuality.dart';
import 'package:kumaanime/core/data/watching.dart';
import 'package:kumaanime/core/commons/enums.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/playerControllers/betterPlayer.dart';
import 'package:kumaanime/ui/models/playerControllers/fvp.dart';
import 'package:kumaanime/ui/models/providers/infoProvider.dart';
import 'package:kumaanime/ui/models/providers/playerDataProvider.dart';
import 'package:kumaanime/ui/models/providers/playerProvider.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/appWrapper.dart';
import 'package:kumaanime/ui/models/widgets/sourceTile.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/ui/pages/watch.dart';
import 'package:flutter/material.dart';
import 'package:kumaanime/ui/models/sources.dart';
import 'package:provider/provider.dart';

class ServerSelectionBottomSheet extends StatefulWidget {
  final InfoProvider provider;
  final ServerSheetType type;
  final int episodeIndex;

  const ServerSelectionBottomSheet({
    super.key,
    required this.provider,
    required this.episodeIndex,
    required this.type,
  });

  @override
  State<ServerSelectionBottomSheet> createState() => ServerSelectionBottomSheetState();
}

class ServerSelectionBottomSheetState extends State<ServerSelectionBottomSheet> {
  List<VideoStream> streamSources = [];
  List<Map<String, String>> qualities = [];

  final src = SourceManager.instance;

  Future<void> getStreams(InfoProvider provider, {bool directElseBlock = false}) async {
    streamSources = [];
    if (widget.type == ServerSheetType.download && !directElseBlock) {
      try {
        await src.getDownloadSources(
          widget.provider.selectedSource.identifier,
          widget.provider.epLinks[widget.episodeIndex].episodeLink,
          dub: provider.preferDubs,
          metadata: provider.epLinks[widget.episodeIndex].metadata,
          (list, finished) {
            final loc = AppLocalizations.of(context);
            if (mounted)
              setState(() {
                if (finished) {
                  _isLoading = widget.type == ServerSheetType.download ? true : false;
                }
                streamSources = streamSources + list;
                if (widget.type == ServerSheetType.download) {
                  list.forEach((element) async {
                    qualities.add({
                      'url': element.url,
                      'server': "${element.server}  ${element.backup ? "- ${loc.sssBackup}" : ""}",
                      'quality': "${element.quality}",
                      'headers': jsonEncode(element.customHeaders),
                      'subtitle': element.subtitle ?? "",
                    });
                  });
                  if (mounted)
                    setState(() {
                      _isLoading = false;
                    });
                }
              });
          },
        );
      } catch (err) {
        if (err is UnimplementedError) {
          getStreams(provider, directElseBlock: true);
        }
      }
    } else {
      await src.getStreams(
          widget.provider.selectedSource.identifier, widget.provider.epLinks[widget.episodeIndex].episodeLink,
          dub: provider.preferDubs, metadata: provider.epLinks[widget.episodeIndex].metadata, (list, finished) {
        final loc = AppLocalizations.of(context);
        if (mounted)
          setState(() {
            if (finished) {
              if (widget.type == ServerSheetType.watch) {
                _aggregateOtherProviders(provider);
              } else {
                _isLoading = true;
              }
            }
            streamSources = streamSources + list;
            if (widget.type == ServerSheetType.download) {
              list.forEach((element) async {
                // auto or multi quality would mean multiple qualities
                if (element.quality == "multi-quality" || element.quality == "auto") {
                  await getQualities(element);
                } else {
                  qualities.add({
                    'url': element.url,
                    'server': "${element.server}  ${element.backup ? "- ${loc.sssBackup}" : ""}",
                    'quality': "${element.quality}",
                    'headers': jsonEncode(element.customHeaders ?? {}),
                    'subtitle': element.subtitle ?? "",
                  });
                }
              });
              if (mounted)
                setState(() {
                  _isLoading = false;
                });
            }
          });
      });
    }
  }

  Future<void> getQualities(VideoStream source) async {
    final loc = AppLocalizations.of(context);
    List<Map<String, String>> mainList = [];

    final ParsedHlsMaster list = await parseMasterPlaylist(source.url, customHeader: source.customHeaders).catchError((e) {
      Logs.app.log("${source.server}: $e");
      return ParsedHlsMaster(audioStreams: [], qualityStreams: []);
    });
    list.qualityStreams.forEach((element) {
      final map = element.toMap();
      map['bandwidth'] = map['bandwidth']?.toString();
      map['server'] = "${source.server} ${source.backup ? "- ${loc.sssBackup}" : ""}";
      map['subtitle'] = source.subtitle ?? "";
      map['headers'] = jsonEncode(source.customHeaders ?? {});
      mainList.add(map.cast());
    });
    // if (mounted)
    setState(() {
      //     _isLoading = false;
      qualities = qualities + mainList;
    });
  }

  bool _aggregating = false;

  void _mergeStreams(List<VideoStream> incoming) {
    final existing = streamSources.map((e) => e.url).toSet();
    for (final stream in incoming) {
      if (existing.add(stream.url)) streamSources.add(stream);
    }
  }

  Future<List<VideoStream>> _resolveProviderStreams(
      ProviderDetails source, String query, String romaji, int targetEpNum, bool dub) async {
    src.useInbuiltProviders = source.version == "0.0.0.0";

    List<Map<String, String?>> results = [];
    for (final q in [query, romaji]) {
      if (q.trim().isEmpty) continue;
      results = await src.searchInSource(source.identifier, q);
      if (results.isNotEmpty) break;
    }
    if (results.isEmpty) return [];

    final exact = results.where((e) => (e['name'] ?? '').toLowerCase() == query.toLowerCase()).toList();
    final match = exact.isNotEmpty ? exact.first : results.first;
    final alias = match['alias'];
    if (alias == null) return [];

    final episodes = await src.getAnimeEpisodes(source.identifier, alias, dub: dub);
    if (episodes.isEmpty) return [];

    final ep = episodes.firstWhere(
      (e) => e.episodeNumber == targetEpNum,
      orElse: () => widget.episodeIndex < episodes.length ? episodes[widget.episodeIndex] : episodes.first,
    );

    final collected = <VideoStream>[];
    await src.getStreams(source.identifier, ep.episodeLink, dub: dub, metadata: ep.metadata, (list, finished) {
      collected.addAll(list);
    });
    return collected;
  }

  Future<void> _aggregateOtherProviders(InfoProvider provider) async {
    if (_aggregating) return;
    _aggregating = true;

    final titles = provider.data.title;
    final query = (titles['english'] ?? titles['romaji'] ?? '').trim();
    final romaji = (titles['romaji'] ?? '').trim();
    final targetEpNum = provider.epLinks[widget.episodeIndex].episodeNumber;
    final dub = provider.preferDubs;

    final selectedId = provider.selectedSource.identifier.replaceAll("_inbuilt", "");
    final seen = <String>{selectedId};
    final others =
        src.inbuiltSources.where((s) => seen.add(s.identifier.replaceAll("_inbuilt", ""))).toList();

    for (final source in others) {
      if (!mounted) break;
      try {
        final streams =
            await _resolveProviderStreams(source, query, romaji, targetEpNum, dub).timeout(const Duration(seconds: 12));
        if (streams.isEmpty || !mounted) continue;
        setState(() => _mergeStreams(streams));
      } catch (err) {
        Logs.app.log("[AGGREGATE] ${source.identifier} failed: $err");
      }
    }

    if (mounted) setState(() => _isLoading = false);
    _aggregating = false;
  }

  @override
  void initState() {
    super.initState();
    getStreams(widget.provider);
  }

  bool _isLoading = true;

  int? hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: MediaQuery.of(context).padding.bottom),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(bottom: 10, left: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.sssSelectServer,
                  style: textStyle().copyWith(fontSize: 23),
                ),
                Text(
                  loc.sssEpisodeNumber(widget.episodeIndex + 1),
                 style: TextStyle(color: appTheme.textSubColor, )
                ),
              ],
            ),
          ),
          _isLoading
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (streamSources.isNotEmpty) _list(),
                      Container(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: appTheme.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : streamSources.isNotEmpty
                  ? Container(
                      height: MediaQuery.of(context).orientation == Orientation.landscape
                          ? MediaQuery.of(context).size.height / 2
                          : MediaQuery.of(context).size.height / 3,
                      child: _list(),
                    )
                  : Container(
                      height: 100,
                      padding: EdgeInsets.only(bottom: 10, top: 20),
                      child: Center(
                        child: Text(
                          loc.sssEmptyServers,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    )
        ],
      ),
    );
  }

  ListView _list() {
    final titles = widget.provider.data.title;
    final defaulTitle = titles['english'] ?? titles['romaji'] ?? "";
    final title = (currentUserSettings?.nativeTitle ?? false) ? titles['native'] ?? defaulTitle : defaulTitle;

    return widget.type == ServerSheetType.watch
        ? ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: Platform.isAndroid ? 10 : 15),
            shrinkWrap: true,
            itemCount: streamSources.length,
            itemBuilder: (context, index) {
              final source = streamSources[index];

              return SourceTile(
                source: source,
                onTap: () async {
                  // return print(streamSources[index]);

                  await storeWatching(
                    title,
                    widget.provider.data.cover,
                    widget.provider.id,
                    widget.episodeIndex,
                    totalEpisodes: widget.provider.data.episodes,
                    alternateDatabases: widget.provider.altDatabases,
                    rating: widget.provider.data.rating,
                  );

                  final controller = Platform.isAndroid ? BetterPlayerWrapper() : FvpWrapper();
                  final provider = widget.provider;
                  final navigatorState = (Platform.isWindows ? AppWrapper.navKey.currentState : Navigator.of(context));

                  Navigator.pop(context, true);

                  navigatorState
                      ?.push(
                    MaterialPageRoute(
                      builder: (context) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider(
                            create: (context) => PlayerDataProvider(
                              initialStreams: streamSources,
                              initialStream: streamSources[index],
                              epLinks: provider.epLinks,
                              showTitle: title,
                              coverImageUrl: widget.provider.data.cover,
                              showId: provider.id,
                              selectedSource: provider.selectedSource.identifier,
                              startIndex: widget.episodeIndex,
                              altDatabases: provider.altDatabases,
                              preferDubs: provider.preferDubs,
                              lastWatchDuration: provider.lastWatchedDurationMap?[
                                  provider.watched < provider.epLinks.length ? provider.watched + 1 : provider.watched],
                            ),
                          ),
                          ChangeNotifierProvider(
                            create: (context) => PlayerProvider(controller, true),
                          ),
                        ],
                        child: Watch(
                          controller: controller,
                        ),
                      ),
                    ),
                  )
                      .then((value) {
                    provider.getWatched(refreshLastWatchDuration: true);
                  });
                },
              );
            },
          )
        : ListView.builder(
            itemCount: qualities.length,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, ind) =>
                _DownloadTile(quality: qualities[ind], widget: widget, title: title),
          );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({
    required this.quality,
    required this.widget,
    required this.title,
  });

  final Map<String, String> quality;
  final ServerSelectionBottomSheet widget;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: ElevatedButton(
        onPressed: () {
          String? subs = quality['subtitle'];
          subs = (subs?.isEmpty ?? true) ? null : subs;
          // print(qualities[ind]);
          final mapped = jsonDecode(quality['headers'] ?? "{}");
          Map<String, String> headers = Map.from(mapped).cast();

          final episodeNum = "${widget.episodeIndex + 1}";

          final fileName = "${title} EP ${episodeNum.padLeft(2, '0')}";
          final streamLink = quality['url']!;
          // print(streamLink);

          DownloadManager()
              .addDownloadTask(
            streamLink,
            fileName,
            customHeaders: headers,
            subtitleUrl: subs,
          )
              .onError((err, st) {
            print(err);
            print(st);
            floatingSnackBar("$err");
          });
          Navigator.of(context).pop();
          floatingSnackBar(AppLocalizations.of(context).sssDownloadingEpisode);
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: appTheme.backgroundSubColor,
          padding: EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${quality['server']}",
                        style: TextStyle(
                          color: appTheme.accentColor,
                          fontSize: 18,
                          ),
                      ),
                      Text(
                        "${quality['quality']}",
                        style: TextStyle(
                          color: appTheme.textMainColor,
                          fontSize: 18,
                          ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
