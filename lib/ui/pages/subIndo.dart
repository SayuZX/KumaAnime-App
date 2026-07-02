import 'dart:io';

import 'package:kumaanime/core/anime/providers/otakudesu.dart';
import 'package:kumaanime/core/anime/providers/subIndoTypes.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/widgets/cards/subIndoCard.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/ui/pages/subIndoDetail.dart';
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
    } catch (_) {
      // Genre chips are optional, the rest of the page still works
    }
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
      return Center(child: CircularProgressIndicator(color: appTheme.accentColor));
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

    final cardWidth = Platform.isWindows || Platform.isLinux ? 170.0 : 130.0;

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(top: 20, left: 15, right: 15, bottom: MediaQuery.of(context).padding.bottom + 20),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: cardWidth,
        mainAxisExtent: Platform.isWindows || Platform.isLinux ? 290 : 250,
        crossAxisSpacing: 5,
        mainAxisSpacing: 10,
      ),
      itemCount: _items.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return Center(child: CircularProgressIndicator(color: appTheme.accentColor));
        }
        final anime = _items[index];
        return SubIndoCard(
          anime: anime,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SubIndoDetailPage(animeId: anime.animeId),
              ),
            );
          },
        );
      },
    );
  }
}
