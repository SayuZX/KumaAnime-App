import 'package:kumaanime/core/anime/downloader/downloadManager.dart';
import 'package:kumaanime/core/data/watching.dart';
import 'package:kumaanime/ui/models/bottomSheets/commentSection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/commons/enums.dart';
import 'package:kumaanime/core/database/types.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/bottomSheets/mediaListStatus.dart';
import 'package:kumaanime/ui/models/bottomSheets/serverSelectionSheet.dart';
import 'package:kumaanime/ui/models/providers/infoProvider.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/cards.dart';
import 'package:kumaanime/ui/models/widgets/loader.dart';
import 'package:kumaanime/ui/pages/info.dart';

class InfoMobile extends StatefulWidget {
  const InfoMobile({super.key});

  @override
  State<InfoMobile> createState() => _InfoMobileState();
}

class _InfoMobileState extends State<InfoMobile> {
  late InfoProvider provider;

  bool infoPage = true;
  bool _synopsisExpanded = false;

  FocusNode _watchInfoButtonFocusNode = FocusNode();
  final useNativeTitle = currentUserSettings?.nativeTitle ?? false;

  // just a small helper function to get the title based on preference!
  String getTitle(Map<String, String?> titles) {
    final normalTitle = titles['english'] ?? titles['romaji'] ?? '';
    final customizedTitle =
        useNativeTitle ? titles['native'] ?? normalTitle : normalTitle;
    return customizedTitle;
  }

