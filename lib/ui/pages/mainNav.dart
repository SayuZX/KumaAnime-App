import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/app/update.dart';
import 'package:kumaanime/core/app/version.dart';
import 'package:kumaanime/core/commons/utils.dart';
import 'package:kumaanime/core/data/downloadHistory.dart';
import 'package:kumaanime/core/data/resumeSession.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/providers/mainNavProvider.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/cards.dart';
import 'package:kumaanime/ui/models/widgets/dialogs/beta_announcement_dialog.dart';
import 'package:kumaanime/ui/models/widgets/fluentSideNav.dart';
import 'package:kumaanime/ui/models/widgets/floatyBar/controller.dart';
import 'package:kumaanime/ui/models/widgets/floatyBar/floatyBarView.dart';
import 'package:kumaanime/ui/models/widgets/floatyBar/floatyBottomBar.dart';
import 'package:kumaanime/ui/models/widgets/liquidGlassNavBar.dart';
import 'package:kumaanime/ui/models/widgets/miniResumePlayer.dart';
import 'package:kumaanime/ui/pages/discover.dart';
import 'package:kumaanime/ui/pages/library.dart';
import 'package:kumaanime/ui/pages/terbaru.dart';
import 'package:kumaanime/ui/pages/settings.dart';
import 'package:kumaanime/ui/pages/genres.dart';
import 'package:kumaanime/ui/pages/subIndo.dart';
import 'package:kumaanime/core/anime/providers/englishSource.dart';
import 'package:kumaanime/ui/pages/history.dart';
import 'package:kumaanime/ui/pages/search.dart';
import 'package:kumaanime/ui/pages/settingPages/stats.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => MainNavigatorState();
}

