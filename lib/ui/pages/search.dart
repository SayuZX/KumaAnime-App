import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/preferences.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/core/database/handler/handler.dart';
import 'package:kumaanime/core/database/types.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/widgets/cards.dart';
import 'package:kumaanime/ui/models/widgets/cards/animeCardExtended.dart';
import 'package:kumaanime/ui/models/widgets/loader.dart';

class Search extends StatefulWidget {
  final bool isTab;
  final TextEditingController? externalController;

  const Search({
    super.key,
    this.isTab = false,
    this.externalController,
  });

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  List<DatabaseSearchResult> results = [];
  List<DatabaseSearchResult> exactMatches = [];
  late TextEditingController _controller;
  final TextEditingController textEditingController = TextEditingController();
  bool _searching = false;
  Timer? debounce;
  final db = DatabaseHandler();

  bool exactMatch = false;
  bool verticalCards = false;

  @override
  void initState() {
    super.initState();
    verticalCards = (currentUserSettings?.listLayout == 'list') || (userPreferences?.searchPageListMode ?? false);
    _controller = widget.externalController ?? textEditingController;
    _controller.addListener(_onSearchChanged);
    if (_controller.text.isNotEmpty) {
      _searching = true;
      addCards(_controller.text);
    }
  }

  void _onSearchChanged() {
    final query = _controller.text;
    if (debounce?.isActive ?? false) debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty) {
        if (mounted) {
          setState(() {
            results = [];
            exactMatches = [];
            _searching = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _searching = true;
        });
      }
      await addCards(query);
    });
  }

  Future<void> addCards(String query) async {
    final searchResults = await db.search(query);
    if (!mounted) return;

    List<DatabaseSearchResult> tempResults = [];
    List<DatabaseSearchResult> tempExact = [];

    if (searchResults.isNotEmpty) {
      for (var ele in searchResults) {
        final String title = ele.title['english'] ?? ele.title['romaji'] ?? '';
        tempResults.add(ele);
        if (query.toLowerCase() == title.toLowerCase()) {
          tempExact.add(ele);
        }
      }
    }

    setState(() {
      results = tempResults;
      exactMatches = tempExact;
      _searching = false;
    });
  }

  bool get compactCards => (currentUserSettings?.listLayout ?? 'grid') == 'compact';
  final nativeTitle = currentUserSettings?.nativeTitle ?? false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom + 100;

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          padding: EdgeInsets.only(
            top: widget.isTab ? 16 : MediaQuery.of(context).padding.top + 16,
            bottom: bottomPad,
          ),
          children: [
            // Header (only on mobile / non-tab view)
            if (!widget.isTab)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(HugeIcons.strokeRoundedArrowLeft01, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.searchTitle,
                      style: TextStyle(
                        color: appTheme.textMainColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Search Bar (only if not using external controller)
            if (widget.externalController == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: appTheme.backgroundSubColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    cursorColor: appTheme.accentColor,
                    style: TextStyle(color: appTheme.textMainColor),
                    decoration: InputDecoration(
                      hintText: loc.searchHint,
                      hintStyle: TextStyle(color: appTheme.textSubColor.withValues(alpha: 0.6)),
                      prefixIcon: Icon(
                        HugeIcons.strokeRoundedSearch01,
                        color: appTheme.accentColor,
                        size: 20,
                      ),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 20),
                              onPressed: () {
                                _controller.clear();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),

            // Sleek Options Chips (Fluent-style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _fluentFilterChip(
                    label: loc.searchExactMatch,
                    selected: exactMatch,
                    icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                    onSelected: (val) {
                      setState(() {
                        exactMatch = val;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  _fluentFilterChip(
                    label: loc.searchListView,
                    selected: verticalCards,
                    icon: HugeIcons.strokeRoundedDashboardSquare01,
                    onSelected: (val) {
                      setState(() {
                        verticalCards = val;
                        UserPreferences.saveUserPreferences(
                          UserPreferencesModal(searchPageListMode: val),
                        );
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search Results or Loading
            _searching
                ? Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        KumaAnimeLoading(color: appTheme.accentColor, size: 40),
                        const SizedBox(height: 16),
                        Text(
                          loc.searchSearching,
                          style: TextStyle(
                            color: appTheme.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      ],
                    ),
                  )
                : _searchResultsWidget(),
          ],
        ),
      ),
    );
  }

  Widget _fluentFilterChip({
    required String label,
    required bool selected,
    required IconData icon,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? appTheme.onAccent : appTheme.textSubColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: selected ? appTheme.onAccent : appTheme.textMainColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      selected: selected,
      selectedColor: appTheme.accentColor,
      backgroundColor: appTheme.backgroundSubColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? appTheme.accentColor : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      onSelected: onSelected,
    );
  }

  Widget _searchResultsWidget() {
    final listToDisplay = exactMatch ? exactMatches : results;

    if (listToDisplay.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          children: [
            Image.asset('lib/assets/images/ghost.png', height: 100),
            const SizedBox(height: 16),
            Text(
              _controller.text.isEmpty ? "Type something to search..." : "No results found",
              style: TextStyle(color: appTheme.textSubColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: verticalCards ? 450.0 : (compactCards ? 120.0 : 180.0),
          mainAxisExtent: verticalCards
              ? 150.0
              : Platform.isAndroid
                  ? (compactCards ? 165.0 : 220.0)
                  : 260.0,
          crossAxisSpacing: verticalCards ? 10.0 : 10.0,
          mainAxisSpacing: 15.0,
        ),
        itemCount: listToDisplay.length,
        itemBuilder: (context, index) {
          final it = listToDisplay[index];
          final image = it.cover;
          final String title = it.title['english'] ?? it.title['romaji'] ?? '';
          final id = it.id;

          if (verticalCards) {
            return AnimeCardExtended(
              id: id,
              title: nativeTitle ? it.title['native'] ?? title : title,
              imageUrl: image,
              rating: it.rating ?? 0,
              customWidth: 450,
              totalEpisodes: it.totalEpisodes,
              surfaceColor: appTheme.backgroundSubColor.withValues(alpha: 0.5),
            );
          } else {
            return Center(
              child: Cards.animeCard(
                id,
                nativeTitle ? it.title['native'] ?? title : title,
                image,
                rating: it.rating,
                isAnime: true,
                isMobile: Platform.isAndroid,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged);
    textEditingController.dispose();
    debounce?.cancel();
    super.dispose();
  }
}
