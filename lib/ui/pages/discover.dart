import 'dart:async';
import 'dart:io';

import 'package:kumaanime/ui/models/providers/mainNavProvider.dart';
import 'package:kumaanime/ui/models/widgets/cards/animeCard.dart';
import 'package:kumaanime/ui/models/widgets/infoPageWidgets/scrollingList.dart';
import 'package:flutter/material.dart';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/widgets/header.dart';
import 'package:kumaanime/ui/pages/genres.dart';
import 'package:kumaanime/ui/pages/info.dart';
import 'package:kumaanime/ui/pages/news.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/ui/pages/subIndo.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class Discover extends StatefulWidget {
  final MainNavProvider mainNavProvider;

  const Discover({
    super.key,
    required this.mainNavProvider,
  });

  @override
  State<Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover> {
  @override
  void initState() {
    super.initState();
    if (!widget.mainNavProvider.discoverDataLoaded) widget.mainNavProvider.loadDiscoverItems();
    _pageController.addListener(onScroll);
  }

  final recentlyUpdatedScrollController = ScrollController(),
      thisSeasonScrollController = ScrollController(),
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
          _pageController.animateToPage(currentPage, duration: Duration(milliseconds: 400), curve: Curves.easeOut);
        });
    });
  }

  bool initialTimeOutCalled = false;

  bool isHoveredOverScrollList = false;

  @override
  Widget build(BuildContext context) {
    if (!initialTimeOutCalled && widget.mainNavProvider.trendingList.length > 0) {
      pageTimeout();
      initialTimeOutCalled = true;
    }
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SmartRefresher(
        // reset the controller on build, preventing it from causing error: "Dont use one controller for multiple SmartRefresher"
        controller: widget.mainNavProvider.discoverRefreshController = RefreshController(initialRefresh: false),
        onRefresh: () async {
          await widget.mainNavProvider.refresh(refreshPage: 1, fromSettings: false);
        },
        header: WaterDropMaterialHeader(
          backgroundColor: appTheme.backgroundSubColor,
          color: appTheme.accentColor,
        ),
        child: SingleChildScrollView(
          physics: isHoveredOverScrollList ? NeverScrollableScrollPhysics() : null,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    // margin: EdgeInsets.only(top: 30),
                    height: (Platform.isWindows || Platform.isLinux) ? 450 : 370,
                    // width: double.infinity,
                    child: widget.mainNavProvider.trendingList.length > 0
                        ? _trendingAnimesPageView()
                        : Container(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: appTheme.accentColor,
                              ),
                            ),
                          ),
                  ),
                  Padding(
                    padding: pagePadding(context).copyWith(left: 0),
                    child: buildHeader("Discover", context, afterNavigation: () => setState(() {})),
                  )
                ],
              ),
              Container(
                height: 44,
                margin: EdgeInsets.only(top: 22, bottom: 4),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _navChip(
                      icon: Icons.newspaper_rounded,
                      label: "News",
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => News())),
                    ),
                    _navChip(
                      icon: Icons.category_rounded,
                      label: "Genres",
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => GenresPage())),
                    ),
                    _navChip(
                      icon: Icons.subtitles_rounded,
                      label: AppLocalizations.of(context).subIndo,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => SubIndoPage())),
                    ),
                  ],
                ),
              ),
              _itemTitle("Recently updated", recentlyUpdatedScrollController),
              _scrollList(widget.mainNavProvider.recentlyUpdatedList, recentlyUpdatedScrollController),
              _itemTitle("This season", thisSeasonScrollController),
              _scrollList(widget.mainNavProvider.thisSeason, thisSeasonScrollController),
              _itemTitle("Recommended", recommendedScrollController),
              _scrollList(widget.mainNavProvider.recommendedList, recommendedScrollController),
              footSpace(),
            ],
          ),
        ),
      ),
    );
  }

  SizedBox footSpace() {
    return SizedBox(
      height: MediaQuery.of(context).padding.bottom + 60,
    );
  }

  Widget _navChip({required IconData icon, required String label, required void Function() onTap}) {
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
                    fontFamily: "NotoSans",
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

  PageView _trendingAnimesPageView() {
    return PageView.builder(
        pageSnapping: true,
        controller: _pageController,
        allowImplicitScrolling: true,
        onPageChanged: (page) async {
          currentPage = page;
          await pageTimeout();
        },
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final trendingList = widget.mainNavProvider.trendingList;
          final moddedIndex = index % trendingList.length;
          final titles = trendingList[moddedIndex].title;
          final title = titles['english'] ?? titles['romaji'] ?? '';
          final preferNative = currentUserSettings?.nativeTitle ?? false;

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
            child: Container(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    trendingList[moddedIndex].banner ?? trendingList[moddedIndex].cover,
                    alignment: Alignment((index - page).clamp(-1, 1).toDouble() * 0.6, 0),
                    fit: BoxFit.cover,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
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
                          appTheme.backgroundColor.withValues(alpha: 0.55),
                          Colors.transparent,
                          appTheme.backgroundColor.withValues(alpha: 0.85),
                          appTheme.backgroundColor,
                        ],
                        stops: const [0.0, 0.3, 0.75, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preferNative ? titles['native'] ?? title : title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Rubik',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star_rounded, color: const Color(0xFFF5C518), size: 18),
                            const SizedBox(width: 3),
                            Text(
                              "${trendingList[moddedIndex].rating != null ? trendingList[moddedIndex].rating! / 10 : '??'}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: "Rubik",
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                trendingList[moddedIndex].genres.take(3).join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontFamily: 'NotoSans',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
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
              child: CircularProgressIndicator(
                color: appTheme.accentColor,
              ),
            ),
    );
  }

  Container _itemTitle(String title, ScrollController controller) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(top: 25, left: 25, right: 25, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: basicTextStyle("Rubik", 20),
          ),
          if (Platform.isWindows || Platform.isLinux) ScrollingList.scrollButtons(controller) else SizedBox.shrink()
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
