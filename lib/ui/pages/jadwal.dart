import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/commons/enums/hiveEnums.dart';
import 'package:kumaanime/core/database/anilist/anilist.dart';
import 'package:kumaanime/ui/models/widgets/cards.dart';
import 'package:kumaanime/ui/models/widgets/header.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<List<dynamic>> _groupedItems = List.generate(7, (_) => []);
  bool _isLoading = true;
  bool _isError = false;
  bool _isOffline = false;
  bool _isFetching = false;


  @override
  void initState() {
    super.initState();
    final todayIndex = DateTime.now().weekday - 1;
    _tabController = TabController(length: 7, vsync: this, initialIndex: todayIndex);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    final cached = await _readCache();
    if (cached != null && cached.length == 7) {
      if (mounted) {
        setState(() {
          for (int i = 0; i < 7; i++) {
            _groupedItems[i] = cached[i];
          }
          _isLoading = false;
        });
      }
    }
    _fetchWeeklySchedule();
  }

  Future<void> _fetchWeeklySchedule() async {
    if (_isFetching) return;
    _isFetching = true;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _isError = false;
        _isOffline = false;
      });
    }

    final online = await _checkConnection();
    if (!online) {
      _isFetching = false;
      if (mounted) {
        setState(() {
          _isOffline = true;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final now = DateTime.now();
      final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      final weekStart = monday.millisecondsSinceEpoch ~/ 1000;
      final weekEnd = monday.add(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000;

      final query = '''
        query {
          Page(perPage: 100) {
            airingSchedules(airingAt_greater: $weekStart, airingAt_lesser: $weekEnd, sort: TIME) {
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

      if (kDebugMode) {
        print("[DEBUG] Airing Schedule Request URL: https://graphql.anilist.co");
        print("[DEBUG] Parameters: weekStart=$weekStart, weekEnd=$weekEnd");
        print("[DEBUG] Query:\n$query");
      }

      final rawResponse = await Anilist().fetchQuery(query, null);
      if (rawResponse == null || rawResponse['Page'] == null) {
        throw Exception("Invalid schedule response");
      }

      final List<dynamic> schedules = rawResponse['Page']['airingSchedules'] ?? [];
      final List<List<dynamic>> tempGrouped = List.generate(7, (_) => []);

      for (final rawItem in schedules) {
        final airingAt = rawItem['airingAt'] as int? ?? 0;
        final airingTime = DateTime.fromMillisecondsSinceEpoch(airingAt * 1000);
        final dayIndex = airingTime.weekday - 1;

        final media = rawItem['media'] as Map<String, dynamic>? ?? {};
        final id = media['id'] as int? ?? 0;
        final titleInfo = media['title'] as Map<String, dynamic>? ?? {};
        final title = titleInfo['english'] ?? titleInfo['romaji'] ?? titleInfo['native'] ?? '';
        final cover = media['coverImage']?['large'] ?? '';
        final rating = media['averageScore'] != null ? (media['averageScore'] as num).toDouble() / 10.0 : null;
        final epNum = rawItem['episode'] as int? ?? 1;

        final timeFormatted = "${airingTime.hour.toString().padLeft(2, '0')}:${airingTime.minute.toString().padLeft(2, '0')}";

        tempGrouped[dayIndex].add({
          'id': id,
          'title': title,
          'cover': cover,
          'rating': rating,
          'episode': epNum,
          'time': timeFormatted,
        });
      }

      if (kDebugMode) {
        print("[DEBUG] HTTP Status: 200 (Success)");
        print("[DEBUG] Parsing result: ${schedules.length} items parsed.");
      }

      if (mounted) {
        setState(() {
          for (int i = 0; i < 7; i++) {
            _groupedItems[i] = tempGrouped[i];
          }
          _isLoading = false;
          _isError = false;
          _isOffline = false;
        });
      }

      _writeCache(tempGrouped);
    } catch (e) {
      if (kDebugMode) {
        print("[DEBUG] Error fetching schedule: ${e.toString()}");
      }
      if (mounted) {
        setState(() {
          if (_groupedItems.every((list) => list.isEmpty)) {
            _isError = true;
          }
          _isLoading = false;
        });
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _writeCache(List<List<dynamic>> data) async {
    try {
      final box = await Hive.openBox(HiveBox.misc.boxName);
      await box.put('jadwal_cache', jsonEncode(data));
    } catch (_) {}
  }

  Future<List<List<dynamic>>?> _readCache() async {
    try {
      final box = await Hive.openBox(HiveBox.misc.boxName);
      final String? cachedStr = box.get('jadwal_cache');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final decoded = jsonDecode(cachedStr) as List<dynamic>;
        return decoded.map((list) => list as List<dynamic>).toList();
      }
    } catch (_) {}
    return null;
  }

  Widget _buildSkeletonGrid() {
    final isDesktop = Platform.isWindows || Platform.isLinux;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisExtent: isDesktop ? 260 : 220,
        mainAxisSpacing: 15,
      ),
      itemCount: 8,
      itemBuilder: (context, index) => Container(
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
            AppLocalizations.of(context).stateErrorJadwal,
            style: TextStyle(color: appTheme.textMainColor, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchWeeklySchedule();
            },
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
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchWeeklySchedule();
            },
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

  Widget _buildDayGrid(int dayIndex) {
    final list = _groupedItems[dayIndex];
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "📅",
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).stateEmptyJadwal,
              style: TextStyle(color: appTheme.textSubColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final isDesktop = Platform.isWindows || Platform.isLinux;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisExtent: isDesktop ? 260 : 220,
        mainAxisSpacing: 15,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Stack(
          children: [
            Cards.animeCard(
              item['id'] as int,
              item['title'] as String,
              item['cover'] as String,
              rating: item['rating'] as double?,
              subText: AppLocalizations.of(context).labelAiringTime(item['time'] as String),
              subIcon: Icons.access_time_filled,
              isAnime: true,
              isMobile: !isDesktop,
            ),
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
                  AppLocalizations.of(context).cbEpisodeNumber(item['episode'] as int),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = [
      AppLocalizations.of(context).daysSenin,
      AppLocalizations.of(context).daysSelasa,
      AppLocalizations.of(context).daysRabu,
      AppLocalizations.of(context).daysKamis,
      AppLocalizations.of(context).daysJumat,
      AppLocalizations.of(context).daysSabtu,
      AppLocalizations.of(context).daysMinggu,
    ];

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchWeeklySchedule,
          color: appTheme.accentColor,
          backgroundColor: appTheme.backgroundSubColor,
          child: Column(
            children: [
              buildHeader(AppLocalizations.of(context).tabJadwal, context),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: appTheme.accentColor,
                labelColor: appTheme.accentColor,
                unselectedLabelColor: appTheme.textSubColor,
                tabs: days.map((day) => Tab(text: day)).toList(),
              ),
              Expanded(
                child: _isLoading
                    ? _buildSkeletonGrid()
                    : _isOffline && _groupedItems.every((list) => list.isEmpty)
                        ? _buildOfflineState()
                        : _isError && _groupedItems.every((list) => list.isEmpty)
                            ? _buildErrorState()
                            : Stack(
                                children: [
                                  TabBarView(
                                    controller: _tabController,
                                    children: List.generate(7, (idx) => _buildDayGrid(idx)),
                                  ),
                                  if (_isOffline)
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
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
