import 'package:kumaanime/core/anime/providers/subIndoTypes.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SubIndoCard extends StatelessWidget {
  final SubIndoAnime anime;
  final void Function() onTap;
  final String? badge;

  const SubIndoCard({
    super.key,
    required this.anime,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final subText = anime.episodes != null && anime.episodes!.isNotEmpty
        ? "${anime.episodes} ${AppLocalizations.of(context).subIndoEpisodes}"
        : (anime.status ?? anime.releaseDay);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: anime.poster,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (context, url) => Container(color: appTheme.backgroundSubColor),
                    errorWidget: (context, url, error) => Container(
                      color: appTheme.backgroundSubColor,
                      child: Icon(Icons.broken_image_rounded, color: appTheme.textSubColor),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: appTheme.accentColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (badge ?? AppLocalizations.of(context).subIndo).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.5,
                          color: appTheme.onAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (anime.score != null && anime.score!.trim().isNotEmpty)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF5C518), size: 13),
                            const SizedBox(width: 2),
                            Text(
                              anime.score!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            anime.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: appTheme.textMainColor,
            ),
          ),
          if (subText != null && subText.isNotEmpty)
            Text(
              subText,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(fontSize: 11, color: appTheme.textSubColor),
            ),
        ],
      ),
    );
  }
}
