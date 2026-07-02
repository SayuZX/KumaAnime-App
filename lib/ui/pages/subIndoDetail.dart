import 'dart:io';

import 'package:kumaanime/core/anime/providers/otakudesu.dart';
import 'package:kumaanime/core/anime/providers/subIndoTypes.dart';
import 'package:kumaanime/core/anime/providers/types.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/playerControllers/betterPlayer.dart';
import 'package:kumaanime/ui/models/playerControllers/fvp.dart';
import 'package:kumaanime/ui/models/providers/playerDataProvider.dart';
import 'package:kumaanime/ui/models/providers/playerProvider.dart';
import 'package:kumaanime/ui/models/widgets/appWrapper.dart';
import 'package:kumaanime/ui/models/widgets/sourceTile.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/ui/pages/watch.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SubIndoDetailPage extends StatefulWidget {
  final String animeId;

  const SubIndoDetailPage({super.key, required this.animeId});

  @override
  State<SubIndoDetailPage> createState() => _SubIndoDetailPageState();
}

class _SubIndoDetailPageState extends State<SubIndoDetailPage> {
  final _provider = OtakuDesu();

  SubIndoAnimeDetail? _detail;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final detail = await _provider.getDetail(widget.animeId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      appBar: settingPagesAppBar(context),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: appTheme.accentColor))
          : _error
              ? _errorBody(loc)
              : _content(loc),
    );
  }

  Widget _errorBody(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            loc.subIndoLoadError,
            textAlign: TextAlign.center,
            style: TextStyle(color: appTheme.textSubColor, fontFamily: "NotoSans", fontSize: 16),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: appTheme.accentColor,
              foregroundColor: appTheme.onAccent,
            ),
            child: Text(loc.retry),
          ),
        ],
      ),
    );
  }

  Widget _content(AppLocalizations loc) {
    final detail = _detail!;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).padding.left + 20,
        right: MediaQuery.of(context).padding.right + 20,
        bottom: MediaQuery.of(context).padding.bottom + 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 200,
                width: 140,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                child: CachedNetworkImage(
                  imageUrl: detail.poster,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: appTheme.backgroundSubColor),
                  errorWidget: (context, url, error) =>
                      Container(color: appTheme.backgroundSubColor),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.title,
                      style: TextStyle(
                        color: appTheme.textMainColor,
                        fontFamily: "Rubik",
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (detail.japanese != null && detail.japanese!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          detail.japanese!,
                          style: TextStyle(color: appTheme.textSubColor, fontFamily: "NotoSans"),
                        ),
                      ),
                    const SizedBox(height: 10),
                    _metaLine(Icons.live_tv_rounded, [detail.type, detail.status]),
                    _metaLine(Icons.star_rounded, [detail.score]),
                    _metaLine(Icons.timer_outlined, [detail.duration]),
                    _metaLine(Icons.calendar_month_rounded, [detail.aired]),
                    _metaLine(Icons.business_rounded, [detail.studios]),
                  ],
                ),
              ),
            ],
          ),
          if (detail.genres.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: detail.genres
                    .map((genre) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: appTheme.backgroundSubColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            genre.title,
                            style: TextStyle(color: appTheme.textMainColor, fontFamily: "NotoSans"),
                          ),
                        ))
                    .toList(),
              ),
            ),
          if (detail.synopsis.isNotEmpty) ...[
            _sectionTitle(loc.subIndoSynopsis),
            Text(
              detail.synopsis,
              style: TextStyle(color: appTheme.textSubColor, fontFamily: "NotoSans", fontSize: 15),
            ),
          ],
          _sectionTitle(detail.isMovie
              ? loc.movie
              : "${loc.subIndoEpisodes}${detail.episodes != null && detail.episodes!.isNotEmpty ? " (${detail.episodes})" : ""}"),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: detail.episodeList.length,
            itemBuilder: (context, index) {
              final episode = detail.episodeList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: appTheme.backgroundSubColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        isScrollControlled: true,
                        builder: (context) => _SubIndoServerSheet(
                          detail: detail,
                          episodeIndex: index,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                            detail.isMovie ? Icons.movie_outlined : Icons.play_circle_outline_rounded,
                            color: appTheme.accentColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              detail.isMovie && detail.episodeList.length == 1
                                  ? loc.watchMovie
                                  : "${loc.episode} ${episode.episodeNumber}",
                              style: TextStyle(
                                color: appTheme.textMainColor,
                                fontFamily: "NotoSans",
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: appTheme.textSubColor),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _metaLine(IconData icon, List<String?> values) {
    final text = values.where((e) => e != null && e.isNotEmpty).join(" • ");
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: appTheme.textSubColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: appTheme.textSubColor, fontFamily: "NotoSans"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: appTheme.textMainColor,
          fontFamily: "Rubik",
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SubIndoServerSheet extends StatefulWidget {
  final SubIndoAnimeDetail detail;
  final int episodeIndex;

  const _SubIndoServerSheet({
    required this.detail,
    required this.episodeIndex,
  });

  @override
  State<_SubIndoServerSheet> createState() => _SubIndoServerSheetState();
}

class _SubIndoServerSheetState extends State<_SubIndoServerSheet> {
  final _provider = OtakuDesu();

  List<VideoStream> _streams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getStreams();
  }

  Future<void> _getStreams() async {
    try {
      await _provider.getStreams(
        widget.detail.episodeList[widget.episodeIndex].episodeLink,
        (list, finished) {
          if (!mounted) return;
          setState(() {
            _streams = _streams + list;
            if (finished) _loading = false;
          });
        },
      );
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openPlayer(int streamIndex) {
    final controller = Platform.isAndroid ? BetterPlayerWrapper() : FvpWrapper();
    final navigatorState = Platform.isWindows ? AppWrapper.navKey.currentState : Navigator.of(context);
    final detail = widget.detail;
    final streams = _streams;

    Navigator.pop(context, true);

    navigatorState?.push(
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (context) => PlayerDataProvider(
                initialStreams: streams,
                initialStream: streams[streamIndex],
                epLinks: detail.episodeList,
                showTitle: detail.title,
                coverImageUrl: detail.poster,
                showId: 0,
                selectedSource: "otakudesu_inbuilt",
                startIndex: widget.episodeIndex,
                altDatabases: const [],
                lastWatchDuration: null,
              ),
            ),
            ChangeNotifierProvider(
              create: (context) => PlayerProvider(controller, true),
            ),
          ],
          child: Watch(controller: controller),
        ),
      ),
    );
  }

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
                  loc.subIndoSelectServer,
                  style: textStyle().copyWith(fontSize: 23),
                ),
                Text(
                  widget.detail.isMovie && widget.detail.episodeList.length == 1
                      ? loc.movie
                      : "${loc.episode} ${widget.detail.episodeList[widget.episodeIndex].episodeNumber}",
                  style: TextStyle(color: appTheme.textSubColor, fontFamily: "Rubik"),
                ),
              ],
            ),
          ),
          if (_streams.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height / 2.5),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: Platform.isAndroid ? 10 : 15),
                itemCount: _streams.length,
                itemBuilder: (context, index) => SourceTile(
                  source: _streams[index],
                  onTap: () => _openPlayer(index),
                ),
              ),
            ),
          if (_loading)
            Container(
              padding: const EdgeInsets.only(bottom: 15, top: 10),
              child: Center(child: CircularProgressIndicator(color: appTheme.accentColor)),
            )
          else if (_streams.isEmpty)
            Container(
              height: 100,
              padding: const EdgeInsets.only(bottom: 10, top: 20),
              child: Center(
                child: Text(
                  loc.subIndoEmpty,
                  style: const TextStyle(fontFamily: "Rubik", fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
