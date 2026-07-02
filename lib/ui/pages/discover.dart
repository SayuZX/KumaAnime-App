import 'dart:async';
import 'dart:io';
import 'dart:ui';

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
              Padding(
                padding: EdgeInsets.only(top: 30),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 25,
                  runSpacing: 15,
                  children: [
                    _bannerButton(
                      label: "News",
                      imageAsset: 'lib/assets/images/chisato.jpeg',
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => News()));
                      },
                    ),
                    _bannerButton(
                      label: "Genres",
                      imageAsset: 'lib/assets/images/mitsuha.jpg',
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => GenresPage()));
                      },
                    ),
                    _bannerButton(
                      label: AppLocalizations.of(context).subIndo,
                      imageAsset: 'lib/assets/images/chisato_AI.jpg',
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => SubIndoPage()));
                      },
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

  Widget _bannerButton({required String label, required String imageAsset, required void Function() onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 75,
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: AssetImage(imageAsset),
            fit: BoxFit.cover,
            opacity: 0.4,
          ),
          border: Border.all(color: appTheme.accentColor),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: appTheme.textMainColor,
              fontFamily: "NotoSans",
              fontWeight: FontWeight.bold,
              fontSize: 24,
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
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  Container(
                    width: double.infinity,
                    child: ClipRRect(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Image.network(
                          trendingList[moddedIndex].banner ?? trendingList[moddedIndex].cover,
                          alignment: Alignment((index - page).clamp(-1, 1).toDouble(), 1),
                          opacity: AlwaysStoppedAnimation(0.5),
                          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: Duration(milliseconds: 150),
                              child: child,
                            );
                          },
                          height: 360,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 20.0, top: MediaQuery.of(context).padding.top + 50),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            trendingList[moddedIndex].cover,
                            height: 170,
                            width: 120,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 10, right: 10),
                          width: 250,
                          child: Column(
                            // mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Text(
                                  preferNative ? titles['native'] ?? title : title,
                                  style: TextStyle(
                                    color: appTheme.textMainColor,
                                    fontFamily: 'NunitoSans',
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              Text(
                                trendingList[moddedIndex].genres.join(', '),
                                style: TextStyle(
                                    color: appTheme.textMainColor.withAlpha(145),
                                    fontFamily: 'NunitoSans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: appTheme.textMainColor,
                                      size: 20,
                                    ),
                                    Text(
                                      "${trendingList[moddedIndex].rating != null ? trendingList[moddedIndex].rating! / 10 : '??'}",
                                      style:
                                          TextStyle(color: appTheme.textMainColor, fontFamily: "Rubik", fontSize: 17),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
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
