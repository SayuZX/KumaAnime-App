import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:kumaanime/ui/models/widgets/backButton.dart';

import 'package:kumaanime/core/anime/providers/animeLangSource.dart';
import 'package:kumaanime/core/anime/providers/otakudesu.dart';
import 'package:kumaanime/ui/models/widgets/loader.dart';
import 'package:kumaanime/core/anime/providers/subIndoTypes.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/widgets/cards/subIndoCard.dart';
import 'package:kumaanime/ui/pages/subIndoDetail.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

enum _SubIndoMode { ongoing, completed, genre, search }

class SubIndoPage extends StatefulWidget {
  final AnimeLangSource? source;
  final String? pageTitle;
  final String? searchHint;

  const SubIndoPage({super.key, this.source, this.pageTitle, this.searchHint});

  @override
  State<SubIndoPage> createState() => _SubIndoPageState();
}

class _SubIndoPageState extends State<SubIndoPage> with SingleTickerProviderStateMixin {
  late final AnimeLangSource _provider = widget.source ?? OtakuDesu();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late final AnimationController _enterController;

  _SubIndoMode _mode = _SubIndoMode.ongoing;
  SubIndoGenre? _selectedGenre;
  List<SubIndoGenre> _genres = [];
  List<SubIndoAnime> _items = [];
  int _page = 1;
  bool _hasNextPage = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _error = false;

