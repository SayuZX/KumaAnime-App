import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/database/anilist/queries.dart';
import 'package:kumaanime/core/database/anilist/types.dart';
import 'package:kumaanime/ui/models/widgets/backButton.dart';
import 'package:kumaanime/ui/models/widgets/cards.dart';
import 'package:kumaanime/ui/models/widgets/loader.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';

class GenreAnimeListPage extends StatefulWidget {
  final String genre;

  const GenreAnimeListPage({
    super.key,
    required this.genre,
  });

  @override
  State<GenreAnimeListPage> createState() => _GenreAnimeListPageState();
}

class _GenreAnimeListPageState extends State<GenreAnimeListPage> {
  final ScrollController _scrollController = ScrollController();
  final List<dynamic> _animeList = [];
  bool _isLoading = true;
  bool _isLazyLoading = false;
  bool _hasError = false;
  int _currentPage = 1;
  bool _hasMore = true;

  AnilistSortType _selectedSort = AnilistSortType.trendingDesc;

  @override
  void initState() {
    super.initState();
    _fetchAnime();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!_isLazyLoading && _hasMore && !_isLoading) {
        _fetchAnime(loadMore: true);
      }
    }
  }

  Future<void> _fetchAnime({bool loadMore = false, bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _animeList.clear();
        _isLoading = true;
        _hasError = false;
        _hasMore = true;
      });
    } else if (loadMore) {
      setState(() {
        _isLazyLoading = true;
        _hasError = false;
      });
    } else {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final res = await AnilistQueries().advancedSearch(
        genres: [widget.genre],
        page: _currentPage,
        sort: _selectedSort,
      );

      if (!mounted) return;

      setState(() {
        if (res.isEmpty) {
          _hasMore = false;
        } else {
          _animeList.addAll(res);
          _currentPage++;
        }
        _isLoading = false;
        _isLazyLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
        _isLazyLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDesktop = Platform.isWindows || Platform.isLinux;

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            children: [
              _buildHeader(loc),
              Expanded(
                child: _buildBody(loc, isDesktop),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          KumaBackButton(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loc.genreAnimeListTitle(widget.genre),
              style: TextStyle(
                color: appTheme.textMainColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildSortMenu(loc),
        ],
      ),
    );
  }

  Widget _buildSortMenu(AppLocalizations loc) {
    return PopupMenuButton<AnilistSortType>(
      icon: Icon(Icons.sort_rounded, color: appTheme.textMainColor),
      color: appTheme.modalSheetBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      onSelected: (sort) {
        if (_selectedSort != sort) {
          _selectedSort = sort;
          _fetchAnime(reset: true);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: AnilistSortType.trendingDesc,
          child: Text(
            loc.sortTrending,
            style: TextStyle(
              color: _selectedSort == AnilistSortType.trendingDesc
                  ? appTheme.accentColor
                  : appTheme.textMainColor,
            ),
          ),
        ),
        PopupMenuItem(
          value: AnilistSortType.popularityDesc,
          child: Text(
            loc.sortPopularity,
            style: TextStyle(
              color: _selectedSort == AnilistSortType.popularityDesc
                  ? appTheme.accentColor
                  : appTheme.textMainColor,
            ),
          ),
        ),
        PopupMenuItem(
          value: AnilistSortType.scoreDesc,
          child: Text(
            loc.sortScore,
            style: TextStyle(
              color: _selectedSort == AnilistSortType.scoreDesc
                  ? appTheme.accentColor
                  : appTheme.textMainColor,
            ),
          ),
        ),
        PopupMenuItem(
          value: AnilistSortType.startDateDesc,
          child: Text(
            loc.sortNewest,
            style: TextStyle(
              color: _selectedSort == AnilistSortType.startDateDesc
                  ? appTheme.accentColor
                  : appTheme.textMainColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(AppLocalizations loc, bool isDesktop) {
    if (_isLoading) {
      return _buildSkeletonGrid(isDesktop);
    }

    if (_hasError) {
      return _buildErrorState(loc);
    }

    if (_animeList.isEmpty) {
      return _buildEmptyState(loc);
    }

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isDesktop ? 180 : 140,
              mainAxisExtent: isDesktop ? 260 : 220,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
            ),
            padding: EdgeInsets.only(
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            itemCount: _animeList.length,
            itemBuilder: (context, index) {
              final item = _animeList[index];
              final defaultTitle =
                  item.title['english'] ?? item.title['romaji'] ?? '';
              final title = (currentUserSettings?.nativeTitle ?? false)
                  ? item.title['native'] ?? defaultTitle
                  : defaultTitle;

              return Center(
                child: Cards.animeCard(
                  item.id,
                  title,
                  item.cover,
                  ongoing: item.status == "RELEASING",
                  rating: item.rating,
                  isMobile: !isDesktop,
                ),
              );
            },
          ),
          if (_isLazyLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: KumaAnimeLoading(color: appTheme.accentColor, size: 36),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkeletonGrid(bool isDesktop) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isDesktop ? 180 : 140,
        mainAxisExtent: isDesktop ? 260 : 220,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
      ),
      padding: const EdgeInsets.only(top: 12),
      itemCount: 12,
      itemBuilder: (context, index) => _buildSkeletonCard(isDesktop),
    );
  }

  Widget _buildSkeletonCard(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: appTheme.backgroundSubColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 80,
            margin: const EdgeInsets.only(left: 8),
            color: Colors.grey.withOpacity(0.12),
          ),
          const SizedBox(height: 6),
          Container(
            height: 10,
            width: 50,
            margin: const EdgeInsets.only(left: 8, bottom: 8),
            color: Colors.grey.withOpacity(0.08),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_filter_rounded,
            color: appTheme.textSubColor.withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            loc.genreAnimeNoResults,
            style: TextStyle(
              color: appTheme.textSubColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: appTheme.accentColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              loc.genresErrorLoading,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: appTheme.textSubColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _fetchAnime(),
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.accentColor,
                foregroundColor: appTheme.onAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(loc.genresRetry),
            ),
          ],
        ),
      ),
    );
  }
}
