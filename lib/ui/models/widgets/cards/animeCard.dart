import 'dart:io';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/commons/enums.dart';
import 'package:kumaanime/core/database/handler/syncHandler.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/ContextMenu.dart';
import 'package:kumaanime/ui/pages/info.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AnimeCard extends StatefulWidget {
  final int id;
  final String title;
  final String imageUrl;
  final bool ongoing;
  final bool shouldNavigate;
  final bool isAnime;
  final bool isMobile;
  final String? subText;
  final double? rating;
  final void Function()? afterNavigation;

  const AnimeCard({
    super.key,
    required this.id,
    required this.title,
    required this.afterNavigation,
    required this.imageUrl,
    this.isAnime = true,
    this.ongoing = false,
    this.rating = null,
    this.shouldNavigate = true,
    this.subText = null,
    this.isMobile = true,
  });

  @override
  State<AnimeCard> createState() => _AnimeCardState();
}

class _AnimeCardState extends State<AnimeCard> {
  bool isFocused = false;
  final double _scale = (currentUserSettings?.cardScale ?? 1.0).clamp(0.85, 1.15).toDouble();
  late final double width = (Platform.isWindows || Platform.isLinux ? 150.0 : 110.0) * _scale;
  late final double height = (Platform.isWindows || Platform.isLinux ? 200.0 : 160.0) * _scale;

  void updateFocus(bool val) {
    return setState(() {
      isFocused = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      width: widget.isMobile ? width : width + 5,
      margin: EdgeInsets.only(left: 5, right: 5),
      child: InkWell(
        onHover: updateFocus,
        onFocusChange: updateFocus,
        splashFactory: NoSplash.splashFactory,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
        onTap: () {
          if (!widget.isAnime) return floatingSnackBar(loc.animeCardMangaNotSupported);
          if (widget.shouldNavigate)
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (context) => Info(
                  id: widget.id,
                ),
              ),
            )
                .then((val) {
              widget.afterNavigation?.call();
            });
        },
        child: ContextMenu(
          menuItems: [
            ContextMenuItem(
              icon: Icons.movie_outlined,
              label: loc.animeCardAddToWatching,
              onClick: () {
                SyncHandler()
                    .mutateAnimeList(id: widget.id, status: MediaStatus.CURRENT)
                    .then((_) => floatingSnackBar(loc.animeCardAddedToWatching));
              },
            ),
            ContextMenuItem(
              icon: Icons.calendar_today_outlined,
              label: loc.animeCardAddToPlanned,
              onClick: () {
                SyncHandler()
                    .mutateAnimeList(id: widget.id, status: MediaStatus.PLANNING)
                    .then((_) => floatingSnackBar(loc.animeCardAddedToPlanned));
              },
            ),
            ContextMenuItem(
              icon: Icons.done,
              label: loc.animeCardAddToCompleted,
              onClick: () {
                SyncHandler()
                    .mutateAnimeList(id: widget.id, status: MediaStatus.COMPLETED)
                    .then((_) => floatingSnackBar(loc.animeCardAddedToCompleted));
              },
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.linear,
                    height: widget.isMobile
                        ? height
                        : isFocused
                            ? height * 1.03
                            : height,
                    width: widget.isMobile
                        ? width
                        : isFocused
                            ? width * 1.03
                            : width,
                    margin: EdgeInsets.only(bottom: 10, top: widget.isMobile ? 0 : 5),
                    decoration: BoxDecoration(
                      border: widget.isMobile || Platform.isWindows || Platform.isLinux
                          ? null
                          : isFocused
                              ? Border.all(
                                  color: appTheme.accentColor,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                  width: 2,
                                )
                              : null,
                      borderRadius: BorderRadius.circular(widget.isMobile
                          ? 20
                          : isFocused
                              ? 5
                              : 10),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fadeInDuration: Duration(milliseconds: 200),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: appTheme.backgroundSubColor,
                        height: height,
                        width: width,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 10,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            bottomRight: Radius.circular(widget.isMobile
                                ? 15
                                : isFocused
                                    ? 4
                                    : 9)),
                        color: appTheme.accentColor,
                      ),
                      width: width / 2,
                      padding: EdgeInsets.only(left: 5, right: 5, top: 2, bottom: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star,
                            color: appTheme.onAccent,
                            size: 13,
                          ),
                          Text(
                            " ${widget.rating ?? '??'}",
                            style: TextStyle(
                              fontSize: 14,
                              color: appTheme.onAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isFocused ? appTheme.accentColor : appTheme.textMainColor),
              ),
              if (widget.subText != null)
                Text(
                  widget.subText!,
                  style: TextStyle(color: appTheme.textSubColor),
                )
            ],
          ),
        ),
      ),
    );
  }
}
