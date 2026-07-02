import 'dart:io';

import 'package:kumaanime/core/anime/providers/subIndoTypes.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SubIndoCard extends StatelessWidget {
  final SubIndoAnime anime;
  final void Function() onTap;

  const SubIndoCard({
    super.key,
    required this.anime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = Platform.isWindows || Platform.isLinux ? 150.0 : 110.0;
    final height = Platform.isWindows || Platform.isLinux ? 200.0 : 160.0;
    final subText = anime.episodes != null && anime.episodes!.isNotEmpty
        ? "${anime.episodes} ${AppLocalizations.of(context).subIndoEpisodes}"
        : (anime.status ?? anime.releaseDay);

    return Container(
      width: width,
      margin: const EdgeInsets.only(left: 5, right: 5),
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: height,
                  width: width,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.hardEdge,
                  child: CachedNetworkImage(
                    imageUrl: anime.poster,
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
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: appTheme.accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomRight: Radius.circular(15),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).subIndo,
                      style: TextStyle(
                        fontSize: 12,
                        color: appTheme.onAccent,
                        fontFamily: "NotoSans",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (anime.score != null && anime.score!.isNotEmpty)
                  Positioned(
                    right: 0,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.only(left: 5, right: 5, top: 2, bottom: 2),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                        color: appTheme.accentColor,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: appTheme.onAccent, size: 13),
                          Text(
                            " ${anime.score}",
                            style: TextStyle(
                              fontSize: 14,
                              color: appTheme.onAccent,
                              fontFamily: "NotoSans",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              anime.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: "NotoSans",
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: appTheme.textMainColor,
              ),
            ),
            if (subText != null && subText.isNotEmpty)
              Text(
                subText,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: "NunitoSans", color: appTheme.textSubColor),
              ),
          ],
        ),
      ),
    );
  }
}
