import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/commons/extensions.dart';
import 'package:kumaanime/core/database/anilist/queries.dart';
import 'package:kumaanime/core/database/anilist/types.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/widgets/cards.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/cards/animeCard.dart';
import 'package:kumaanime/ui/models/widgets/loader.dart';
import 'package:kumaanime/ui/pages/genre_anime_list.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/core/commons/genresAndTags.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GenresPage extends StatefulWidget {
  final bool isTab;
  const GenresPage({super.key, this.isTab = false});

  @override
  State<GenresPage> createState() => _GenresPageState();
}

class _GenresPageState extends State<GenresPage> with SingleTickerProviderStateMixin {
  // --- Genres Grid State ---
  final TextEditingController _searchController = TextEditingController();
  List<String> _allGenres = [];
  List<String> _filteredGenres = [];
  bool _isLoadingGenres = true;
  bool _isAscending = true;
  late AnimationController _pulseController;

  // --- Advanced Filter State ---
  bool _showAdvancedResults = false;
  List<String> selectedGenres = [];
  List<String> selectedTags = [];

  String sortType = "";
  List<String> sortTypesString = [];
  Map<String, AnilistSortType> sortTypesMap = {};

  RangeValues ratingRange = const RangeValues(1, 10);

  List<AnimeCard> searchResultsAsWidgets = [];

  int currentLoadedPage = 1;

  bool _searchingAdvanced = false;
  bool _isAdvancedLazyLoading = false;
  bool _firstSearchDone = false;

  final ScrollController _advancedScrollController = ScrollController();
  final ScrollController _tagsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Genres Grid init
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _fetchGenres();
    _searchController.addListener(_onSearchChanged);

    // Advanced Search init
    _advancedScrollController.addListener(_advancedScrollListener);

    sortType = _toFriendlyString(AnilistSortType.trendingDesc.value);
    for (int i = 0; i < AnilistSortType.values.length; i++) {
      final e = AnilistSortType.values[i];
      final name = _toFriendlyString(e.value);
      sortTypesString.add(name);
      sortTypesMap.addAll({name: e});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    _advancedScrollController.dispose();
    _tagsScrollController.dispose();
    super.dispose();
  }

  // --- Genres Grid Logic ---
  Future<void> _fetchGenres() async {
    setState(() {
      _isLoadingGenres = true;
    });

    try {
      final genresList = await AnilistQueries().fetchGenres();
      if (genresList.isEmpty) {
        _allGenres = List.from(genres);
      } else {
        _allGenres = genresList;
      }
    } catch (e) {
      _allGenres = List.from(genres);
    }

    _sortGenres();

    if (mounted) {
      setState(() {
        _isLoadingGenres = false;
        _filteredGenres = _allGenres;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGenres = _allGenres
          .where((genre) => genre.toLowerCase().contains(query))
          .toList();
    });
  }

  void _toggleSort() {
    setState(() {
      _isAscending = !_isAscending;
      _sortGenres();
      _onSearchChanged();
    });
  }

  void _sortGenres() {
    _allGenres.sort((a, b) {
      if (_isAscending) {
        return a.compareTo(b);
      } else {
        return b.compareTo(a);
      }
    });
  }

  Color _getGenreColor(String genre) {
    int hash = genre.hashCode;
    double hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.4).toColor();
  }

  // --- Advanced Filter Logic ---
  static String _toFriendlyString(String input) {
    return input.split("_").map((e) => e.toLowerCase().capitalize()).join(" ");
  }

  void _advancedScrollListener() async {
    if (_advancedScrollController.position.pixels >= _advancedScrollController.position.maxScrollExtent - 300) {
      if (!_isAdvancedLazyLoading && !_searchingAdvanced && _firstSearchDone && _showAdvancedResults) {
        print("loading more advanced results...");
        getAdvancedList(lazyLoaded: true);
      }
    }
  }

