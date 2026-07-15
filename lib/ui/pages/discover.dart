import 'dart:async';
import 'dart:io';

import 'package:kumaanime/ui/models/providers/mainNavProvider.dart';
import 'package:kumaanime/ui/models/widgets/loader.dart';
import 'package:kumaanime/ui/models/widgets/cards/animeCard.dart';
import 'package:kumaanime/ui/models/widgets/infoPageWidgets/scrollingList.dart';
import 'package:flutter/material.dart';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/commons/types.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/widgets/header.dart';
import 'package:kumaanime/ui/models/widgets/cards.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/pages/genres.dart';
import 'package:kumaanime/ui/pages/info.dart';
import 'package:kumaanime/ui/pages/news.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/core/anime/providers/englishSource.dart';
import 'package:kumaanime/ui/pages/subIndo.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:kumaanime/ui/models/animeSubtitle.dart';
import 'package:kumaanime/ui/models/widgets/featureTitleWithBeta.dart';

class Discover extends StatefulWidget {
  final MainNavProvider mainNavProvider;
  final VoidCallback? onViewAllPressed;
  final VoidCallback? onSettingsPressed;

  const Discover({
    super.key,
    required this.mainNavProvider,
    this.onViewAllPressed,
    this.onSettingsPressed,
  });

  @override
  State<Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover> {
  @override
  void initState() {
    super.initState();
    if (!widget.mainNavProvider.discoverDataLoaded)
      widget.mainNavProvider.loadDiscoverItems();
    _pageController.addListener(onScroll);
  }

  final thisSeasonScrollController = ScrollController(),
      recommendedScrollController = ScrollController();

  int currentPage = 0;
  final PageController _pageController = PageController();
  Timer? timer;
  // bool trendingLoaded = false, recentlyUpdatedLoaded = false, recommendedLoaded = false;
  double page = 0;

  void onScroll() {
    setState(() {
      page = _pageController.page ?? 0;
    });
  }

  Future<void> pageTimeout() async {
    if (timer != null && timer!.isActive) timer!.cancel();
    timer = Timer(Duration(seconds: 5), () {
      if (currentPage < widget.mainNavProvider.trendingList.length - 1) {
        currentPage++;
      } else
        currentPage = 0;
      if (mounted)
        setState(() {
          _pageController.animateToPage(currentPage,
              duration: Duration(milliseconds: 400), curve: Curves.easeOut);
        });
    });
  }

  bool initialTimeOutCalled = false;

  bool isHoveredOverScrollList = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (!initialTimeOutCalled &&
        widget.mainNavProvider.trendingList.length > 0) {
      pageTimeout();
      initialTimeOutCalled = true;
    }
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SmartRefresher(
        controller: widget.mainNavProvider.discoverRefreshController =
            RefreshController(initialRefresh: false),
        onRefresh: () async {
          await widget.mainNavProvider
              .refresh(refreshPage: 1, fromSettings: false);
        },
        header: WaterDropMaterialHeader(
          backgroundColor: appTheme.backgroundSubColor,
          color: appTheme.accentColor,
        ),
        child: SingleChildScrollView(
          physics:
              isHoveredOverScrollList ? NeverScrollableScrollPhysics() : null,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height:
                        (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ? 380 : 320,
                    child: widget.mainNavProvider.trendingList.length > 0
                        ? _trendingAnimesPageView()
                        : Container(
                            child: Center(
                              child: KumaAnimeLoading(
                                  color: appTheme.accentColor, size: 40),
                            ),
                          ),
                  ),
                  if (Platform.isAndroid || Platform.isIOS)
                    Padding(
                      padding: pagePadding(context).copyWith(left: 0),
                      child: buildHeader(loc.discoverTitle, context,
                          afterNavigation: () => setState(() {})),
                    )
                ],
              ),
              if (Platform.isAndroid || Platform.isIOS)
                Container(
                  height: 44,
                  margin: const EdgeInsets.only(top: 22, bottom: 4),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _navChip(
                        icon: Icons.newspaper_rounded,
                        label: loc.discoverNews,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => News())),
                      ),
                      _navChip(
                        icon: Icons.category_rounded,
                        label: loc.discoverGenres,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => GenresPage())),
                      ),
                      _navChip(
                        icon: Icons.subtitles_rounded,
                        label: AppLocalizations.of(context).subIndo,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => SubIndoPage())),
                      ),
                      _navChip(
                        icon: Icons.translate_rounded,
                        label: AppLocalizations.of(context).subEng,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SubIndoPage(
                              source: EnglishSource(),
                              pageTitle: AppLocalizations.of(context).subEng,
                              searchHint:
                                  AppLocalizations.of(context).subEngSearchHint,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.mainNavProvider.recentlyWatched.items.isNotEmpty) ...[
                _continueWatchingHeader(context, loc.homeContinueWatching),
                _continueWatchingList(widget.mainNavProvider.recentlyWatched.items),
              ],
              _itemTitle(loc.discoverThisSeason, thisSeasonScrollController),
              _scrollList(widget.mainNavProvider.thisSeason,
                  thisSeasonScrollController),
              _itemTitle(loc.discoverRecommended, recommendedScrollController),
              _scrollList(widget.mainNavProvider.recommendedList,
                  recommendedScrollController),
              footSpace(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _continueWatchingHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, left: 24, right: 24, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: basicTextStyle("Rubik", 20),
          ),
          TextButton(
            onPressed: () {
              if (widget.onViewAllPressed != null) {
                widget.onViewAllPressed!();
              }
            },
            child: Text(
              'View All',
              style: TextStyle(
                color: appTheme.accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _continueWatchingList(List<HomePageList> list) {
    return Container(
      height: 160,
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          final preferNative = currentUserSettings?.nativeTitle ?? false;
          final normalTitle =
              item.title['english'] ?? item.title['romaji'] ?? item.title['title'] ?? '';
          final title = preferNative ? item.title['native'] ?? normalTitle : normalTitle;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Cards.animeCardExtended(
              item.id,
              title,
              item.coverImage,
              item.rating ?? 0.0,
              bannerImageUrl: item.coverImage,
              watchedEpisodeCount: item.watchedEpisodeCount,
              totalEpisodes: item.totalEpisodes,
              afterNavigation: () => setState(() {}),
            ),
          );
        },
      ),
    );
  }

  SizedBox footSpace() {
    return SizedBox(
      height: MediaQuery.of(context).padding.bottom + 60,
    );
  }

  Widget _navChip(
      {required IconData icon,
      required String label,
      required void Function() onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: appTheme.backgroundSubColor,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 18, color: appTheme.accentColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: appTheme.textMainColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroTextOverlay() {
    final list = widget.mainNavProvider.trendingList;
    if (list.isEmpty) return const SizedBox.shrink();
    final item = list[currentPage % list.length];
    final titles = item.title;
    final title = titles['english'] ?? titles['romaji'] ?? '';
    final preferNative = currentUserSettings?.nativeTitle ?? false;

    return Positioned(
      left: 24,
      right: 24,
      bottom: 36, // pushed up a bit to make room for indicator dots
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // New Episode tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Text(
              'New Episode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            preferNative ? titles['native'] ?? title : title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.1,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.genres.take(3).join(' • '),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: appTheme.accentColor,
                  foregroundColor: appTheme.onAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Info(id: item.id),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text(
                  'Watch Now',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // Quick add to watchlist/library
                    floatingSnackBar('Added to Watchlist');
                  },
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trendingAnimesPageView() {
    final trendingList = widget.mainNavProvider.trendingList;
    if (trendingList.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PageView.builder(
              pageSnapping: true,
              controller: _pageController,
              allowImplicitScrolling: true,
              onPageChanged: (page) async {
                currentPage = page;
                await pageTimeout();
              },
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final moddedIndex = index % trendingList.length;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Info(
                          id: trendingList[moddedIndex].id,
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        trendingList[moddedIndex].banner ??
                            trendingList[moddedIndex].cover,
                        alignment: Alignment(
                            (index - page).clamp(-1, 1).toDouble() * 0.6, 0),
                        fit: BoxFit.cover,
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return AnimatedOpacity(
                            opacity: frame == null ? 0 : 1,
                            duration: Duration(milliseconds: 250),
                            curve: Curves.easeIn,
                            child: child,
                          );
                        },
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.2),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                              Colors.black.withValues(alpha: 0.85),
                            ],
                            stops: const [0.0, 0.4, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

          // ── Text and Buttons overlay ──────────────────────────────────────
          _heroTextOverlay(),

          // ── Indicator dots in the bottom middle ────────────────────────────
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(trendingList.length, (dotIndex) {
                final isActive = (currentPage % trendingList.length) == dotIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? appTheme.accentColor : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Container _scrollList(List<AnimeCard> list, ScrollController controller) {
    return Container(
      height: (list.firstOrNull?.isMobile ?? true) ? 220 : 265,
      padding: EdgeInsets.only(left: 10, right: 10),
      child: list.length > 0
          ? ListView.builder(
              controller: controller,
              padding: EdgeInsets.zero,
              itemCount: list.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => list[index],
            )
          : Center(
              child: KumaAnimeLoading(color: appTheme.accentColor, size: 40),
            ),
    );
  }

  Container _itemTitle(
    String title,
    ScrollController controller, {
    bool showBeta = false,
    AnimeSubtitle? subtitle,
  }) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(top: 25, left: 25, right: 25, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: showBeta
                ? FeatureTitleWithBeta(
                    title: title,
                    subtitle: subtitle,
                    titleFontSize: 20,
                    subtitleFontSize: 13,
                    showBetaBadge: true,
                  )
                : Text(
                    title,
                    style: basicTextStyle("Rubik", 20),
                  ),
          ),
          if (Platform.isWindows || Platform.isLinux)
            ScrollingList.scrollButtons(controller)
          else
            SizedBox.shrink()
        ],
      ),
    );
  }

  TextStyle basicTextStyle(String? family, double? size) {
    return TextStyle(
      color: appTheme.textMainColor,
      fontFamily: family ?? 'NotoSans',
      fontSize: size ?? 15,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
    if (timer != null && timer!.isActive) timer?.cancel();
  }
}
