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
import 'package:kumaanime/ui/pages/library.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/pages/discover.dart';
import 'package:kumaanime/ui/pages/home.dart';
import 'package:kumaanime/ui/pages/terbaru.dart';
import 'package:kumaanime/ui/pages/jadwal.dart';
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

    DownloadHistory.initBox();

    ResumeSession.load();

    checkForUpdates().then((data) {
      if (data != null) {
        showUpdateSheet(
          context,
          data.description,
          data.downloadLink,
          data.preRelease,
          data.latestVersion,
        );
      }
    });

    provider.init();
  }

  final _floatyBarController = FloatyBottomBarController(length: 5);
  final _floatyOldController = FloatyBottomBarController(length: 5);
  final _barController = KumaAnimeBottomBarController(length: 5);

  bool popInvoked = false;
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

  Future<void> popTimeoutWindow() async {
    await Future.delayed(const Duration(seconds: 3));
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

        if (popInvoked) return await SystemNavigator.pop();

        floatingSnackBar(loc.mainNavExitPrompt);
        popInvoked = true;
        popTimeoutWindow();
      },
      child: Scaffold(
        body: MediaQuery.of(context).orientation == Orientation.landscape || Platform.isWindows || Platform.isLinux
            ? Row(
                children: [
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
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(
                          Icons.update_rounded,
                          color: _barController.currentIndex == 1 ? appTheme.onAccent : appTheme.textMainColor,
                        ),
                        label: const Text(
                          "Terbaru",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(
                          Icons.calendar_today_rounded,
                          color: _barController.currentIndex == 2 ? appTheme.onAccent : appTheme.textMainColor,
                        ),
                        label: const Text(
                          "Jadwal",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(
                          Icons.video_library_rounded,
                          color: _barController.currentIndex == 3 ? appTheme.onAccent : appTheme.textMainColor,
                        ),
                        label: Text(
                          AppLocalizations.of(context).navLibrary,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      NavigationRailDestination(
                        icon: Icon(
                          Icons.grid_view_rounded,
                          color: _barController.currentIndex == 4 ? appTheme.onAccent : appTheme.textMainColor,
                        ),
                        label: Text(
                          AppLocalizations.of(context).navMore,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                    selectedIndex: _barController.currentIndex,
                  ),
                  Expanded(
                    child: BottomBarView(
                      controller: _barController,
                      children: [
                        Discover(
                          mainNavProvider: mainNavProvider,
                        ),
                        const TerbaruPage(),
                        const JadwalPage(),
                        const LibraryPage(),
                        Home(
                          mainNavProvider: mainNavProvider,
                        ),
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
                  Discover(
                    key: const ValueKey("0"),
                    mainNavProvider: mainNavProvider,
                  ),
                  const TerbaruPage(
                    key: ValueKey("1"),
                  ),
                  const JadwalPage(
                    key: ValueKey("2"),
                  ),
                  const LibraryPage(
                    key: ValueKey("3"),
                  ),
                  Home(
                    key: const ValueKey("4"),
                    mainNavProvider: mainNavProvider,
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
                  const FloatyBarItem(title: "Terbaru", icon: Icons.update_rounded),
                  const FloatyBarItem(title: "Jadwal", icon: Icons.calendar_today_rounded),
                  FloatyBarItem(title: AppLocalizations.of(context).navLibrary, icon: Icons.video_library_rounded),
                  FloatyBarItem(title: AppLocalizations.of(context).navMore, icon: Icons.grid_view_rounded),
                ],
              ),
            ],
          )
        : Stack(
            children: [
              FloatyBarView(
                controller: _floatyBarController,
                children: [
                  Discover(
                    key: const ValueKey("0"),
                    mainNavProvider: mainNavProvider,
                  ),
                  const TerbaruPage(
                    key: ValueKey("1"),
                  ),
                  const JadwalPage(
                    key: ValueKey("2"),
                  ),
                  const LibraryPage(
                    key: ValueKey("3"),
                  ),
                  Home(
                    key: const ValueKey("4"),
                    mainNavProvider: mainNavProvider,
                  ),
                ],
              ),
              LiquidGlassNavBar(
                controller: _floatyBarController,
                blurSigma: blurSigmaValue,
                items: [
                  LiquidGlassNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: AppLocalizations.of(context).navHome,
                  ),
                  const LiquidGlassNavItem(
                    icon: Icons.update_outlined,
                    activeIcon: Icons.update_rounded,
                    label: "Terbaru",
                  ),
                  const LiquidGlassNavItem(
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today_rounded,
                    label: "Jadwal",
                  ),
                  LiquidGlassNavItem(
                    icon: Icons.video_library_outlined,
                    activeIcon: Icons.video_library_rounded,
                    label: AppLocalizations.of(context).navLibrary,
                  ),
                  LiquidGlassNavItem(
                    icon: Icons.grid_view_outlined,
                    activeIcon: Icons.grid_view_rounded,
                    label: AppLocalizations.of(context).navMore,
                  ),
                ],
              ),
              MiniResumePlayer(bottomOffset: MediaQuery.of(context).padding.bottom + 86),
            ],
          );
  }
}