  Future<void> getAdvancedList({bool lazyLoaded = false}) async {
    if (lazyLoaded) {
      _isAdvancedLazyLoading = true;
      currentLoadedPage++;
    } else {
      currentLoadedPage = 1;
    }
    if (!_firstSearchDone) _firstSearchDone = true;
    try {
      setState(() {
        searchResultsAsWidgets = lazyLoaded ? searchResultsAsWidgets : [];
        _searchingAdvanced = true;
      });
      if (selectedGenres.isEmpty && selectedTags.isEmpty) {
        setState(() {
          _searchingAdvanced = false;
          _isAdvancedLazyLoading = false;
        });
        return;
      }
      print("loading page $currentLoadedPage");
      final res = await AnilistQueries().advancedSearch(
        genres: selectedGenres,
        tags: selectedTags,
        page: currentLoadedPage,
        ratingHigh: ratingRange.end.toInt(),
        ratingLow: ratingRange.start.toInt(),
        sort: sortTypesMap[sortType]!,
      );
      
      final List<AnimeCard> newWidgets = [];
      res.forEach((e) {
        final defaultTitle = e.title['english'] ?? e.title['romaji'] ?? '';
        final title = (currentUserSettings?.nativeTitle ?? false) ? e.title['native'] ?? defaultTitle : defaultTitle;
        newWidgets.add(
          Cards.animeCard(
            e.id,
            title,
            e.cover,
            ongoing: e.status == "RELEASING",
            rating: e.rating,
            isMobile: Platform.isAndroid,
          ),
        );
      });

      setState(() {
        searchResultsAsWidgets.addAll(newWidgets);
        _searchingAdvanced = false;
        _isAdvancedLazyLoading = false;
      });
    } catch (err, st) {
      print(st);
      if (currentUserSettings?.showErrors ?? false) {
        floatingSnackBar(err.toString());
      }
      setState(() {
        _searchingAdvanced = false;
        _isAdvancedLazyLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDesktop = Platform.isWindows || Platform.isLinux;

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: Padding(
        padding: pagePadding(context),
        child: Column(
          children: [
            if (!widget.isTab) topRow(context, loc.genresTitle),
            _buildSearchBar(loc),
            Expanded(
              child: _showAdvancedResults
                  ? _buildAdvancedResults(loc)
                  : (_isLoadingGenres ? _buildSkeletonGrid(isDesktop) : _buildGenresGrid(loc, isDesktop)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Header & Search Bar View ---
  // --- Header & Search Bar View ---
  Widget _buildSearchBar(AppLocalizations loc) {
    final hasGenreFilter = selectedGenres.isNotEmpty || selectedTags.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Sort toggle chip
          _fluentFilterChip(
            label: _isAscending ? loc.genresSortAlphabeticalAsc : loc.genresSortAlphabeticalDesc,
            selected: !_isAscending,
            icon: Icons.sort_by_alpha_rounded,
            onSelected: (val) {
              _toggleSort();
            },
          ),
          const SizedBox(width: 12),
          // Advanced filter toggle chip
          _fluentFilterChip(
            label: hasGenreFilter
                ? 'Filter (${selectedGenres.length + selectedTags.length})'
                : 'Advanced Filter',
            selected: _showAdvancedResults || hasGenreFilter,
            icon: Icons.tune_rounded,
            onSelected: (val) {
              _showFilterSheet(loc);
            },
          ),
          if (hasGenreFilter) ...[
            const SizedBox(width: 12),
            // Clear filter chip
            _fluentFilterChip(
              label: 'Clear',
              selected: false,
              icon: Icons.close_rounded,
              onSelected: (val) {
                setState(() {
                  selectedGenres.clear();
                  selectedTags.clear();
                  _showAdvancedResults = false;
                  searchResultsAsWidgets.clear();
                  _firstSearchDone = false;
                });
              },
            ),
          ],
        ],
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

  // --- Genres Grid View ---
  Widget _buildGenresGrid(AppLocalizations loc, bool isDesktop) {
    if (_filteredGenres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: appTheme.textSubColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              loc.genresNoResults,
              style: TextStyle(color: appTheme.textSubColor, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isDesktop ? 240 : 180,
        mainAxisExtent: isDesktop ? 100 : 90,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _filteredGenres.length,
      itemBuilder: (context, index) {
        final genre = _filteredGenres[index];
        final color = _getGenreColor(genre);
        return _GenreCard(
          genre: genre,
          color: color,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GenreAnimeListPage(genre: genre),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonGrid(bool isDesktop) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + (_pulseController.value * 0.5),
          child: child,
        );
      },
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: isDesktop ? 240 : 180,
          mainAxisExtent: isDesktop ? 100 : 90,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: 16,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: appTheme.backgroundSubColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // --- Advanced Results View ---
  Widget _buildAdvancedResults(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: searchResultsAsWidgets.isEmpty && !_searchingAdvanced
          ? Center(
              child: _firstSearchDone
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'lib/assets/images/ghost.png',
                          color: appTheme.textMainColor,
                          height: 80,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.genresNoMatches,
                          style: TextStyle(color: appTheme.textMainColor, fontSize: 17),
                        ),
                      ],
                    )
                  : Text(
                      loc.genresApplyFiltersHint,
                      style: TextStyle(color: appTheme.textMainColor, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
            )
          : Container(
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    appTheme.backgroundColor,
                    appTheme.backgroundColor.withOpacity(0),
                    appTheme.backgroundColor.withOpacity(0),
                    appTheme.backgroundColor
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.00, 0.04, 0.96, 1],
                ),
              ),
              child: SingleChildScrollView(
                controller: _advancedScrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: Platform.isAndroid ? 140 : 180,
                        mainAxisExtent: Platform.isAndroid ? 220 : 260,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      padding: EdgeInsets.only(
                        top: 20,
                        bottom: MediaQuery.of(context).padding.bottom + 20,
                      ),
                      shrinkWrap: true,
                      itemCount: searchResultsAsWidgets.length,
                      itemBuilder: (context, index) => Container(
                        alignment: Alignment.center,
                        child: searchResultsAsWidgets[index],
                      ),
                    ),
                    if (_searchingAdvanced)
                      Container(
                        margin: EdgeInsets.only(
                          top: 20,
                          bottom: MediaQuery.of(context).padding.bottom + 20,
                        ),
                        child: Center(
                          child: KumaAnimeLoading(color: appTheme.accentColor, size: 40),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showFilterSheet(AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setChildState) => Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: 15,
            right: 15,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.genresFilters,
                  style: TextStyle(
                    color: appTheme.textMainColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _scrollableListWithTitle(
                  setChildState,
                  title: loc.genresTitle,
                  mainList: genres,
                  selectedList: selectedGenres,
                ),
                _scrollableListWithTitle(
                  setChildState,
                  title: loc.genresTagsTitle,
                  mainList: tags,
                  selectedList: selectedTags,
                ),
                _scrollableRadioListWithTitle(
                  title: loc.genresSortTitle,
                  value: sortType,
                  setChildState: setChildState,
                  options: sortTypesString,
                  onTap: (e) {
                    sortType = e;
                  },
                ),
                _filterItemTitle(loc.genresRatingRange),
                RangeSlider(
                  values: ratingRange,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: appTheme.accentColor,
                  labels: RangeLabels(
                    ratingRange.start.toString(),
                    ratingRange.end.toString(),
                  ),
                  onChanged: (rv) {
                    setChildState(() {
                      ratingRange = RangeValues(
                        rv.start.roundToDouble(),
                        rv.end.roundToDouble(),
                      );
                    });
                  },
                ),
                Container(
                  margin: const EdgeInsets.only(top: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 20),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appTheme.accentColor,
                          ),
                          child: Text(
                            loc.genresCancel,
                            style: TextStyle(color: appTheme.backgroundColor),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (selectedGenres.isEmpty && selectedTags.isEmpty) {
                            setState(() {
                              _showAdvancedResults = false;
                              searchResultsAsWidgets.clear();
                              _firstSearchDone = false;
                            });
                          } else {
                            setState(() {
                              _showAdvancedResults = true;
                            });
                            getAdvancedList().then((_) {
                              if (Platform.isWindows) {
                                getAdvancedList(lazyLoaded: true);
                              }
                            });
                          }
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appTheme.accentColor,
                        ),
                        child: Text(
                          loc.genresApply,
                          style: TextStyle(color: appTheme.backgroundColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Container _filterItemTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 15, top: 20, left: 20),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: appTheme.textMainColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Column _scrollableRadioListWithTitle<T>({
    required StateSetter setChildState,
    required String title,
    required T value,
    required List<String> options,
    required void Function(String selectedItem) onTap,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 15, top: 20, left: 20),
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: TextStyle(
              color: appTheme.textMainColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options
                .map(
                  (e) => Container(
                    margin: const EdgeInsets.only(left: 5, right: 5),
                    child: GestureDetector(
                      onTap: () {
                        onTap(e);
                        setChildState(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: value == e ? appTheme.accentColor : appTheme.backgroundSubColor,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          e,
                          style: TextStyle(
                            color: value == e ? appTheme.backgroundColor : appTheme.textMainColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Column _scrollableListWithTitle(
    StateSetter setChildState, {
    required String title,
    required List<String> mainList,
    required List<String> selectedList,
  }) {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 15, top: 20, left: 20),
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  color: appTheme.textMainColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => StatefulBuilder(
                    builder: (context, setDialogState) => AlertDialog(
                      backgroundColor: const Color(0xff121212),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Text(
                              title,
                              style: TextStyle(color: appTheme.textMainColor, fontSize: 23),
                            ),
                          ),
                          SizedBox(
                            height: 550,
                            width: 500,
                            child: Scrollbar(
                              controller: _tagsScrollController,
                              interactive: true,
                              child: GridView(
                                controller: _tagsScrollController,
                                shrinkWrap: true,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 15,
                                  crossAxisSpacing: 15,
                                ),
                                children: mainList
                                    .map(
                                      (e) => GestureDetector(
                                        onTap: () {
                                          if (selectedList.contains(e)) {
                                            selectedList.remove(e);
                                          } else {
                                            selectedList.add(e);
                                          }
                                          setChildState(() {});
                                          setDialogState(() {});
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          padding: const EdgeInsets.only(left: 10, right: 10),
                                          height: 40,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: selectedList.contains(e)
                                                ? appTheme.accentColor
                                                : appTheme.backgroundSubColor,
                                            borderRadius: BorderRadius.circular(13),
                                          ),
                                          child: Text(
                                            e,
                                            style: TextStyle(
                                              color: selectedList.contains(e)
                                                  ? appTheme.backgroundColor
                                                  : appTheme.textMainColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appTheme.accentColor,
                              ),
                              child: Text(
                                loc.genresClose,
                                style: TextStyle(color: appTheme.backgroundColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              icon: Icon(
                Icons.grid_3x3_rounded,
                color: appTheme.textMainColor,
              ),
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: mainList
                .map(
                  (e) => Container(
                    margin: const EdgeInsets.only(left: 5, right: 5),
                    child: GestureDetector(
                      onTap: () {
                        if (selectedList.contains(e)) {
                          selectedList.remove(e);
                        } else {
                          selectedList.add(e);
                        }
                        setChildState(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedList.contains(e)
                              ? appTheme.accentColor
                              : appTheme.backgroundSubColor,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          e,
                          style: TextStyle(
                            color: selectedList.contains(e)
                                ? appTheme.backgroundColor
                                : appTheme.textMainColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _GenreCard extends StatefulWidget {
  final String genre;
  final Color color;
  final VoidCallback onTap;

  const _GenreCard({
    required this.genre,
    required this.color,
    required this.onTap,
  });

  @override
  State<_GenreCard> createState() => _GenreCardState();
}

class _GenreCardState extends State<_GenreCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getGenreImageUrl(String genre) {
    final cleanGenre = genre.toLowerCase().trim();
    switch (cleanGenre) {
      case 'action':
        return 'https://images.unsplash.com/photo-1618336753974-aae8e04506aa?w=400&q=80';
      case 'adventure':
        return 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=400&q=80';
      case 'comedy':
        return 'https://images.unsplash.com/photo-1580477667995-2b94f01c9516?w=400&q=80';
      case 'drama':
        return 'https://images.unsplash.com/photo-1613376023733-0a73315d9b06?w=400&q=80';
      case 'ecchi':
      case 'hentai':
        return 'https://images.unsplash.com/photo-1560942485-b2a11cc13456?w=400&q=80';
      case 'fantasy':
        return 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=400&q=80';
      case 'horror':
        return 'https://images.unsplash.com/photo-1617396900799-f4ec2b43c7ae?w=400&q=80';
      case 'mahou shoujo':
        return 'https://images.unsplash.com/photo-1502134249126-9f3755a50d78?w=400&q=80';
      case 'mecha':
        return 'https://images.unsplash.com/photo-1563089145-599997674d42?w=400&q=80';
      case 'music':
        return 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=400&q=80';
      case 'mystery':
        return 'https://images.unsplash.com/photo-1613376023733-0a73315d9b06?w=400&q=80';
      case 'psychological':
        return 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400&q=80';
      case 'romance':
        return 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=400&q=80';
      case 'sci-fi':
        return 'https://images.unsplash.com/photo-1563089145-599997674d42?w=400&q=80';
      case 'slice of life':
        return 'https://images.unsplash.com/photo-1601049676099-e7ed07d825b0?w=400&q=80';
      case 'sports':
        return 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=400&q=80';
      case 'supernatural':
        return 'https://images.unsplash.com/photo-1502134249126-9f3755a50d78?w=400&q=80';
      case 'thriller':
        return 'https://images.unsplash.com/photo-1617396900799-f4ec2b43c7ae?w=400&q=80';
      default:
        return 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=400&q=80';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: _getGenreImageUrl(widget.genre),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: widget.color.withOpacity(0.3),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: widget.color.withOpacity(0.3),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      widget.genre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