  @override
  Widget build(BuildContext context) {
    provider = context.watch<InfoProvider>();
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: provider.infoLoadError
          ? Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'lib/assets/images/broken_heart.png',
                    scale: 7.5,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 15, left: 30, right: 30, bottom: 15),
                    child: Text(
                      loc.imError,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appTheme.accentColor,
                      ),
                      child: Text(
                        loc.imGoBack,
                        style: TextStyle(
                            color: appTheme.backgroundColor,
                            fontWeight: FontWeight.bold),
                      )),
                ],
              ),
            )
          : provider.dataLoaded
              ? CustomScrollView(
                  slivers: [
                    SliverList.list(
                      children: [
                        _stack(),
                        _headerBlock(context),
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 200),
                          child: infoPage
                              ? _infoItems(context)
                              : _watchItems(context),
                        ),
                      ],
                    ),
                  ],
                )
              : Center(
                  child: KumaAnimeLoading(
                    color: appTheme.accentColor,
                  ),
                ),
    );
  }

  Widget _headerBlock(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final data = provider.data;
    final native = data.title['native'];
    final showNative =
        native != null && native.isNotEmpty && native != getTitle(data.title);
    return Padding(
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).padding.left + 20,
        right: MediaQuery.of(context).padding.right + 20,
        top: 6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTitle(data.title),
            style: TextStyle(
              color: appTheme.textMainColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
          if (showNative)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                native,
                style: TextStyle(color: appTheme.textSubColor, fontSize: 13),
              ),
            ),
          const SizedBox(height: 12),
          _metaRow(),
          const SizedBox(height: 14),
          if (data.genres.isNotEmpty) _genreChipsRow(),
          const SizedBox(height: 18),
          _actionRow(context),
          if ((data.synopsis ?? '').isNotEmpty) ...[
            const SizedBox(height: 24),
            _sectionHeading(loc.imSynopsis),
            const SizedBox(height: 8),
            _synopsisBlock(data.synopsis!),
          ],
        ],
      ),
    );
  }

  Widget _metaRow() {
    final loc = AppLocalizations.of(context);
    final data = provider.data;
    final items = <Widget>[];
    void add(IconData icon, String? value, {Color? iconColor}) {
      if (value == null || value.trim().isEmpty || value == 'null') return;
      items.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor ?? appTheme.textSubColor),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(color: appTheme.textSubColor, fontSize: 13)),
        ],
      ));
    }

    final dur = data.duration.toString();
    add(Icons.star_rounded, data.rating != null ? "${data.rating}" : null,
        iconColor: const Color(0xFFF5C518));
    add(Icons.live_tv_rounded, data.type);
    add(
        Icons.podcasts_rounded,
        data.status != null
            ? _capitalize(data.status!.replaceAll('_', ' '))
            : null);
    add(Icons.timer_outlined,
        (dur.isEmpty || dur == 'null') ? null : loc.imDurationMinutes(dur));
    return Wrap(spacing: 16, runSpacing: 8, children: items);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : "${s[0].toUpperCase()}${s.substring(1).toLowerCase()}";

  Widget _genreChipsRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: provider.data.genres
          .map((g) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: appTheme.backgroundSubColor,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(g,
                    style:
                        TextStyle(color: appTheme.textMainColor, fontSize: 12)),
              ))
          .toList(),
    );
  }

  Widget _actionRow(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            focusNode: _watchInfoButtonFocusNode,
            onFocusChange: (val) => setState(() {}),
            onPressed: () => setState(() => infoPage = !infoPage),
            style: ElevatedButton.styleFrom(
              backgroundColor: appTheme.accentColor,
              foregroundColor: appTheme.onAccent,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(infoPage ? Icons.play_arrow_rounded : Icons.info_rounded,
                size: 24),
            label: Text(
              infoPage ? loc.imWatchNow : loc.imInfo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (provider.loggedIn) ...[
          const SizedBox(width: 10),
          _outlineCircle(
            InfoProvider.getTrackerIcon(provider.mediaListStatus),
            () => showModalBottomSheet(
              context: context,
              backgroundColor: appTheme.backgroundColor,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (context) =>
                  MediaListStatusBottomSheet(provider: provider),
            ),
          ),
        ] else if (provider.started) ...[
          const SizedBox(width: 10),
          _outlineCircle(
              Icons.delete_outline_rounded, () => _confirmRemove(context)),
        ],
      ],
    );
  }

  Widget _outlineCircle(IconData icon, VoidCallback onTap) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: appTheme.accentColor),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: appTheme.accentColor, size: 26),
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.imNo)),
          TextButton(
            onPressed: () async {
              await removeWatching(provider.id);
              provider.clearLastWatchDuration();
              await provider.getWatched(refreshLastWatchDuration: true);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
                backgroundColor: appTheme.accentColor,
                foregroundColor: appTheme.onAccent),
            child: Text(loc.imYes),
          ),
        ],
        content: Padding(
          padding: const EdgeInsets.all(10),
          child: Text.rich(
            TextSpan(
                text: loc.imRemovePrefix,
                style: TextStyle(fontSize: 15),
                children: [
                  TextSpan(
                      text: getTitle(provider.data.title),
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  TextSpan(
                      text: loc.imRemoveSuffix, style: TextStyle(fontSize: 15)),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _synopsisBlock(String synopsis) {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: _synopsisExpanded ? double.infinity : 90),
            child: Text(
              synopsis,
              overflow:
                  _synopsisExpanded ? TextOverflow.visible : TextOverflow.fade,
              style: TextStyle(
                  color: appTheme.textSubColor, fontSize: 14, height: 1.5),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _synopsisExpanded = !_synopsisExpanded),
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _synopsisExpanded ? loc.imShowLess : loc.imShowMore,
              style: TextStyle(
                  color: appTheme.accentColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeading(String title) {
    return Text(
      title,
      style: TextStyle(
          color: appTheme.textMainColor,
          fontSize: 20,
          fontWeight: FontWeight.bold),
    );
  }

  Column _watchItems(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(
              top: 25,
              left: 20 + MediaQuery.of(context).padding.left,
              right: 20 + MediaQuery.of(context).padding.right),
          padding: EdgeInsets.only(top: 15, bottom: 20),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: appTheme.backgroundSubColor),
          child: Column(
            children: [
              Container(
                height: 45,
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.imEpisodes,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: appTheme.textMainColor,
                      ),
                    ),
                    if (provider.foundName != null &&
                        provider.epLinks.isNotEmpty)
                      _dubToggle(),
                  ],
                ),
              ),
              provider.epSearcherror
                  ? Container(
                      width: 350,
                      height: 120,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'lib/assets/images/broken_heart.png',
                              scale: 7.5,
                            ),
                            Text(
                              loc.imNoResults,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : (provider.foundName == null || provider.epLinks.isEmpty)
                      ? Container(
                          width: 350,
                          height: 100,
                          child: Center(
                            child: KumaAnimeLoading(
                                color: appTheme.accentColor, size: 40),
                          ),
                        )
                      : _episodeChipGrid(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dubToggle() {
    final loc = AppLocalizations.of(context);
    return InkWell(
      onTap: () => provider.preferDubs = !provider.preferDubs,
      child: Container(
        margin: EdgeInsets.all(2),
        width: 40,
        height: 25,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: appTheme.textMainColor),
        child: Text(provider.preferDubs ? loc.imDub : loc.imSub,
            style: TextStyle(
                color: appTheme.backgroundColor, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _episodeChipGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(provider.epLinks.length, (index) {
          final number = index + 1;
          final isWatched = number <= provider.watched;
          final isLast = number == provider.watched;
          final bg = isLast
              ? appTheme.accentColor
              : (isWatched
                  ? appTheme.accentColor.withValues(alpha: 0.16)
                  : appTheme.backgroundColor);
          final fg = isLast
              ? appTheme.onAccent
              : (isWatched ? appTheme.accentColor : appTheme.textMainColor);
          return GestureDetector(
            onTap: () {
              showModalBottomSheet(
                showDragHandle: true,
                context: context,
                isScrollControlled: true,
                backgroundColor: appTheme.modalSheetBackgroundColor,
                builder: (context) {
                  return ServerSelectionBottomSheet(
                    provider: provider,
                    episodeIndex: index,
                    type: ServerSheetType.watch,
                  );
                },
              ).then((val) {
                if (val == true)
                  provider.refreshListStatus("CURRENT", provider.watched);
              });
            },
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: (isWatched && !isLast)
                    ? Border.all(
                        color: appTheme.accentColor.withValues(alpha: 0.55),
                        width: 1.5)
                    : null,
              ),
              child: Text(
                "$number",
                style: TextStyle(
                    color: fg, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          );
        }),
      ),
    );
  }

  Container _infoItems(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 50),
            child: Column(
              children: [
                _buildInfoItems(
                  _infoLeft(loc.imType),
                  _infoRight(provider.data.type.toLowerCase()),
                ),
                _buildInfoItems(
                  _infoLeft(loc.imStatus),
                  _infoRight('${provider.data.status ?? '??'}'
                      .toLowerCase()
                      .replaceAll("_", ' ')),
                ),
                _buildInfoItems(
                  _infoLeft(loc.imRating),
                  _infoRight('${provider.data.rating ?? '??'}/10'),
                ),
                _buildInfoItems(
                  _infoLeft(loc.imEpisodes),
                  _infoRight('${provider.data.episodes ?? '??'}'),
                ),
                _buildInfoItems(
                  _infoLeft(loc.imDuration),
                  _infoRight('${provider.data.duration}'),
                ),
                _buildInfoItems(_infoLeft(loc.imStartDate),
                    _infoRight("${provider.data.aired['start']}")),
                _buildInfoItems(
                  _infoLeft(loc.imStudios),
                  _infoRight(provider.data.studios.isEmpty
                      ? '??'
                      : provider.data.studios[0] ?? '??'),
                ),
              ],
            ),
          ),
          if (provider.data.tags != null)
            Container(
              margin: EdgeInsets.only(top: 30),
              padding: EdgeInsets.only(left: 15, right: 15),
              child: Column(
                children: [
                  _categoryTitle(loc.imTags),
                  SizedBox(
                    height: 45,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.data.tags!.length,
                      itemBuilder: (context, index) {
                        return Container(
                          alignment: Alignment.center,
                          margin: EdgeInsets.all(5),
                          padding: EdgeInsets.only(left: 15, right: 15),
                          decoration: BoxDecoration(
                              color: appTheme.backgroundSubColor,
                              borderRadius: BorderRadius.circular(5)),
                          child: Text(
                            provider.data.tags![index],
                            style: TextStyle(
                              color: appTheme.textMainColor,
                              fontSize: 15,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: EdgeInsets.only(top: 30),
            child: Column(
              children: [
                _categoryTitle(loc.imCharacters),
                SizedBox(
                  height: 260,
                  child: ListView.builder(
                    itemCount: provider.data.characters.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final character = provider.data.characters[index];
                      return Container(
                        width: 130,
                        child: Cards.characterCard(
                          character['name'],
                          character['role'],
                          character['image'],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 20),
            child: Column(
              children: [
                _categoryTitle(loc.imRelated),
                _buildRecAndRel(provider.data.related, false, context),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 20),
            child: Column(
              children: [
                _categoryTitle(loc.imRecommended),
                _buildRecAndRel(provider.data.recommended, true, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container _buildInfoItems(Widget itemLeft, Widget itemRight) {
    return Container(
      padding: EdgeInsets.only(left: 15, right: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          itemLeft,
          Container(width: 150, child: itemRight),
        ],
      ),
    );
  }

  SizedBox _buildRecAndRel(List<DatabaseRelatedRecommendation> data,
      bool recommended, BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (data.isEmpty)
      return SizedBox(
        height: 240,
        child: Center(
          child: Text(
            loc.imNothingHere,
            style: const TextStyle(
              fontSize: 18,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        ),
      );
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          return GestureDetector(
            onTap: () {
              if (item.type.toLowerCase() != "anime") {
                return floatingSnackBar(loc.imMangaNotSupported);
              }

              //only navigate if the list is being built by characterCard method.
              //since the animeCard has inbuilt navigation
              if (!recommended)
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Info(
                      id: item.id,
                    ),
                  ),
                );
            },
            child: Container(
                width: 130,
                child: recommended
                    ? Cards.animeCard(item.id, getTitle(item.title), item.cover,
                        rating: item.rating)
                    : Cards.characterCard(
                        getTitle(item.title),
                        recommended ? item.type : item.relationType!,
                        item.cover,
                      )),
          );
        },
      ),
    );
  }

  Padding _categoryTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: appTheme.textMainColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Padding _infoLeft(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
            color: const Color.fromARGB(255, 141, 141, 141),
            fontSize: 17,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Padding _infoRight(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
          color: appTheme.textMainColor,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.end,
      ),
    );
  }

  Stack _stack() {
    final loc = AppLocalizations.of(context);
    return Stack(
      children: [
        GestureDetector(
          onLongPress: () {
            final img = provider.data.banner != null
                ? provider.data.banner!
                : provider.data.cover;
            showModalBottomSheet(
              context: context,
              showDragHandle: true,
              backgroundColor: appTheme.modalSheetBackgroundColor,
              builder: (BuildContext context) {
                return SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          loc.imBannerTitle(provider.data.title['english'] ??
                              provider.data.title['romaji'] ??
                              ''),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        Image.network(
                          img,
                          height: 250,
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 20, bottom: 10),
                          alignment: Alignment.center,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await DownloadManager().addDownloadTask(
                                    img,
                                    (provider.data.title['english'] ??
                                            provider.data.title['romaji'] ??
                                            "anime") +
                                        "_Banner");
                                floatingSnackBar(loc.imBannerSaved);
                                Navigator.of(context).pop();
                              } catch (err) {
                                floatingSnackBar(loc.imBannerSaveError);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              fixedSize: Size(150, 75),
                              backgroundColor: appTheme.accentColor,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: appTheme.accentColor),
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              loc.imSave,
                              style: TextStyle(
                                  color: appTheme.onAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.transparent, appTheme.backgroundColor],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.0, 0.55]).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: Container(
              height: 300,
              width: double.infinity,
              child: Image.network(
                provider.data.banner != null
                    ? provider.data.banner!
                    : provider.data.cover,
                fit: BoxFit.cover,
                opacity: AlwaysStoppedAnimation(0.8),
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: Duration(milliseconds: 300),
                    child: child,
                    curve: Curves.easeIn,
                  );
                },
              ),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                clipBehavior: Clip.hardEdge,
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
              Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                clipBehavior: Clip.hardEdge,
                child: IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                        context: context,
                        useSafeArea: true,
                        builder: (context) {
                          return Commentsection(
                              mediaId: provider.id, userId: storedUserData?.id);
                        });
                  },
                  icon: const Icon(Icons.comment_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
