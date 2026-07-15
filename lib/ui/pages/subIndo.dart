import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:hive/hive.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:kumaanime/core/commons/enums/hiveEnums.dart';
import 'package:kumaanime/core/anime/providers/animeLangSource.dart';
import 'package:kumaanime/core/anime/providers/otakudesu.dart';
import 'package:kumaanime/core/anime/providers/subIndoTypes.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/widgets/cards/subIndoCard.dart';
import 'package:kumaanime/ui/pages/subIndoDetail.dart';
import 'package:kumaanime/ui/models/widgets/backButton.dart';

enum _SubIndoMode { ongoing, completed, genre }

class SubIndoPage extends StatefulWidget {
  final AnimeLangSource? source;
  final String? pageTitle;
  final String? searchHint;

  final bool isTab;

  const SubIndoPage({
    super.key,
    this.source,
    this.pageTitle,
    this.searchHint,
    this.isTab = false,
  });

  @override
  State<SubIndoPage> createState() => _SubIndoPageState();
}

class _SubIndoPageState extends State<SubIndoPage> with SingleTickerProviderStateMixin {
  late final AnimeLangSource _provider = widget.source ?? OtakuDesu();
  final RefreshController _refreshController = RefreshController();
  late TabController _tabController;

  _SubIndoMode _mode = _SubIndoMode.ongoing;
  SubIndoGenre? _selectedGenre;
  List<SubIndoAnime> _items = [];
  int _page = 1;
  bool _hasNextPage = false;
  bool _loading = true;
  bool _error = false;
  bool _loadingGenres = false;
  bool _isOffline = false;

