import 'dart:io';

import 'package:kumaanime/core/anime/providers/otakudesu.dart';
import 'package:kumaanime/core/anime/providers/subIndoTypes.dart';
import 'package:kumaanime/core/anime/providers/types.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/subIndoWatched.dart';
import 'package:kumaanime/core/database/database.dart';
import 'package:kumaanime/core/database/handler/handler.dart';
import 'package:kumaanime/core/database/types.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/playerControllers/betterPlayer.dart';
import 'package:kumaanime/ui/models/playerControllers/fvp.dart';
import 'package:kumaanime/ui/models/providers/playerDataProvider.dart';
import 'package:kumaanime/ui/models/providers/playerProvider.dart';
import 'package:kumaanime/ui/models/widgets/appWrapper.dart';
import 'package:kumaanime/ui/models/widgets/cards.dart';
import 'package:kumaanime/ui/models/widgets/loader.dart';
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
  DatabaseInfo? _enriched;
  bool _loading = true;
  bool _error = false;
  bool _enrichLoading = false;
  bool _synopsisExpanded = false;

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
      _loadEnrichment(detail);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Future<void> _loadEnrichment(SubIndoAnimeDetail detail) async {
    setState(() => _enrichLoading = true);
    try {
      final handler = DatabaseHandler(database: Databases.anilist);
      final primary =
          (detail.japanese != null && detail.japanese!.trim().isNotEmpty) ? detail.japanese!.trim() : detail.title;
      var results = await handler.search(primary);
      if (results.isEmpty && primary != detail.title) results = await handler.search(detail.title);
      if (results.isEmpty) {
        if (mounted) setState(() => _enrichLoading = false);
        return;
      }
      final info = await handler.getAnimeInfo(results.first.id);
      if (!mounted) return;
      setState(() {
        _enriched = info;
        _enrichLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _enrichLoading = false);
    }
  }

  void _onWatchNow(SubIndoAnimeDetail detail) {
    if (detail.episodeList.isEmpty) return;
    if (detail.isMovie || detail.episodeList.length == 1) {
      _openServerSheet(detail, 0);
    } else {
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: appTheme.modalSheetBackgroundColor,
        builder: (_) => _EpisodePickerSheet(detail: detail, animeId: widget.animeId),
      );
    }
  }

  void _openServerSheet(SubIndoAnimeDetail detail, int episodeIndex) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      builder: (_) => _SubIndoServerSheet(detail: detail, animeId: widget.animeId, episodeIndex: episodeIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: _loading
          ? Center(child: KumaAnimeLoading(color: appTheme.accentColor, size: 40))
          : _error
              ? _errorBody(loc)
              : _content(loc),
    );
  }

  Widget _errorBody(AppLocalizations loc) {
    return SafeArea(
      child: Stack(
        children: [
          _circleButton(Icons.arrow_back_rounded, () => Navigator.of(context).pop()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.subIndoLoadError,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: appTheme.textSubColor, fontSize: 16),
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
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, void Function() onTap) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        clipBehavior: Clip.hardEdge,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _content(AppLocalizations loc) {
    final detail = _detail!;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 300,
          backgroundColor: appTheme.backgroundColor,
          surfaceTintColor: Colors.transparent,
          leadingWidth: 60,
          leading: _circleButton(Icons.arrow_back_rounded, () => Navigator.of(context).pop()),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 56, right: 16, bottom: 14),
            title: LayoutBuilder(
              builder: (context, constraints) {
                final collapsed = constraints.biggest.height <= kToolbarHeight + MediaQuery.of(context).padding.top + 10;
                return AnimatedOpacity(
                  opacity: collapsed ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    detail.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: appTheme.textMainColor, fontSize: 17),
                  ),
                );
              },
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: detail.poster,
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.25),
                  colorBlendMode: BlendMode.darken,
                  placeholder: (context, url) => Container(color: appTheme.backgroundSubColor),
                  errorWidget: (context, url, error) => Container(color: appTheme.backgroundSubColor),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        appTheme.backgroundColor.withValues(alpha: 0.6),
                        appTheme.backgroundColor,
                      ],
                      stops: const [0.35, 0.75, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              left: MediaQuery.of(context).padding.left + 20,
              right: MediaQuery.of(context).padding.right + 20,
              bottom: MediaQuery.of(context).padding.bottom + 30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.title,
                  style: TextStyle(
                    color: appTheme.textMainColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (detail.japanese != null && detail.japanese!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      detail.japanese!,
                      style: TextStyle(color: appTheme.textSubColor, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 12),
                _metaRow(detail),
                const SizedBox(height: 16),
                if (detail.genres.isNotEmpty) _genreChips(detail),
                const SizedBox(height: 18),
                _watchButton(loc, detail),
                ..._synopsisSection(loc, detail),
                ..._tagsSection(loc),
                ..._charactersSection(loc),
                ..._recommendedSection(loc),
                if (_enrichLoading && _enriched == null) ...[
                  const SizedBox(height: 30),
                  Center(child: KumaAnimeLoading(color: appTheme.accentColor, size: 28)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaRow(SubIndoAnimeDetail detail) {
    final items = <Widget>[];
    void add(IconData icon, String? value, {Color? iconColor}) {
      if (value == null || value.trim().isEmpty) return;
      items.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor ?? appTheme.textSubColor),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: appTheme.textSubColor, fontSize: 13)),
        ],
      ));
    }

    add(Icons.star_rounded, detail.score, iconColor: const Color(0xFFF5C518));
    add(Icons.live_tv_rounded, detail.type);
    add(Icons.podcasts_rounded, detail.status);
    add(Icons.confirmation_num_outlined, detail.episodes != null ? "${detail.episodes} eps" : null);
    add(Icons.timer_outlined, detail.duration);

    return Wrap(spacing: 16, runSpacing: 8, children: items);
  }

  Widget _genreChips(SubIndoAnimeDetail detail) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: detail.genres.map((genre) => _pill(genre.title)).toList(),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: appTheme.backgroundSubColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: appTheme.textMainColor, fontSize: 12),
      ),
    );
  }

  Widget _watchButton(AppLocalizations loc, SubIndoAnimeDetail detail) {
    if (detail.episodeList.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _onWatchNow(detail),
        style: ElevatedButton.styleFrom(
          backgroundColor: appTheme.accentColor,
          foregroundColor: appTheme.onAccent,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 26),
        label: Text(
          detail.isMovie ? loc.watchMovie : loc.subIndoWatchNow,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  List<Widget> _synopsisSection(AppLocalizations loc, SubIndoAnimeDetail detail) {
    final text = detail.synopsis.isNotEmpty ? detail.synopsis : (_enriched?.synopsis ?? '');
    if (text.isEmpty) return [];
    return [
      const SizedBox(height: 24),
      _sectionTitle(loc.subIndoSynopsis),
      const SizedBox(height: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: _synopsisExpanded ? double.infinity : 90),
              child: Text(
                text,
                overflow: _synopsisExpanded ? TextOverflow.visible : TextOverflow.fade,
                style: TextStyle(color: appTheme.textSubColor, fontSize: 14, height: 1.5),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _synopsisExpanded = !_synopsisExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _synopsisExpanded ? loc.showLess : loc.showMore,
                style: TextStyle(color: appTheme.accentColor, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _tagsSection(AppLocalizations loc) {
    final tags = _enriched?.tags ?? [];
    if (tags.isEmpty) return [];
    return [
      const SizedBox(height: 24),
      _sectionTitle(loc.subIndoTags),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: tags.map(_pill).toList()),
    ];
  }

  List<Widget> _charactersSection(AppLocalizations loc) {
    final chars = _enriched?.characters ?? [];
    if (chars.isEmpty) return [];
    return [
      const SizedBox(height: 24),
      _sectionTitle(loc.subIndoCharacters),
      const SizedBox(height: 12),
      SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: chars.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => _characterCard(chars[index]),
        ),
      ),
    ];
  }

  Widget _characterCard(Map<String, dynamic> character) {
    final name = (character['name'] ?? '').toString();
    final role = (character['role'] ?? '').toString();
    final image = (character['image'] ?? '').toString();
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: image,
              height: 150,
              width: 110,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(height: 150, width: 110, color: appTheme.backgroundSubColor),
              errorWidget: (_, __, ___) => Container(
                height: 150,
                width: 110,
                color: appTheme.backgroundSubColor,
                child: Icon(Icons.person_rounded, color: appTheme.textSubColor),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: appTheme.textMainColor, fontSize: 13),
          ),
          if (role.isNotEmpty)
            Text(
              role,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: appTheme.textSubColor, fontSize: 11),
            ),
        ],
      ),
    );
  }

  List<Widget> _recommendedSection(AppLocalizations loc) {
    final recs = _enriched?.recommended ?? [];
    if (recs.isEmpty) return [];
    return [
      const SizedBox(height: 24),
      _sectionTitle(loc.subIndoRecommended),
      const SizedBox(height: 12),
      SizedBox(
        height: 235,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: recs.length,
          itemBuilder: (context, index) {
            final r = recs[index];
            return Cards.animeCard(
              r.id,
              r.title['english'] ?? r.title['romaji'] ?? '',
              r.cover,
              isMobile: true,
              rating: r.rating,
            );
          },
        ),
      ),
    ];
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: appTheme.textMainColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _EpisodePickerSheet extends StatefulWidget {
  final SubIndoAnimeDetail detail;
  final String animeId;

  const _EpisodePickerSheet({required this.detail, required this.animeId});

  @override
  State<_EpisodePickerSheet> createState() => _EpisodePickerSheetState();
}