  int _heroIndex = 0;
  Timer? _heroTimer;
  final _heroController = PageController(viewportFraction: 0.82);

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 550))..forward();
    _scrollController.addListener(_onScroll);
    _loadGenres();
    _load(reset: true);
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroController.dispose();
    _enterController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startHeroRotation() {
    _heroTimer?.cancel();
    final isHeroMode = _mode == _SubIndoMode.ongoing || _mode == _SubIndoMode.completed;
    if (!isHeroMode || _items.length < 2) return;
    _heroTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_heroController.hasClients) return;
      final pool = _items.length < 8 ? _items.length : 8;
      final next = (_heroIndex + 1) % pool;
      _heroController.animateToPage(next, duration: const Duration(milliseconds: 550), curve: Curves.easeOutCubic);
    });
  }

  Widget _entrance(Widget child, double start, double end) {
    final anim = CurvedAnimation(parent: _enterController, curve: Interval(start, end, curve: Curves.easeOut));
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.18), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300 &&
        _hasNextPage &&
        !_loadingMore &&
        !_loading) {
      _load();
    }
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await _provider.getGenres();
      if (mounted) setState(() => _genres = genres);
    } catch (_) {}
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = false;
        _items = [];
        _page = 1;
        _hasNextPage = false;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      List<SubIndoAnime> newItems;
      bool hasNext = false;
      switch (_mode) {
        case _SubIndoMode.ongoing:
          final res = await _provider.getOngoing(page: _page);
          newItems = res.items;
          hasNext = res.hasNextPage;
        case _SubIndoMode.completed:
          final res = await _provider.getCompleted(page: _page);
          newItems = res.items;
          hasNext = res.hasNextPage;
        case _SubIndoMode.genre:
          final res = await _provider.getByGenre(_selectedGenre!.genreId, page: _page);
          newItems = res.items;
          hasNext = res.hasNextPage;
        case _SubIndoMode.search:
          newItems = await _provider.searchAnime(_searchController.text.trim());
          hasNext = false;
      }
      if (!mounted) return;
      setState(() {
        _items = _items + newItems;
        _hasNextPage = hasNext;
        _page = _page + 1;
        _loading = false;
        _loadingMore = false;
      });
      _startHeroRotation();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _switchMode(_SubIndoMode mode, {SubIndoGenre? genre}) {
    _mode = mode;
    _selectedGenre = genre;
    _heroIndex = 0;
    _heroTimer?.cancel();
    _load(reset: true);
  }

  void _openDetail(SubIndoAnime anime) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => SubIndoDetailPage(animeId: anime.animeId, source: _provider)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _entrance(_vintageHeader(context, loc), 0.0, 0.6),
          _entrance(
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12),
              child: _searchField(loc),
            ),
            0.3,
            1.0,
          ),
          _entrance(
            Container(
              height: 44,
              margin: const EdgeInsets.only(top: 14),
              child: _filterChips(loc),
            ),
            0.3,
            1.0,
          ),
          Expanded(
            child: Stack(
              children: [
                _body(loc),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            appTheme.backgroundColor,
                            appTheme.backgroundColor.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vintageHeader(BuildContext context, AppLocalizations loc) {
    final topInset = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.only(top: topInset + 10, left: 20, right: 20, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: appTheme.backgroundSubColor,
            shape: const CircleBorder(),
            clipBehavior: Clip.hardEdge,
            child: KumaBackButton(size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            widget.pageTitle ?? loc.subIndo,
            style: TextStyle(
              color: appTheme.textMainColor,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField(AppLocalizations loc) {
    return TextField(
      controller: _searchController,
      onSubmitted: (value) {
        if (value.trim().isEmpty) return;
        _switchMode(_SubIndoMode.search);
      },
      style: TextStyle(color: appTheme.textMainColor, ),
      decoration: InputDecoration(
        hintText: widget.searchHint ?? loc.subIndoSearchHint,
        hintStyle: TextStyle(color: appTheme.textSubColor, ),
        prefixIcon: Icon(Icons.search_rounded, color: appTheme.textSubColor, size: 22),
        filled: true,
        fillColor: appTheme.backgroundSubColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: appTheme.textSubColor.withValues(alpha: 0.25), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: appTheme.accentColor, width: 1.2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: appTheme.textSubColor.withValues(alpha: 0.25), width: 1),
        ),
      ),
    );
  }

  Widget _filterChips(AppLocalizations loc) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _chip(
          label: loc.subIndoOngoing,
          selected: _mode == _SubIndoMode.ongoing,
          onTap: () => _switchMode(_SubIndoMode.ongoing),
        ),
        _chip(
          label: loc.subIndoCompleted,
          selected: _mode == _SubIndoMode.completed,
          onTap: () => _switchMode(_SubIndoMode.completed),
        ),
        for (final genre in _genres)
          _chip(
            label: genre.title,
            selected: _mode == _SubIndoMode.genre && _selectedGenre?.genreId == genre.genreId,
            onTap: () => _switchMode(_SubIndoMode.genre, genre: genre),
          ),
      ],
    );
  }

  Widget _chip({required String label, required bool selected, required void Function() onTap}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? appTheme.accentColor : appTheme.backgroundSubColor,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? appTheme.accentColor : appTheme.textSubColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? appTheme.onAccent : appTheme.textSubColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations loc) {
    if (_loading) {
      return Center(child: KumaAnimeLoading(color: appTheme.accentColor, size: 40));
    }

    if (_error && _items.isEmpty) {
      return Center(
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
              onPressed: () => _load(reset: true),
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

    if (_items.isEmpty) {
      return Center(
        child: Text(
          loc.subIndoEmpty,
          style: TextStyle(color: appTheme.textSubColor, fontSize: 18),
        ),
      );
    }

    final desktop = Platform.isWindows || Platform.isLinux;
    final showHero = _mode == _SubIndoMode.ongoing || _mode == _SubIndoMode.completed;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (showHero) SliverToBoxAdapter(child: _heroCarousel()),
        SliverPadding(
          padding: EdgeInsets.only(top: 16, left: 15, right: 15, bottom: MediaQuery.of(context).padding.bottom + 20),
          sliver: _layout == 'list'
              ? SliverList.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _listRow(_items[index]),
                  ),
                )
              : SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: (_layout == 'compact' ? (desktop ? 120.0 : 95.0) : (desktop ? 165.0 : 125.0)) *
                        (currentUserSettings?.cardScale ?? 1.0).clamp(0.85, 1.15),
                    mainAxisExtent: (_layout == 'compact' ? (desktop ? 230.0 : 185.0) : (desktop ? 300.0 : 240.0)) *
                        (currentUserSettings?.cardScale ?? 1.0).clamp(0.85, 1.15),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final anime = _items[index];
                    return SubIndoCard(anime: anime, badge: widget.pageTitle, onTap: () => _openDetail(anime));
                  },
                ),
        ),
        if (_loadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Center(child: KumaAnimeLoading(color: appTheme.accentColor, size: 40)),
            ),
          ),
      ],
    );
  }

  String get _layout => currentUserSettings?.listLayout ?? 'grid';

  Widget _listRow(SubIndoAnime anime) {
    return GestureDetector(
      onTap: () => _openDetail(anime),
      child: Container(
        decoration: BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.hardEdge,
        child: Row(
          children: [
            CachedNetworkImage(
              imageUrl: anime.poster,
              width: 64,
              height: 92,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(width: 64, height: 92, color: appTheme.backgroundColor),
              errorWidget: (context, url, error) => Container(width: 64, height: 92, color: appTheme.backgroundColor),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(anime.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: appTheme.textMainColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (anime.score != null && anime.score!.isNotEmpty) ...[
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF5C518)),
                          const SizedBox(width: 3),
                          Text(anime.score!, style: TextStyle(color: appTheme.textSubColor, fontSize: 12)),
                          const SizedBox(width: 10),
                        ],
                        if (anime.episodes != null && anime.episodes!.isNotEmpty)
                          Text("${anime.episodes} eps", style: TextStyle(color: appTheme.textSubColor, fontSize: 12)),
                        if (anime.status != null && anime.status!.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(anime.status!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: appTheme.textSubColor, fontSize: 12)),
                          ),
                        ],
                      ],
                    ),
                    if (anime.genres.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(anime.genres.take(3).map((g) => g.title).join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: appTheme.textSubColor, fontSize: 11)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroCarousel() {
    final pool = _items.take(8).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 250,
        child: PageView.builder(
          controller: _heroController,
          itemCount: pool.length,
          onPageChanged: (i) => _heroIndex = i,
          itemBuilder: (context, index) => _heroCard(pool[index], index),
        ),
      ),
    );
  }

  Widget _heroCard(SubIndoAnime anime, int index) {
    final loc = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: _heroController,
      builder: (context, child) {
        double page = index.toDouble();
        if (_heroController.hasClients && _heroController.position.haveDimensions) {
          page = _heroController.page ?? index.toDouble();
        }
        final delta = (page - index).abs().clamp(0.0, 1.0);
        final scale = 1 - delta * 0.12;
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: () => _openDetail(anime),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: anime.poster,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: appTheme.backgroundSubColor),
                errorWidget: (context, url, error) => Container(color: appTheme.backgroundSubColor),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              if (anime.score != null && anime.score!.trim().isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF5C518), size: 14),
                        const SizedBox(width: 3),
                        Text(anime.score!,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: appTheme.accentColor, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          loc.subIndoPopular,
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.1,
                            color: appTheme.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      anime.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, height: 1.15),
                    ),
                    if (anime.episodes != null && anime.episodes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        "${anime.episodes} ${loc.subIndoEpisodes}",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