  int _heroIndex = 0;
  Timer? _heroTimer;
  final _heroController = PageController(viewportFraction: 0.82);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadInitialData();
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _mode = _tabController.index == 0 ? _SubIndoMode.ongoing : _SubIndoMode.completed;
        _selectedGenre = null; // Reset genre when switching tabs
      });
      _load(reset: true);
    }
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroController.dispose();
    _refreshController.dispose();
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
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
      _heroController.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<bool> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _writeCache(List<SubIndoAnime> data) async {
    try {
      final box = await Hive.openBox(HiveBox.misc.boxName);
      final jsonList = data.map((e) => {
        'animeId': e.animeId,
        'title': e.title,
        'poster': e.poster,
        'episodes': e.episodes,
        'score': e.score,
        'status': e.status,
        'releaseDay': e.releaseDay,
        'genres': e.genres.map((g) => {'title': g.title, 'genreId': g.genreId}).toList(),
      }).toList();
      await box.put(
        'subindo_cache_${_mode.name}_${_provider.runtimeType}',
        jsonEncode(jsonList),
      );
    } catch (_) {}
  }

  Future<List<SubIndoAnime>?> _readCache() async {
    try {
      final box = await Hive.openBox(HiveBox.misc.boxName);
      final String? cachedStr = box.get('subindo_cache_${_mode.name}_${_provider.runtimeType}');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(cachedStr);
        return jsonList.map((e) => SubIndoAnime(
          animeId: e['animeId'],
          title: e['title'],
          poster: e['poster'],
          episodes: e['episodes'],
          score: e['score'],
          status: e['status'],
          releaseDay: e['releaseDay'],
          genres: (e['genres'] as List<dynamic>?)?.map((g) => SubIndoGenre(title: g['title'], genreId: g['genreId'])).toList() ?? [],
        )).toList();
      }
    } catch (_) {}
    return null;
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _error = false;
      _isOffline = false;
    });

    final cached = await _readCache();
    if (cached != null && cached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _items = cached;
          _loading = false;
        });
        _startHeroRotation();
      }
    }

    _load(reset: true, background: cached != null && cached.isNotEmpty);
  }

  Future<void> _load({bool reset = false, bool background = false}) async {
    if (reset && !background) {
      setState(() {
        _loading = true;
        _error = false;
        _isOffline = false;
        _items = [];
        _page = 1;
        _hasNextPage = false;
      });
    }

    final online = await _checkConnection();
    if (!online) {
      if (mounted) {
        setState(() {
          _isOffline = _items.isEmpty;
          _loading = false;
        });
        if (reset) {
          _refreshController.refreshFailed();
        } else {
          _refreshController.loadFailed();
        }
      }
      return;
    }

    final int targetPage = reset ? 1 : _page;

    try {
      List<SubIndoAnime> newItems;
      bool hasNext = false;

      switch (_mode) {
        case _SubIndoMode.ongoing:
          final res = await _provider.getOngoing(page: targetPage);
          newItems = res.items;
          hasNext = res.hasNextPage;
        case _SubIndoMode.completed:
          final res = await _provider.getCompleted(page: targetPage);
          newItems = res.items;
          hasNext = res.hasNextPage;
        case _SubIndoMode.genre:
          final res = await _provider.getByGenre(_selectedGenre!.genreId, page: targetPage);
          newItems = res.items;
          hasNext = res.hasNextPage;
      }

      if (!mounted) return;

      setState(() {
        if (reset) {
          _items = newItems;
        } else {
          _items.addAll(newItems);
        }
        _hasNextPage = hasNext;
        _page = targetPage + 1;
        _loading = false;
        _error = false;
        _isOffline = false;
      });

      if (reset) {
        _writeCache(_items);
        _refreshController.refreshCompleted();
      } else {
        _refreshController.loadComplete();
      }
      _startHeroRotation();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _items.isEmpty;
        _loading = false;
      });
      if (reset) {
        _refreshController.refreshFailed();
      } else {
        _refreshController.loadFailed();
      }
    }
  }

  void _openDetail(SubIndoAnime anime) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubIndoDetailPage(animeId: anime.animeId, source: _provider),
      ),
    );
  }

  void _showGenresBottomSheet() async {
    setState(() => _loadingGenres = true);
    try {
      final genres = await _provider.getGenres();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: appTheme.modalSheetBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.subIndoGenres,
                    style: TextStyle(
                      color: appTheme.textMainColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: genres.map((genre) {
                          final isSelected = _selectedGenre?.genreId == genre.genreId && _mode == _SubIndoMode.genre;
                          return FilterChip(
                            selected: isSelected,
                            label: Text(genre.title),
                            labelStyle: TextStyle(
                              color: isSelected ? appTheme.onAccent : appTheme.textMainColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            selectedColor: appTheme.accentColor,
                            backgroundColor: appTheme.backgroundSubColor,
                            checkmarkColor: appTheme.onAccent,
                            onSelected: (selected) {
                              Navigator.pop(context);
                              if (selected) {
                                setState(() {
                                  _mode = _SubIndoMode.genre;
                                  _selectedGenre = genre;
                                });
                                _load(reset: true);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.stateError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingGenres = false);
      }
    }
  }

  Widget _buildSkeletonList() {
    final isDesktop = Platform.isWindows || Platform.isLinux;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: (isDesktop ? 165.0 : 125.0) * (currentUserSettings?.cardScale ?? 1.0).clamp(0.85, 1.15),
          mainAxisExtent: (isDesktop ? 300.0 : 240.0) * (currentUserSettings?.cardScale ?? 1.0).clamp(0.85, 1.15),
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: 10,
        itemBuilder: (context, index) => _buildShimmerCard(),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: appTheme.backgroundSubColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 80,
            margin: const EdgeInsets.only(left: 8),
            color: Colors.grey.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 6),
          Container(
            height: 10,
            width: 50,
            margin: const EdgeInsets.only(left: 8, bottom: 8),
            color: Colors.grey.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 50, color: appTheme.textSubColor),
          const SizedBox(height: 12),
          Text(
            loc.subIndoLoadError,
            textAlign: TextAlign.center,
            style: TextStyle(color: appTheme.textMainColor, fontSize: 16),
          ),
          const SizedBox(height: 16),
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

  Widget _buildOfflineState(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 55, color: appTheme.textSubColor),
          const SizedBox(height: 12),
          Text(
            loc.stateOffline,
            style: TextStyle(color: appTheme.textMainColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            loc.stateOfflineSub,
            style: TextStyle(color: appTheme.textSubColor, fontSize: 13),
          ),
          const SizedBox(height: 20),
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

  Widget _buildSliverAppBar(AppLocalizations loc) {
    final hasGenreFilter = _selectedGenre != null;
    return SliverAppBar(
      pinned: false,
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: appTheme.backgroundColor,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 8,
      leading: widget.isTab
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: Material(
                  color: appTheme.backgroundSubColor,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.hardEdge,
                  child: KumaBackButton(size: 22),
                ),
              ),
            ),
      leadingWidth: widget.isTab ? 0 : 48,
      title: widget.isTab
          ? null
          : Text(
              widget.pageTitle ?? loc.subIndo,
              style: TextStyle(
                color: appTheme.textMainColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Stack(
            children: [
              IconButton.filledTonal(
                onPressed: _showGenresBottomSheet,
                icon: _loadingGenres
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.tune_rounded, color: appTheme.accentColor),
                style: IconButton.styleFrom(
                  backgroundColor: appTheme.backgroundSubColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (hasGenreFilter)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: appTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: appTheme.accentColor,
        labelColor: appTheme.accentColor,
        unselectedLabelColor: appTheme.textSubColor,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
        tabs: [
          Tab(text: loc.subIndoOngoing),
          Tab(text: loc.subIndoCompleted),
        ],
      ),
    );
  }

  Widget _buildMainContent(AppLocalizations loc, bool desktop, bool showHero) {
    final hasGenreFilter = _selectedGenre != null;

    if (_loading && _items.isEmpty) {
      return CustomScrollView(
        slivers: [
          _buildSliverAppBar(loc),
          _buildSkeletonList(),
        ],
      );
    }

    if (_isOffline && _items.isEmpty) {
      return CustomScrollView(
        slivers: [
          _buildSliverAppBar(loc),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildOfflineState(loc),
          ),
        ],
      );
    }

    if (_error && _items.isEmpty) {
      return CustomScrollView(
        slivers: [
          _buildSliverAppBar(loc),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildErrorState(loc),
          ),
        ],
      );
    }

    return SmartRefresher(
      controller: _refreshController,
      enablePullUp: _hasNextPage,
      onRefresh: () => _load(reset: true),
      onLoading: () => _load(reset: false),
      header: WaterDropMaterialHeader(
        backgroundColor: appTheme.backgroundSubColor,
        color: appTheme.accentColor,
      ),
      child: CustomScrollView(
        slivers: [
          _buildSliverAppBar(loc),
          if (hasGenreFilter)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
                child: Row(
                  children: [
                    InputChip(
                      label: Text(_selectedGenre!.title),
                      labelStyle: TextStyle(color: appTheme.onAccent, fontWeight: FontWeight.bold),
                      backgroundColor: appTheme.accentColor,
                      onDeleted: () {
                        setState(() {
                          _selectedGenre = null;
                          _mode = _tabController.index == 0 ? _SubIndoMode.ongoing : _SubIndoMode.completed;
                        });
                        _load(reset: true);
                      },
                      deleteIconColor: appTheme.onAccent,
                    ),
                  ],
                ),
              ),
            ),
          if (_items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  loc.subIndoEmpty,
                  style: TextStyle(color: appTheme.textSubColor, fontSize: 14),
                ),
              ),
            )
          else ...[
            if (showHero) SliverToBoxAdapter(child: _heroCarousel()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  return SubIndoCard(
                    anime: anime,
                    isSubIndo: widget.source == null || widget.source is OtakuDesu,
                    onTap: () => _openDetail(anime),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final desktop = Platform.isWindows || Platform.isLinux;
    final showHero = (_mode == _SubIndoMode.ongoing || _mode == _SubIndoMode.completed) && _items.isNotEmpty;

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SafeArea(
        child: _buildMainContent(loc, desktop, showHero),
      ),
    );
  }

  Widget _heroCarousel() {
    final pool = _items.take(8).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
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
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
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
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
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
                        Text(
                          anime.score!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    if (anime.episodes != null && anime.episodes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        "${anime.episodes} ${loc.subIndoEpisodes}",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
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