class _EpisodePickerSheetState extends State<_EpisodePickerSheet> {
  Set<int> _watched = {};
  int? _lastWatched;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final watched = await SubIndoWatched.getWatched(widget.animeId);
    final last = await SubIndoWatched.getLast(widget.animeId);
    if (mounted) {
      setState(() {
        _watched = watched;
        _lastWatched = last;
      });
    }
  }

  void _openServerSheet(int episodeIndex) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      builder: (_) => _SubIndoServerSheet(detail: widget.detail, animeId: widget.animeId, episodeIndex: episodeIndex),
    ).then((_) => _reload());
  }

  Future<void> _markAll() async {
    await SubIndoWatched.markAll(widget.animeId, widget.detail.episodeList.map((e) => e.episodeNumber).toList());
    await _reload();
  }

  void _confirmReset(AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appTheme.modalSheetBackgroundColor,
        content: Text(loc.resetProgressConfirm, style: TextStyle(color: appTheme.textMainColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () async {
              await SubIndoWatched.reset(widget.animeId);
              await _reload();
              if (mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: appTheme.accentColor),
            child: Text(loc.resetProgress),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final detail = widget.detail;
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(loc.subIndoSelectEpisode, style: textStyle().copyWith(fontSize: 22)),
              ),
              IconButton(
                tooltip: loc.markAllWatched,
                onPressed: _markAll,
                icon: Icon(Icons.done_all_rounded, color: appTheme.textSubColor),
              ),
              IconButton(
                tooltip: loc.resetProgress,
                onPressed: () => _confirmReset(loc),
                icon: Icon(Icons.restart_alt_rounded, color: appTheme.textSubColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(detail.episodeList.length, (index) {
                  final number = detail.episodeList[index].episodeNumber;
                  final isWatched = _watched.contains(number);
                  final isLast = _lastWatched == number;
                  final bg = isLast
                      ? appTheme.accentColor
                      : (isWatched ? appTheme.accentColor.withValues(alpha: 0.16) : appTheme.backgroundSubColor);
                  final fg =
                      isLast ? appTheme.onAccent : (isWatched ? appTheme.accentColor : appTheme.textMainColor);
                  return GestureDetector(
                    onTap: () => _openServerSheet(index),
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: !isLast && isWatched
                            ? Border.all(color: appTheme.accentColor.withValues(alpha: 0.55), width: 1.5)
                            : null,
                      ),
                      child: Text(
                        "$number",
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubIndoServerSheet extends StatefulWidget {
  final SubIndoAnimeDetail detail;
  final String animeId;
  final int episodeIndex;

  const _SubIndoServerSheet({
    required this.detail,
    required this.animeId,
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

    SubIndoWatched.mark(widget.animeId, detail.episodeList[widget.episodeIndex].episodeNumber);

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
                  style: TextStyle(color: appTheme.textSubColor, ),
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
              child: Center(child: KumaAnimeLoading(color: appTheme.accentColor, size: 40)),
            )
          else if (_streams.isEmpty)
            Container(
              height: 100,
              padding: const EdgeInsets.only(bottom: 10, top: 20),
              child: Center(
                child: Text(
                  loc.subIndoEmpty,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
