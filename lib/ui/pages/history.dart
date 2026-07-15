import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/watching.dart';
import 'package:kumaanime/core/database/anilist/types.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/widgets/cards.dart';
import 'package:kumaanime/ui/models/widgets/loader.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<UserAnimeListItem> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await getWatchedList(userName: storedUserData?.name);
      if (mounted) {
        setState(() {
          _history = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom + 100;

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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      loc.libHistory,
                      style: TextStyle(
                        color: appTheme.textMainColor,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_history.isEmpty)
                    _emptyState(loc)
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: (Platform.isAndroid ? 140.0 : 180.0) *
                            (currentUserSettings?.cardScale ?? 1.0).clamp(0.85, 1.15),
                        mainAxisExtent: (Platform.isAndroid ? 220.0 : 260.0) *
                            (currentUserSettings?.cardScale ?? 1.0).clamp(0.85, 1.15),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        final title = item.title['title'] ??
                            item.title['english'] ??
                            item.title['romaji'] ??
                            '';
                        return Center(
                          child: Cards.animeCard(
                            item.id,
                            title,
                            item.coverImage,
                            rating: item.rating,
                            isMobile: true,
                          ),
                        );
                      },
                    ),
                ],
              ),
      ),
    );
  }

  Widget _emptyState(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Image.asset('lib/assets/images/ghost.png', height: 100),
          const SizedBox(height: 16),
          Text(
            loc.subIndoEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: appTheme.textSubColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
