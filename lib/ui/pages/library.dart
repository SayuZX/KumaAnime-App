import 'package:kumaanime/core/anime/downloader/downloadManager.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/commons/enums.dart';
import 'package:kumaanime/core/data/downloadHistory.dart';
import 'package:kumaanime/core/data/resumeSession.dart';
import 'package:kumaanime/core/data/watching.dart';
import 'package:kumaanime/core/database/anilist/queries.dart';
import 'package:kumaanime/core/database/anilist/types.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/widgets/cards.dart';
import 'package:kumaanime/ui/models/widgets/loader.dart';
import 'package:kumaanime/ui/models/widgets/miniResumePlayer.dart';
import 'package:kumaanime/ui/pages/downloads.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class LibraryPage extends StatefulWidget {
  final bool isTab;
  const LibraryPage({super.key, this.isTab = false});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<UserAnimeListItem> _watching = [];
  List<UserAnimeListItem> _watchlist = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final watching = await getWatchedList(userName: storedUserData?.name);
      List<UserAnimeListItem> planning = [];
      if (storedUserData != null) {
        try {
          final lists =
              await AnilistQueries().getUserAnimeList(storedUserData!.name, status: MediaStatus.PLANNING);
          if (lists.isNotEmpty) planning = lists.first.list.reversed.toList();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _watching = watching;
        _watchlist = planning;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isDark => currentUserSettings?.darkMode ?? true;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom + 170;

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: RefreshIndicator(
        color: appTheme.accentColor,
        onRefresh: _load,
        child: _loading
            ? Center(child: KumaAnimeLoading(color: appTheme.accentColor, size: 40))
            : ListView(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: bottomPad,
                ),
                children: [
                  if (!widget.isTab) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        loc.navLibrary,
                        style: TextStyle(color: appTheme.textMainColor, fontSize: 34, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _resumeSection(loc),
                  if (_watching.isNotEmpty) ...[
                    _sectionHeader(Icons.play_circle_outline_rounded, loc.libContinueWatching),
                    _animeRow(_watching),
                    _sectionHeader(Icons.local_fire_department_rounded, loc.libMostWatched),
                    _animeRow(_mostWatched()),
                  ],
                  _downloadsSection(loc),
                  if (_watching.isNotEmpty) ...[
                    _sectionHeader(Icons.history_rounded, loc.libHistory),
                    _animeRow(_watching),
                  ],
                  if (_watchlist.isNotEmpty) ...[
                    _sectionHeader(Icons.bookmark_outline_rounded, loc.libWatchlist),
                    _animeRow(_watchlist),
                  ],
                  if (_watching.isEmpty && _watchlist.isEmpty) _emptyState(loc),
                ],
              ),
      ),
    );
  }

  List<UserAnimeListItem> _mostWatched() {
    final sorted = List<UserAnimeListItem>.from(_watching)
      ..sort((a, b) => (b.watchProgress ?? 0).compareTo(a.watchProgress ?? 0));
    return sorted.take(10).toList();
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 22, bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: appTheme.accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: appTheme.accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(color: appTheme.textMainColor, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _animeRow(List<UserAnimeListItem> items) {
    return SizedBox(
      height: 235,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final title = item.title['title'] ?? item.title['english'] ?? item.title['romaji'] ?? '';
          return Cards.animeCard(
            item.id,
            title,
            item.coverImage,
            rating: item.rating,
            isMobile: true,
          );
        },
      ),
    );
  }

  Widget _resumeSection(AppLocalizations loc) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: ResumeSession.notifier,
      builder: (context, session, _) {
        if (session == null) return const SizedBox.shrink();
        final progress = ((session['progress'] ?? 0.0) as num).toDouble().clamp(0.0, 1.0);
        final cover = session['cover'] as String?;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: InkWell(
            onTap: () => MiniResumePlayer.resume(context, session),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF1E1F22) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  cover == null || cover.isEmpty
                      ? Container(width: 92, height: 118, color: appTheme.backgroundSubColor)
                      : CachedNetworkImage(imageUrl: cover, width: 92, height: 118, fit: BoxFit.cover),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            session['title'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: appTheme.textMainColor, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${loc.episode} ${session['episodeNumber'] ?? '?'}",
                            style: TextStyle(color: appTheme.textSubColor, fontSize: 12.5),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: appTheme.textSubColor.withValues(alpha: 0.25),
                              valueColor: AlwaysStoppedAnimation(appTheme.accentColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: appTheme.accentColor, shape: BoxShape.circle),
                      child: Icon(Icons.play_arrow_rounded, color: appTheme.onAccent, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _downloadsSection(AppLocalizations loc) {
    return ValueListenableBuilder(
      valueListenable: DownloadHistory.listenable,
      builder: (context, box, _) {
        final completed = DownloadHistory.getDownloadHistory();
        return ValueListenableBuilder<int>(
          valueListenable: DownloadManager.downloadsCount,
          builder: (context, activeCount, _) {
            if (completed.isEmpty && activeCount == 0) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 22, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: appTheme.accentColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.download_rounded, color: appTheme.accentColor, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            loc.libDownloads,
                            style:
                                TextStyle(color: appTheme.textMainColor, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          if (activeCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: appTheme.accentColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "$activeCount",
                                  style: TextStyle(
                                      color: appTheme.onAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => DownloadsPage())),
                        child: Text(loc.libManage, style: TextStyle(color: appTheme.accentColor)),
                      ),
                    ],
                  ),
                ),
                ...completed.take(4).map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _isDark ? const Color(0xFF1E1F22) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.movie_rounded, color: appTheme.accentColor, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: appTheme.textMainColor, fontSize: 13.5),
                                ),
                              ),
                              Text(
                                _formatSize(item.size),
                                style: TextStyle(color: appTheme.textSubColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(0)} KB";
    if (bytes < 1024 * 1024 * 1024) return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  }

  Widget _emptyState(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Image.asset('lib/assets/images/ghost.png', height: 100),
          const SizedBox(height: 16),
          Text(
            loc.libEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: appTheme.textSubColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
