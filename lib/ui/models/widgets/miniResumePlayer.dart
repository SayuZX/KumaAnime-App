import 'dart:io';
import 'dart:ui';

import 'package:kumaanime/core/anime/providers/types.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/resumeSession.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/playerControllers/betterPlayer.dart';
import 'package:kumaanime/ui/models/playerControllers/fvp.dart';
import 'package:kumaanime/ui/models/providers/playerDataProvider.dart';
import 'package:kumaanime/ui/models/providers/playerProvider.dart';
import 'package:kumaanime/ui/pages/watch.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Floating continue-watching bar above the navbar, resumes the last session.
class MiniResumePlayer extends StatelessWidget {
  final double bottomOffset;

  const MiniResumePlayer({super.key, required this.bottomOffset});

  bool get _isDark => currentUserSettings?.darkMode ?? true;

  void _resume(BuildContext context, Map<String, dynamic> session) {
    final stream = VideoStream.fromMap(Map<String, dynamic>.from(session['stream']));
    final epLinks =
        (session['epLinks'] as List).map((e) => EpisodeDetails.fromMap(Map<String, dynamic>.from(e))).toList();
    final controller = Platform.isAndroid ? BetterPlayerWrapper() : FvpWrapper();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (context) => PlayerDataProvider(
                initialStreams: [stream],
                initialStream: stream,
                epLinks: epLinks,
                showTitle: session['title'] ?? '',
                coverImageUrl: session['cover'],
                showId: session['showId'] ?? 0,
                selectedSource: session['selectedSource'] ?? '',
                startIndex: session['episodeIndex'] ?? 0,
                altDatabases: const [],
                preferDubs: session['preferDubs'] ?? false,
                lastWatchDuration: ((session['progress'] ?? 0.0) as num).toDouble() * 100,
              ),
            ),
            ChangeNotifierProvider(create: (context) => PlayerProvider(controller, true)),
          ],
          child: Watch(controller: controller),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: ResumeSession.notifier,
      builder: (context, session, _) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          left: 16,
          right: 16,
          bottom: session == null ? -(90 + bottomOffset) : bottomOffset,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: session == null ? 0 : 1,
            child: session == null ? const SizedBox.shrink() : _bar(context, session),
          ),
        );
      },
    );
  }

  Widget _bar(BuildContext context, Map<String, dynamic> session) {
    final loc = AppLocalizations.of(context);
    final progress = ((session['progress'] ?? 0.0) as num).toDouble().clamp(0.0, 1.0);
    final cover = session['cover'] as String?;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Material(
                color: _isDark
                    ? appTheme.backgroundSubColor.withValues(alpha: 0.6)
                    : Color.alphaBlend(Colors.black.withValues(alpha: 0.06), appTheme.backgroundSubColor)
                        .withValues(alpha: 0.85),
                child: InkWell(
                  onTap: () => _resume(context, session),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border:
                          Border.all(color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.08), width: 1),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white.withValues(alpha: _isDark ? 0.06 : 0.45), Colors.transparent],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: cover == null || cover.isEmpty
                                  ? Container(width: 46, height: 46, color: appTheme.backgroundColor)
                                  : CachedNetworkImage(imageUrl: cover, width: 46, height: 46, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    session['title'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: appTheme.textMainColor, fontWeight: FontWeight.w600, fontSize: 13.5),
                                  ),
                                  Text(
                                    "${loc.episode} ${session['episodeNumber'] ?? '?'}",
                                    maxLines: 1,
                                    style: TextStyle(color: appTheme.textSubColor, fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _resume(context, session),
                              visualDensity: VisualDensity.compact,
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: appTheme.accentColor, shape: BoxShape.circle),
                                child: Icon(Icons.play_arrow_rounded, color: appTheme.onAccent, size: 20),
                              ),
                            ),
                            IconButton(
                              onPressed: () => ResumeSession.clear(),
                              visualDensity: VisualDensity.compact,
                              icon: Icon(Icons.close_rounded, color: appTheme.textSubColor, size: 20),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 2, right: 2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 3,
                              backgroundColor: appTheme.textSubColor.withValues(alpha: 0.25),
                              valueColor: AlwaysStoppedAnimation(appTheme.accentColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
