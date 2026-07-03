import 'dart:io';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/app/update.dart';
import 'package:kumaanime/core/commons/utils.dart';
import 'package:kumaanime/core/data/downloadHistory.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/providers/mainNavProvider.dart';
import 'package:kumaanime/ui/models/widgets/bottomBar.dart';
import 'package:kumaanime/ui/models/widgets/floatyBar/controller.dart';
import 'package:kumaanime/ui/models/widgets/floatyBar/floatyBarView.dart';
import 'package:kumaanime/core/data/resumeSession.dart';
import 'package:kumaanime/ui/models/widgets/floatyBar/floatyBottomBar.dart';
import 'package:kumaanime/ui/models/widgets/liquidGlassNavBar.dart';
import 'package:kumaanime/ui/models/widgets/miniResumePlayer.dart';
import 'package:kumaanime/ui/models/widgets/cards.dart';
import 'package:kumaanime/ui/pages/genres.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/pages/discover.dart';
import 'package:kumaanime/ui/pages/home.dart';
import 'package:kumaanime/ui/pages/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => MainNavigatorState();
}

class MainNavigatorState extends State<MainNavigator> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    final provider = context.read<MainNavProvider>();

    isTv().then((value) => provider.tv = value);

    // open the box for the whole app life time!
    DownloadHistory.initBox();

    ResumeSession.load();

    //check for app updates & show prompt
    checkForUpdates().then((data) => {
          if (data != null)
            {
              showUpdateSheet(
                context,
                data.description,
                data.downloadLink,
                data.preRelease,
                data.latestVersion,
                // forceTrigger: true
              ),
            }
        });

    // load the stuff
    provider.init();
  }

  final _floatyBarController = FloatyBottomBarController(length: 4);
  final _floatyOldController = FloatyBottomBarController(length: 3);
  final _barController = KumaAnimeBottomBarController(length: 3);

  bool popInvoked = false;
  // late bool tv;
  // bool isAndroid = Platform.isAndroid;

  late MainNavProvider mainNavProvider;

  void rebuildCards() {
    mainNavProvider.recentlyUpdatedList.clear();

    final isMobile = !mainNavProvider.tv && mainNavProvider.isAndroid;

    mainNavProvider.recentlyUpdatedListData.forEach((elem) {
      final title = elem.title['english'] ?? elem.title['romaji'] ?? '';
      mainNavProvider.recentlyUpdatedList.add(
        Cards.animeCard(
          elem.id,
          (currentUserSettings?.nativeTitle ?? false) ? elem.title['native'] ?? title : title,
          elem.cover,
          rating: (elem.rating ?? 0) / 10,
          isMobile: isMobile,
        ),
      );
    });

    mainNavProvider.recommendedList.clear();
    mainNavProvider.recommendedListData.forEach((item) {
      final title = item.title['english'] ?? item.title['romaji'] ?? '';
      mainNavProvider.recommendedList.add(Cards.animeCard(
          item.id, (currentUserSettings?.nativeTitle ?? false) ? item.title['native'] ?? title : title, item.cover,
          rating: item.rating, isMobile: isMobile));
    });

    mainNavProvider.thisSeason.clear();
    mainNavProvider.thisSeasonData.forEach((item) {
      final title = item.title['english'] ?? item.title['romaji'] ?? '';
      mainNavProvider.thisSeason.add(Cards.animeCard(
          item.id, (currentUserSettings?.nativeTitle ?? false) ? item.title['native'] ?? title : title, item.cover,
          rating: item.rating, isMobile: isMobile));
    });

    setState(() {});
  }

  //reset the popInvoke
  Future<void> popTimeoutWindow() async {
    await Future.delayed(Duration(seconds: 3));
    popInvoked = false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    mainNavProvider = context.watch<MainNavProvider>();

    if (mainNavProvider.recentlyUpdatedList.isNotEmpty && mainNavProvider.thisSeason.isNotEmpty) {
      rebuildCards();
    }
    double blurSigmaValue = currentUserSettings!.navbarTranslucency ?? 5;
    if (blurSigmaValue <= 1) {
      blurSigmaValue = blurSigmaValue * 10;
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) async {
        if (_barController.currentIndex != 0) {
          _barController.currentIndex = 0;
          return;
        }

        if (_floatyBarController.currentIndex != 0) {
          _floatyBarController.currentIndex = 0;
          return;
        }

        if (_floatyOldController.currentIndex != 0) {
          _floatyOldController.currentIndex = 0;
          return;
        }

        //exit the app if back is pressed again within 3 sec window
        if (popInvoked) return await SystemNavigator.pop();

        floatingSnackBar(loc.mainNavExitPrompt);
        popInvoked = true;
        popTimeoutWindow();
      },
      child: Scaffold(
        body: MediaQuery.of(context).orientation == Orientation.landscape || Platform.isWindows || Platform.isLinux
            ? Row(
                children: [
                  // KumaAnimeNavRail(
                  //   destinations: [
                  //     KumaAnimeNavDestination(icon: Icons.home, label: "Home"),
                  //     KumaAnimeNavDestination(icon: Icons.auto_awesome, label: "Discover"),
                  //     KumaAnimeNavDestination(icon: Icons.search, label: "Search"),
                  //   ],
                  //   controller: _barController,
                  //   initialIndex: 0,
                  //   shouldExpand: true,
                  // ),
                  NavigationRail(
                    onDestinationSelected: (value) {
                      _barController.currentIndex = value;
                      setState(() {});
                    },
                    backgroundColor: appTheme.backgroundColor,
                    elevation: 1,
                    indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    indicatorColor: appTheme.accentColor,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(
                          Icons.home,
                          color: _barController.currentIndex == 0 ? appTheme.onAccent : appTheme.textMainColor,
                        ),
                        label: Text(
                          AppLocalizations.of(context).navHome,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(
                          Icons.auto_awesome,
                          color: _barController.currentIndex == 1 ? appTheme.onAccent : appTheme.textMainColor,
                        ),
                        label: Text(
                          AppLocalizations.of(context).navDiscover,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.search_rounded,
                            color: _barController.currentIndex == 2 ? appTheme.onAccent : appTheme.textMainColor),
                        label: Text(
                          AppLocalizations.of(context).navSearch,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                    selectedIndex: _barController.currentIndex,
                  ),
                  Expanded(
                    child: BottomBarView(
                      controller: _barController,
                      // physics: NeverScrollableScrollPhysics(),
                      children: [
                        Home(
                          mainNavProvider: mainNavProvider,
                        ),
                        Discover(
                          mainNavProvider: mainNavProvider,
                        ),
                        Search(),
                      ],
                    ),
                  ),
                ],
              )
            : _bottomBar(context, blurSigmaValue),
      ),
    );
  }

  Widget _bottomBar(BuildContext context, double blurSigmaValue) {
    return (currentUserSettings?.useOldNavbar ?? false)
        ? Stack(
            children: [
              FloatyBarView(
                controller: _floatyOldController,
                children: [
                  Home(
                    key: ValueKey("0"),
                    mainNavProvider: mainNavProvider,
                  ),
                  Discover(
                    key: ValueKey("1"),
                    mainNavProvider: mainNavProvider,
                  ),
                  Search(
                    key: ValueKey("2"),
                  ),
                ],
              ),
              FloatyBottomBar(
                controller: _floatyOldController,
                accentColor: appTheme.accentColor,
                backgroundColor:
                    appTheme.backgroundSubColor.withValues(alpha: currentUserSettings?.navbarTranslucency ?? 0.5),
                items: [
                  FloatyBarItem(title: AppLocalizations.of(context).navHome, icon: Icons.home),
                  FloatyBarItem(title: AppLocalizations.of(context).navDiscover, icon: Icons.auto_awesome),
                  FloatyBarItem(title: AppLocalizations.of(context).navSearch, icon: Icons.search),
                ],
              ),
            ],
          )
        : Stack(
            children: [
              FloatyBarView(
                controller: _floatyBarController,
                children: [
                  Home(
                    key: ValueKey("0"),
                    mainNavProvider: mainNavProvider,
                  ),
                  Search(
                    key: ValueKey("1"),
                  ),
                  Discover(
                    key: ValueKey("2"),
                    mainNavProvider: mainNavProvider,
                  ),
                  GenresPage(
                    key: ValueKey("3"),
                  ),
                ],
              ),
              LiquidGlassNavBar(
                controller: _floatyBarController,
                blurSigma: blurSigmaValue,
                items: [
                  LiquidGlassNavItem(
                      icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: AppLocalizations.of(context).navHome),
                  LiquidGlassNavItem(
                      icon: Icons.search_rounded, activeIcon: Icons.search_rounded, label: AppLocalizations.of(context).navSearch),
                  LiquidGlassNavItem(
                      icon: Icons.new_releases_outlined,
                      activeIcon: Icons.new_releases_rounded,
                      label: AppLocalizations.of(context).navUpdates),
                  LiquidGlassNavItem(
                      icon: Icons.grid_view_outlined,
                      activeIcon: Icons.grid_view_rounded,
                      label: AppLocalizations.of(context).navCategories),
                ],
              ),
              MiniResumePlayer(bottomOffset: MediaQuery.of(context).padding.bottom + 86),
            ],
          );
  }
}
