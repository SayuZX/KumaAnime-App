import 'dart:async';
import 'dart:io';
import 'dart:ui';

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
  const SubIndoPage({super.key});

  @override
  State<SubIndoPage> createState() => _SubIndoPageState();
}

class _SubIndoPageState extends State<SubIndoPage> with SingleTickerProviderStateMixin {
  final _provider = OtakuDesu();
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
      if (!mounted) return;
      final pool = _items.length < 8 ? _items.length : 8;
      setState(() => _heroIndex = (_heroIndex + 1) % pool);
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
      MaterialPageRoute(builder: (context) => SubIndoDetailPage(animeId: anime.animeId)),
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
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
              icon: Icon(Icons.arrow_back_rounded, color: appTheme.textMainColor, size: 22),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            loc.subIndo,
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
        hintText: loc.subIndoSearchHint,
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
        if (showHero)
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              child: KeyedSubtree(
                key: ValueKey(_items[_heroIndex.clamp(0, _items.length - 1)].animeId),
                child: _hero(_items[_heroIndex.clamp(0, _items.length - 1)]),
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.only(top: 16, left: 15, right: 15, bottom: MediaQuery.of(context).padding.bottom + 20),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: (desktop ? 165.0 : 125.0) * (currentUserSettings?.cardScale ?? 1.0).clamp(0.85, 1.15),
              mainAxisExtent: (desktop ? 300.0 : 240.0) * (currentUserSettings?.cardScale ?? 1.0).clamp(0.85, 1.15),
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final anime = _items[index];
              return SubIndoCard(anime: anime, onTap: () => _openDetail(anime));
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

  Widget _hero(SubIndoAnime anime) {
    final loc = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => _openDetail(anime),
      child: Container(
        height: 214,
        margin: const EdgeInsets.only(left: 15, right: 15, top: 16),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: CachedNetworkImage(
                imageUrl: anime.poster,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: appTheme.backgroundSubColor),
                errorWidget: (context, url, error) => Container(color: appTheme.backgroundSubColor),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.black.withValues(alpha: 0.4), Colors.black.withValues(alpha: 0.9)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: CachedNetworkImage(
                      imageUrl: anime.poster,
                      width: 112,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: appTheme.backgroundSubColor, width: 112),
                      errorWidget: (context, url, error) => Container(color: appTheme.backgroundSubColor, width: 112),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_fire_department_rounded, color: appTheme.accentColor, size: 17),
                            const SizedBox(width: 5),
                            Text(
                              loc.subIndoPopular.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.2,
                                color: appTheme.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          anime.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (anime.score != null && anime.score!.trim().isNotEmpty) ...[
                              const Icon(Icons.star_rounded, color: Color(0xFFF5C518), size: 15),
                              const SizedBox(width: 3),
                              Text(
                                anime.score!,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 10),
                            ],
                            if (anime.episodes != null && anime.episodes!.isNotEmpty)
                              Text(
                                "${anime.episodes} ${loc.subIndoEpisodes}",
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: appTheme.accentColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: appTheme.onAccent, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                loc.subIndoWatchNow,
                                style: TextStyle(
                                  color: appTheme.onAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
