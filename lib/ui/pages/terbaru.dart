import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/app/values.dart';
import 'package:kumaanime/core/commons/enums/hiveEnums.dart';
import 'package:kumaanime/core/database/anilist/anilist.dart';
import 'package:kumaanime/ui/models/widgets/cards.dart';
import 'package:kumaanime/ui/models/widgets/comingSoonOverlay.dart';
import 'package:kumaanime/ui/models/widgets/header.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';

class TerbaruPage extends StatefulWidget {
  final bool isTab;
  const TerbaruPage({super.key, this.isTab = false});

  @override
  State<TerbaruPage> createState() => _TerbaruPageState();
}

class _TerbaruPageState extends State<TerbaruPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.isTab)
              buildHeader(AppLocalizations.of(context).navUpdates, context),
            TabBar(
              controller: _tabController,
              indicatorColor: appTheme.accentColor,
              labelColor: appTheme.accentColor,
              unselectedLabelColor: appTheme.textSubColor,
              tabs: [
                Tab(text: AppLocalizations.of(context).tabTerbaruEpisodes),
                Tab(text: AppLocalizations.of(context).tabTerbaruAnime),
                Tab(text: AppLocalizations.of(context).tabTerbaruManga),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  TerbaruTabContent(type: "episodes"),
                  TerbaruTabContent(type: "new_anime"),
                  TerbaruTabContent(type: "new_manga"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TerbaruTabContent extends StatefulWidget {
  final String type;
  const TerbaruTabContent({super.key, required this.type});

  @override
  State<TerbaruTabContent> createState() => _TerbaruTabContentState();
}

class _TerbaruTabContentState extends State<TerbaruTabContent> {
  final RefreshController _refreshController = RefreshController();
  final List<dynamic> _items = [];
  int _page = 1;
  bool _hasNextPage = true;
  bool _isLoading = true;
  bool _isError = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<bool> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _isOffline = false;
    });

    final cached = await _readCache();
    if (cached != null && cached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _items.addAll(cached);
          _isLoading = false;
        });
      }
    }

    _fetchData(refresh: true);
  }

  Future<void> _fetchData({bool refresh = false}) async {
    final online = await _checkConnection();
    if (!online) {
      if (mounted) {
        setState(() {
          _isOffline = true;
          _isLoading = false;
        });
      }
      if (refresh) {
        _refreshController.refreshFailed();
      } else {
        _refreshController.loadFailed();
      }
      return;
    }

    final int targetPage = refresh ? 1 : _page + 1;
    final int limit = 20;

    try {
      final query = _getQueryForType(targetPage, limit);
      final rawResponse = await Anilist().fetchQuery(query, null);

      if (rawResponse == null || rawResponse['Page'] == null) {
        throw Exception("Invalid API response");
      }

      final pageData = rawResponse['Page'];
      _hasNextPage = pageData['pageInfo']?['hasNextPage'] ?? false;

      final List<dynamic> rawList = _extractListFromPage(pageData);
      final mapped = rawList.map((e) => _mapItem(e)).toList();

      if (mounted) {
        setState(() {
          if (refresh) {
            _items.clear();
          }
          _items.addAll(mapped);
          _page = targetPage;
          _isLoading = false;
          _isError = false;
          _isOffline = false;
        });
      }

      if (refresh) {
        _writeCache(_items);
        _refreshController.refreshCompleted();
      } else {
        _refreshController.loadComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _isLoading = false;
        });
      }
      if (refresh) {
        _refreshController.refreshFailed();
      } else {
        _refreshController.loadFailed();
      }
    }
  }

  String _getQueryForType(int page, int limit) {
    if (widget.type == "episodes") {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return '''
        query {
          Page(page: $page, perPage: $limit) {
            pageInfo {
              hasNextPage
            }
            airingSchedules(sort: TIME_DESC, airingAt_lesser: $now) {
              episode
              airingAt
              media {
                id
                title {
                  english
                  romaji
                  native
                }
                coverImage {
                  large
                }
                averageScore
              }
            }
          }
        }
      ''';
    } else if (widget.type == "new_anime") {
      return '''
        query {
          Page(page: $page, perPage: $limit) {
            pageInfo {
              hasNextPage
            }
            media(sort: ID_DESC, type: ANIME, isAdult: false) {
              id
              title {
                english
                romaji
                native
              }
              coverImage {
                large
              }
              averageScore
            }
          }
        }
      ''';
    } else {
      return '''
        query {
          Page(page: $page, perPage: $limit) {
            pageInfo {
              hasNextPage
            }
            media(sort: UPDATED_AT_DESC, type: MANGA, isAdult: false) {
              id
              title {
                english
                romaji
                native
              }
              coverImage {
                large
              }
              averageScore
            }
          }
        }
      ''';
    }
  }

  List<dynamic> _extractListFromPage(Map<String, dynamic> pageData) {
    if (widget.type == "episodes") {
      return pageData['airingSchedules'] ?? [];
    } else {
      return pageData['media'] ?? [];
    }
  }

  Map<String, dynamic> _mapItem(Map<String, dynamic> raw) {
    final isEpisode = widget.type == "episodes";
    final media = isEpisode ? (raw['media'] as Map<String, dynamic>? ?? {}) : raw;

    final id = media['id'] as int? ?? 0;
    final titleInfo = media['title'] as Map<String, dynamic>? ?? {};
    final title = titleInfo['english'] ?? titleInfo['romaji'] ?? titleInfo['native'] ?? '';
    final cover = media['coverImage']?['large'] ?? '';
    final rating = media['averageScore'] != null ? (media['averageScore'] as num).toDouble() / 10.0 : null;

    String? subText;
    String? badgeText;

    if (isEpisode) {
      final epNum = raw['episode'] as int? ?? 0;
      badgeText = AppLocalizations.of(context).cbEpisodeNumber(epNum);
      final airingTime = raw['airingAt'] as int? ?? 0;
      subText = _formatRelativeTime(airingTime);
    } else {
      badgeText = AppLocalizations.of(context).badgeNew;
    }

    return {
      'id': id,
      'title': title,
      'cover': cover,
      'rating': rating,
      'badgeText': badgeText,
      'subText': subText,
    };
  }

  String _formatRelativeTime(int timestamp) {
    final now = DateTime.now();
    final airingTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final diff = now.difference(airingTime);

    if (diff.inDays == 1) {
      return AppLocalizations.of(context).labelAiringTimeYesterday;
    } else if (diff.inDays > 1) {
      return AppLocalizations.of(context).labelAiringTimeDaysAgo(diff.inDays);
    } else if (diff.inHours > 0) {
      return AppLocalizations.of(context).labelAiringTimeHoursAgo(diff.inHours);
    } else if (diff.inMinutes > 0) {
      return AppLocalizations.of(context).labelAiringTimeMinutesAgo(diff.inMinutes);
    } else {
      return AppLocalizations.of(context).labelAiringTimeJustNow;
    }
  }

  Future<void> _writeCache(List<dynamic> data) async {
    try {
      final box = await Hive.openBox(HiveBox.misc.boxName);
      await box.put('terbaru_cache_${widget.type}', jsonEncode(data));
    } catch (_) {}
  }

  Future<List<dynamic>?> _readCache() async {
    try {
      final box = await Hive.openBox(HiveBox.misc.boxName);
      final String? cachedStr = box.get('terbaru_cache_${widget.type}');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        return jsonDecode(cachedStr) as List<dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Widget _buildSkeletonList() {
    final isDesktop = Platform.isWindows || Platform.isLinux;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisExtent: isDesktop ? 260 : 220,
        mainAxisSpacing: 15,
      ),
      itemCount: 10,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 50, color: appTheme.textSubColor),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).stateError,
            style: TextStyle(color: appTheme.textMainColor, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _fetchData(refresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: appTheme.accentColor,
              foregroundColor: appTheme.onAccent,
            ),
            child: Text(AppLocalizations.of(context).btnRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 55, color: appTheme.textSubColor),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).stateOffline,
            style: TextStyle(color: appTheme.textMainColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).stateOfflineSub,
            style: TextStyle(color: appTheme.textSubColor, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _fetchData(refresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: appTheme.accentColor,
              foregroundColor: appTheme.onAccent,
            ),
            child: Text(AppLocalizations.of(context).btnRetry),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isManga = widget.type == "new_manga";
    final mangaComingSoon = isManga && AppValues.mangaComingSoon;

    if (_isLoading && _items.isEmpty) {
      return mangaComingSoon
          ? ComingSoonOverlay.manga(context: context, child: _buildSkeletonList())
          : _buildSkeletonList();
    }

    if (_isOffline && _items.isEmpty) {
      return mangaComingSoon
          ? ComingSoonOverlay.manga(context: context, child: _buildOfflineState())
          : _buildOfflineState();
    }

    if (_isError && _items.isEmpty) {
      return mangaComingSoon
          ? ComingSoonOverlay.manga(context: context, child: _buildErrorState())
          : _buildErrorState();
    }

    final isDesktop = Platform.isWindows || Platform.isLinux;

    final content = Stack(
      children: [
        SmartRefresher(
          controller: _refreshController,
          enablePullUp: _hasNextPage,
          onRefresh: () => _fetchData(refresh: true),
          onLoading: () => _fetchData(refresh: false),
          header: WaterDropMaterialHeader(
            backgroundColor: appTheme.backgroundSubColor,
            color: appTheme.accentColor,
          ),
          child: _items.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context).stateEmpty,
                    style: TextStyle(color: appTheme.textSubColor, fontSize: 14),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisExtent: isDesktop ? 260 : 220,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Stack(
                      children: [
                        Cards.animeCard(
                          item['id'] as int,
                          item['title'] as String,
                          item['cover'] as String,
                          rating: item['rating'] as double?,
                          isAnime: !mangaComingSoon,
                          isMobile: !isDesktop,
                          subText: item['subText'] as String?,
                          subIcon: item['subText'] != null ? Icons.access_time_rounded : null,
                        ),
                        if (item['badgeText'] != null)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: appTheme.accentColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item['badgeText'] as String,
                                style: TextStyle(
                                  color: appTheme.onAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
        if (_isOffline && _items.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                AppLocalizations.of(context).stateOfflineCacheAlert,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );

    if (mangaComingSoon) {
      return ComingSoonOverlay.manga(context: context, child: content);
    }

    return content;
  }
}