class MainNavigatorState extends State<MainNavigator>
    with TickerProviderStateMixin {
  // Controllers – satu set untuk bottom-bar, satu untuk sidebar desktop
  final _floatyBarController = FloatyBottomBarController(length: 5);
  final _floatyOldController = FloatyBottomBarController(length: 5);
  final _desktopController = FloatyBottomBarController(length: 9);
  final searchController = TextEditingController();

  bool popInvoked = false;
  late MainNavProvider mainNavProvider;

  @override
  void dispose() {
    _desktopController.currentIndexNotifier.removeListener(_onTabChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _desktopController.currentIndexNotifier.addListener(_onTabChanged);

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      BetaAnnouncementDialog.showBetaAnnouncementDialogIfNeeded(
        context,
        AppVersion.instance.version,
      );
    });

    provider.init();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void rebuildCards() {
    mainNavProvider.recentlyUpdatedList.clear();

    final isMobile = !mainNavProvider.tv && mainNavProvider.isAndroid;

    for (final elem in mainNavProvider.recentlyUpdatedListData) {
      final title = elem.title['english'] ?? elem.title['romaji'] ?? '';
      mainNavProvider.recentlyUpdatedList.add(
        Cards.animeCard(
          elem.id,
          (currentUserSettings?.nativeTitle ?? false)
              ? elem.title['native'] ?? title
              : title,
          elem.cover,
          rating: (elem.rating ?? 0) / 10,
          isMobile: isMobile,
        ),
      );
    }

    mainNavProvider.recommendedList.clear();
    for (final item in mainNavProvider.recommendedListData) {
      final title = item.title['english'] ?? item.title['romaji'] ?? '';
      mainNavProvider.recommendedList.add(Cards.animeCard(
        item.id,
        (currentUserSettings?.nativeTitle ?? false)
            ? item.title['native'] ?? title
            : title,
        item.cover,
        rating: item.rating,
        isMobile: isMobile,
      ));
    }

    mainNavProvider.thisSeason.clear();
    for (final item in mainNavProvider.thisSeasonData) {
      final title = item.title['english'] ?? item.title['romaji'] ?? '';
      mainNavProvider.thisSeason.add(Cards.animeCard(
        item.id,
        (currentUserSettings?.nativeTitle ?? false)
            ? item.title['native'] ?? title
            : title,
        item.cover,
        rating: item.rating,
        isMobile: isMobile,
      ));
    }

    setState(() {});
  }

  Future<void> popTimeoutWindow() async {
    await Future.delayed(const Duration(seconds: 3));
    popInvoked = false;
  }

  bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    mainNavProvider = context.watch<MainNavProvider>();

    if (mainNavProvider.recentlyUpdatedList.isNotEmpty &&
        mainNavProvider.thisSeason.isNotEmpty) {
      rebuildCards();
    }

    double blurSigmaValue = currentUserSettings!.navbarTranslucency ?? 5;
    if (blurSigmaValue <= 1) blurSigmaValue = blurSigmaValue * 10;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) async {
        // Coba reset ke tab pertama di controller yang aktif
        final activeCtrl =
            _isDesktop ? _desktopController : _floatyBarController;
        final oldCtrl = _isDesktop ? _desktopController : _floatyOldController;

        if (activeCtrl.currentIndex != 0) {
          activeCtrl.currentIndex = 0;
          return;
        }
        if (oldCtrl.currentIndex != 0) {
          oldCtrl.currentIndex = 0;
          return;
        }

        if (popInvoked) return await SystemNavigator.pop();

        floatingSnackBar(loc.mainNavExitPrompt);
        popInvoked = true;
        popTimeoutWindow();
      },
      child: Scaffold(
        body: _isDesktop
            ? _desktopLayout(context, loc)
            : _bottomBar(context, blurSigmaValue, loc),
      ),
    );
  }

  // ─── Desktop layout (Windows / Linux / macOS) ─────────────────────────────

  Widget _desktopLayout(BuildContext context, AppLocalizations loc) {
    final pages = [
      Discover(
        key: const ValueKey('d0'),
        mainNavProvider: mainNavProvider,
        onViewAllPressed: () => _desktopController.currentIndex = 5,
        onSettingsPressed: () => _desktopController.currentIndex = 7,
      ),
      const TerbaruPage(key: ValueKey('d1'), isTab: true),
      const GenresPage(key: ValueKey('d2'), isTab: true),
      const SubIndoPage(key: ValueKey('d3'), isTab: true),
      SubIndoPage(
        key: const ValueKey('d4'),
        source: EnglishSource(),
        pageTitle: loc.subEng,
        searchHint: loc.subEngSearchHint,
        isTab: true,
      ),
      const LibraryPage(key: ValueKey('d5'), isTab: true),
      const HistoryPage(key: ValueKey('d6'), isTab: true),
      const SettingsPage(key: ValueKey('d7'), isTab: true),
      Search(key: const ValueKey('d8'), isTab: true, externalController: searchController),
    ];

    final navItems = [
      FluentNavItem(
        icon: HugeIcons.strokeRoundedHome01,
        activeIcon: HugeIcons.strokeRoundedHome01,
        label: loc.navHome,
      ),
      FluentNavItem(
        icon: HugeIcons.strokeRoundedClock01,
        activeIcon: HugeIcons.strokeRoundedClock01,
        label: loc.navUpdates,
      ),
      FluentNavItem(
        icon: HugeIcons.strokeRoundedGrid,
        activeIcon: HugeIcons.strokeRoundedGrid,
        label: loc.subIndoGenres,
      ),
      FluentNavItem(
        icon: Icons.subtitles_outlined,
        activeIcon: Icons.subtitles_rounded,
        label: 'Sub Indo',
      ),
      FluentNavItem(
        icon: Icons.translate_outlined,
        activeIcon: Icons.translate_rounded,
        label: 'English',
      ),
      FluentNavItem(
        icon: Icons.bookmark_outline_rounded,
        activeIcon: Icons.bookmark_rounded,
        label: 'Bookmarks',
      ),
      FluentNavItem(
        icon: Icons.history_rounded,
        activeIcon: Icons.history_rounded,
        label: 'History',
      ),
      FluentNavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: loc.settingsTitle,
      ),
    ];

    return Row(
      children: [
        // ── Sidebar Fluent ──────────────────────────────────────────────
        FluentSideNav(
          controller: _desktopController,
          items: navItems,
          expandedWidth: 200,
          collapsedWidth: 64,
          expandBreakpoint: 900,
        ),

        // ── Content area ────────────────────────────────────────────────
        Expanded(
          child: Column(
            children: [
              _desktopTopBar(context, loc),
              Expanded(
                child: FloatyBarView(
                  controller: _desktopController,
                  children: pages,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPageTitle(int index, AppLocalizations loc) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return loc.navUpdates;
      case 2:
        return loc.subIndoGenres;
      case 3:
        return 'Sub Indo';
      case 4:
        return 'English';
      case 5:
        return 'Bookmarks';
      case 6:
        return 'History';
      case 7:
        return loc.settingsTitle;
      case 8:
        return 'Search';
      default:
        return '';
    }
  }

  Widget _desktopSearchBar(BuildContext context, AppLocalizations loc) {
    return Container(
      width: 400,
      height: 40,
      decoration: BoxDecoration(
        color: appTheme.backgroundSubColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (currentUserSettings?.darkMode ?? true ? Colors.white : Colors.black)
              .withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: TextField(
          controller: searchController,
          autofocus: true,
          style: TextStyle(
            color: appTheme.textMainColor,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: appTheme.accentColor,
              size: 20,
            ),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                    onPressed: () {
                      searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            hintText: loc.subEngSearchHint,
            hintStyle: TextStyle(
              color: appTheme.textSubColor.withValues(alpha: 0.6),
              fontSize: 13,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onChanged: (val) {
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _desktopTopBar(BuildContext context, AppLocalizations loc) {
    final avatarImage = storedUserData?.avatar != null
        ? NetworkImage(storedUserData!.avatar!)
        : const AssetImage('lib/assets/images/chisato_AI.jpg') as ImageProvider;

    final isSearching = _desktopController.currentIndex == 8;
    final pageTitle = _getPageTitle(_desktopController.currentIndex, loc);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: appTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: (currentUserSettings?.darkMode ?? true ? Colors.white : Colors.black)
                .withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (isSearching) ...[
            _desktopSearchBar(context, loc),
            const Spacer(),
            IconButton(
              onPressed: () {
                searchController.clear();
                FocusManager.instance.primaryFocus?.unfocus();
                _desktopController.currentIndex = 0;
              },
              icon: Icon(
                Icons.close_rounded,
                color: appTheme.textMainColor,
                size: 22,
              ),
            ),
          ] else ...[
            Text(
              pageTitle,
              style: TextStyle(
                color: appTheme.textMainColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                _desktopController.currentIndex = 8;
              },
              icon: Icon(
                Icons.search_rounded,
                color: appTheme.textMainColor,
                size: 22,
              ),
            ),
          ],
          const SizedBox(width: 12),

          // User Profile Avatar
          InkWell(
            onTap: () {
              if (storedUserData != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserStats(userModal: storedUserData!),
                  ),
                );
              } else {
                _desktopController.currentIndex = 5;
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: avatarImage,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.fullscreen_rounded,
            color: appTheme.textSubColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ─── Mobile layout ─────────────────────────────────────────────────────────

  Widget _bottomBar(
      BuildContext context, double blurSigmaValue, AppLocalizations loc) {
    final useOld = currentUserSettings?.useOldNavbar ?? false;
    final ctrl = useOld ? _floatyOldController : _floatyBarController;

    final pages = [
      Discover(
          key: ValueKey(useOld ? 'o0' : 'm0'),
          mainNavProvider: mainNavProvider,
          onViewAllPressed: () => ctrl.currentIndex = 2,
          onSettingsPressed: () => ctrl.currentIndex = 4),
      TerbaruPage(key: ValueKey(useOld ? 'o1' : 'm1')),
      LibraryPage(key: ValueKey(useOld ? 'o2' : 'm2')),
      HistoryPage(key: ValueKey(useOld ? 'o3' : 'm3')),
      SettingsPage(
          key: ValueKey(useOld ? 'o4' : 'm4'), isTab: true),
    ];

    return Stack(
      children: [
        FloatyBarView(controller: ctrl, children: pages),
        if (useOld)
          FloatyBottomBar(
            controller: ctrl,
            accentColor: appTheme.accentColor,
            backgroundColor: appTheme.backgroundSubColor
                .withValues(alpha: currentUserSettings?.navbarTranslucency ?? 0.5),
            items: [
              FloatyBarItem(title: loc.navHome, icon: Icons.home),
              FloatyBarItem(title: loc.tabTerbaru, icon: Icons.update_rounded),
              FloatyBarItem(
                  title: loc.navLibrary, icon: Icons.bookmark_rounded),
              FloatyBarItem(title: 'History', icon: Icons.history_rounded),
              FloatyBarItem(title: loc.settingsTitle, icon: Icons.settings_rounded),
            ],
          )
        else ...[
          LiquidGlassNavBar(
            controller: ctrl,
            blurSigma: blurSigmaValue,
            items: [
              LiquidGlassNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: loc.navHome,
              ),
              LiquidGlassNavItem(
                icon: Icons.update_outlined,
                activeIcon: Icons.update_rounded,
                label: loc.tabTerbaru,
              ),
              LiquidGlassNavItem(
                icon: Icons.bookmark_outline_rounded,
                activeIcon: Icons.bookmark_rounded,
                label: 'Bookmarks',
              ),
              LiquidGlassNavItem(
                icon: Icons.history_rounded,
                activeIcon: Icons.history_rounded,
                label: 'History',
              ),
              LiquidGlassNavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: loc.settingsTitle,
              ),
            ],
          ),
          MiniResumePlayer(
              bottomOffset: MediaQuery.of(context).padding.bottom + 86),
        ],
      ],
    );
  }
}
