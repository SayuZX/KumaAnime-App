import 'dart:io';
import 'package:kumaanime/core/anime/providers/subIndoTypes.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SubIndoCard extends StatefulWidget {
  final SubIndoAnime anime;
  final void Function() onTap;
  final String? badge;
  final bool isSubIndo;

  const SubIndoCard({
    super.key,
    required this.anime,
    required this.onTap,
    this.badge,
    this.isSubIndo = true,
  });

  @override
  State<SubIndoCard> createState() => _SubIndoCardState();
}

class _SubIndoCardState extends State<SubIndoCard> {
  bool isFocused = false;

  void updateFocus(bool val) {
    if (mounted) setState(() => isFocused = val);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final subText = widget.anime.episodes != null && widget.anime.episodes!.isNotEmpty
        ? "${widget.anime.episodes} ${loc.subIndoEpisodes}"
        : (widget.anime.status ?? widget.anime.releaseDay);

    final _scale = (currentUserSettings?.cardScale ?? 1.0).clamp(0.85, 1.15).toDouble();
    final double width = (Platform.isWindows || Platform.isLinux ? 150.0 : 110.0) * _scale;
    final double height = (Platform.isWindows || Platform.isLinux ? 200.0 : 160.0) * _scale;

    // Parse rating as double if available
    double? ratingVal;
    if (widget.anime.score != null && widget.anime.score!.trim().isNotEmpty) {
      ratingVal = double.tryParse(widget.anime.score!);
    }

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: InkWell(
        onHover: updateFocus,
        onFocusChange: updateFocus,
        splashFactory: NoSplash.splashFactory,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.linear,
                  height: isFocused ? height * 1.03 : height,
                  width: isFocused ? width * 1.03 : width,
                  margin: EdgeInsets.only(bottom: 10, top: isFocused ? 0 : 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Platform.isWindows || Platform.isLinux
                        ? null
                        : isFocused
                            ? Border.all(
                                color: appTheme.accentColor,
                                strokeAlign: BorderSide.strokeAlignOutside,
                                width: 2,
                              )
                            : null,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: CachedNetworkImage(
                    imageUrl: widget.anime.poster,
                    fadeInDuration: const Duration(milliseconds: 200),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: appTheme.backgroundSubColor,
                      height: height,
                      width: width,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: appTheme.backgroundSubColor,
                      height: height,
                      width: width,
                      child: Icon(Icons.broken_image_rounded, color: appTheme.textSubColor),
                    ),
                  ),
                ),
                // Top Badges
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    children: [
                      // Sub Indo / Sub Eng Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: appTheme.accentColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.isSubIndo ? "Sub Indo" : "Sub Eng",
                          style: TextStyle(
                            color: appTheme.onAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.badge != null && widget.badge!.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Bottom Labels (subText & rating)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (subText != null && subText.isNotEmpty)
                        Flexible(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                              ),
                              color: Colors.black.withValues(alpha: 0.65),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.movie_outlined,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    subText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const SizedBox(),
                      if (ratingVal != null)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              bottomRight: Radius.circular(15),
                            ),
                            color: appTheme.accentColor,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                                " ${ratingVal.toStringAsFixed(1)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: appTheme.onAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              widget.anime.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isFocused ? appTheme.accentColor : appTheme.textMainColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
