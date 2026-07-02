import 'dart:io';
import 'dart:ui';

import 'package:kumaanime/core/anime/providers/otakudesu.dart';
import 'package:kumaanime/ui/models/widgets/loader.dart';
import 'package:kumaanime/core/anime/providers/subIndoTypes.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/widgets/cards/subIndoCard.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/ui/pages/subIndoDetail.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

enum _SubIndoMode { ongoing, completed, genre, search }

class SubIndoPage extends StatefulWidget {
  const SubIndoPage({super.key});

  @override
  State<SubIndoPage> createState() => _SubIndoPageState();
}

class _SubIndoPageState extends State<SubIndoPage> {
  final _provider = OtakuDesu();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  _SubIndoMode _mode = _SubIndoMode.ongoing;
  SubIndoGenre? _selectedGenre;
  List<SubIndoGenre> _genres = [];
  List<SubIndoAnime> _items = [];
  int _page = 1;
  bool _hasNextPage = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadGenres();
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
      body: Padding(
        padding: pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            settingPagesTitleHeader(context, loc.subIndo),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _searchField(loc),
            ),
            Container(
              height: 50,
              margin: const EdgeInsets.only(top: 15),
              child: _filterChips(loc),
            ),
            Expanded(child: _body(loc)),
          ],
        ),
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
      style: TextStyle(color: appTheme.textMainColor, fontFamily: "NotoSans"),
      decoration: InputDecoration(
        hintText: loc.subIndoSearchHint,
        hintStyle: TextStyle(color: appTheme.textSubColor, fontFamily: "NotoSans"),
        prefixIcon: Icon(Icons.search_rounded, color: appTheme.textSubColor),
        filled: true,
        fillColor: appTheme.backgroundSubColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
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
      margin: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? appTheme.accentColor : appTheme.backgroundSubColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? appTheme.onAccent : appTheme.textMainColor,
              fontFamily: "NotoSans",
              fontWeight: FontWeight.bold,
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
              style: TextStyle(color: appTheme.textSubColor, fontFamily: "NotoSans", fontSize: 16),
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
          style: TextStyle(color: appTheme.textSubColor, fontFamily: "Rubik", fontSize: 18),
        ),
      );
    }

    final desktop = Platform.isWindows || Platform.isLinux;
    final showHero = _mode == _SubIndoMode.ongoing || _mode == _SubIndoMode.completed;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (showHero)
          SliverToBoxAdapter(child: _hero(_items.first)),
        SliverPadding(
          padding: EdgeInsets.only(top: 16, left: 15, right: 15, bottom: MediaQuery.of(context).padding.bottom + 20),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: desktop ? 165 : 125,
              mainAxisExtent: desktop ? 300 : 240,
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
    return GestureDetector(
      onTap: () => _openDetail(anime),
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 15),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
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
                  colors: [Colors.black.withValues(alpha: 0.35), Colors.black.withValues(alpha: 0.85)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: anime.poster,
                      width: 110,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: appTheme.backgroundSubColor, width: 110),
                      errorWidget: (context, url, error) => Container(color: appTheme.backgroundSubColor, width: 110),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: appTheme.accentColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppLocalizations.of(context).subIndo.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 0.5,
                              color: appTheme.onAccent,
                              fontFamily: "NotoSans",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          anime.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: "Rubik",
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (anime.episodes != null && anime.episodes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              "${anime.episodes} ${AppLocalizations.of(context).subIndoEpisodes}",
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontFamily: "NotoSans"),
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
