import 'dart:ui';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/commons/systemBars.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/providers/playerSheetController.dart';
import 'package:kumaanime/ui/models/widgets/player/squigglySlider.dart';
import 'package:kumaanime/ui/pages/watch.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class PlayerSheetHost extends StatefulWidget {
  const PlayerSheetHost({super.key});

  @override
  State<PlayerSheetHost> createState() => _PlayerSheetHostState();
}

class _PlayerSheetHostState extends State<PlayerSheetHost> with SingleTickerProviderStateMixin {
  final PlayerSheet _sheet = PlayerSheet.instance;
  late final AnimationController _anim;

  static const _spring = SpringDescription(mass: 1, stiffness: 380, damping: 34);

  double _dragAccum = 0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, value: 1, lowerBound: 0, upperBound: 1);
    _anim.addListener(() => _sheet.visualValue = _anim.value);
    _sheet.addListener(_onSheetChanged);
  }

  @override
  void dispose() {
    _sheet.removeListener(_onSheetChanged);
    _anim.dispose();
    super.dispose();
  }

  void _onSheetChanged() {
    if (!mounted) return;
    if (_sheet.active) {
      _sheet.expandRequested ? _performExpand() : _performMinimize();
    }
    setState(() {});
  }

  void _springTo(double target, [double velocity = 0]) {
    _anim.animateWith(SpringSimulation(_spring, _anim.value, target, velocity));
  }

  void _performMinimize([double velocity = 0]) {
    _sheet.saveProgress();
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    showSystemBars();
    _springTo(0, velocity);
  }

  void _performExpand([double velocity = 0]) {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _springTo(1, velocity);
  }

  void _onFullDragUpdate(double dy) {
    _dragAccum += dy;
    final range = MediaQuery.sizeOf(context).height * 0.65;
    _anim.value = (1 - (_dragAccum / range)).clamp(0.0, 1.0);
  }

  void _onFullDragEnd(double velocity) {
    _dragAccum = 0;
    final normalized = velocity / MediaQuery.sizeOf(context).height;
    if (_anim.value < 0.55 || velocity > 700) {
      _sheet.requestMinimize();
    } else {
      _springTo(1, -normalized);
    }
  }

  void _onMiniDragUpdate(DragUpdateDetails details) {
    _dragAccum += details.delta.dy;
    final range = MediaQuery.sizeOf(context).height * 0.65;
    _anim.value = ((-_dragAccum) / range).clamp(0.0, 1.0);
  }

  void _onMiniDragEnd(DragEndDetails details) {
    _dragAccum = 0;
    final velocity = details.primaryVelocity ?? 0;
    if (_anim.value > 0.25 || velocity < -700) {
      _sheet.requestExpand();
    } else {
      _springTo(0, velocity / MediaQuery.sizeOf(context).height);
    }
  }

  bool get _isDark => currentUserSettings?.darkMode ?? true;

  @override
  Widget build(BuildContext context) {
    if (!_sheet.active) return const SizedBox.shrink();

    final media = MediaQuery.of(context);
    final screen = media.size;
    final miniHeight = 66.0;
    final miniBottom = media.viewPadding.bottom + 88;
    final miniRect = Rect.fromLTWH(16, screen.height - miniBottom - miniHeight, screen.width - 32, miniHeight);
    final fullRect = Offset.zero & screen;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final v = Curves.linear.transform(_anim.value.clamp(0.0, 1.0));
        final rect = Rect.lerp(miniRect, fullRect, v)!;
        final radius = lerpDouble(24, 0, v)!;
        final showFull = v > 0.02;
        final miniOpacity = (1 - v / 0.3).clamp(0.0, 1.0);
        final draggableLayer = v < 0.98;
        final blur = (1 - v) * 22;

        final miniGlass = _isDark
            ? appTheme.backgroundSubColor.withValues(alpha: 0.55)
            : Color.alphaBlend(Colors.black.withValues(alpha: 0.06), appTheme.backgroundSubColor)
                .withValues(alpha: 0.8);
        final fullColor = _isDark ? const Color(0xFF141518) : Colors.white;
        final surface = Color.lerp(miniGlass, fullColor, v)!;

        return Stack(
          children: [
            if (v > 0.02 && v < 1)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(color: Colors.black.withValues(alpha: 0.35 * v)),
                ),
              ),
            Positioned.fromRect(
              rect: rect,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: v < 1 ? (_isDark ? 0.3 : 0.16) : 0),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: v < 0.5 ? _sheet.requestExpand : null,
                  onVerticalDragUpdate: draggableLayer ? _onMiniDragUpdate : null,
                  onVerticalDragEnd: draggableLayer ? _onMiniDragEnd : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                      child: Container(
                        decoration: BoxDecoration(
                          color: surface,
                          border: v < 0.5
                              ? Border.all(
                                  color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.08 * (1 - v * 2)),
                                  width: 1)
                              : null,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Offstage(
                              offstage: !showFull,
                              child: Opacity(
                                opacity: ((v - 0.15) / 0.5).clamp(0.0, 1.0),
                                child: IgnorePointer(
                                  ignoring: v < 0.85,
                                  child: OverflowBox(
                                    minWidth: 0,
                                    minHeight: 0,
                                    maxWidth: screen.width,
                                    maxHeight: screen.height,
                                    alignment: Alignment.topCenter,
                                    child: Transform.scale(
                                      scale: (rect.width / screen.width).clamp(0.3, 1.0),
                                      alignment: Alignment.topCenter,
                                      child: SizedBox(
                                        width: screen.width,
                                        height: screen.height,
                                        child: MultiProvider(
                                          providers: [
                                            ChangeNotifierProvider.value(value: _sheet.dataProvider!),
                                            ChangeNotifierProvider.value(value: _sheet.playerProvider!),
                                          ],
                                          child: HeroControllerScope.none(
                                            child: Navigator(
                                              key: _sheet.nestedNavKey,
                                              onGenerateRoute: (settings) => MaterialPageRoute(
                                                builder: (context) => Watch(
                                                  controller: _sheet.controller!,
                                                  sheetMode: true,
                                                  onMinimize: _sheet.requestMinimize,
                                                  onMinimizeDragUpdate: _onFullDragUpdate,
                                                  onMinimizeDragEnd: _onFullDragEnd,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (miniOpacity > 0)
                              Opacity(
                                opacity: miniOpacity,
                                child: IgnorePointer(
                                  child: _miniBar(context),
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
          ],
        );
      },
    );
  }

  Widget _miniBar(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final dp = _sheet.dataProvider!;
    final pp = _sheet.playerProvider!;

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: Listenable.merge([dp, pp]),
        builder: (context, _) {
          final controller = _sheet.controller;
          final durationMs = (controller?.duration ?? 0).toDouble();
          final positionMs = (controller?.position ?? 0).toDouble();
          final progress = durationMs <= 0 ? 0.0 : (positionMs / durationMs).clamp(0.0, 1.0);
          final playing = controller?.isPlaying ?? false;
          final cover = dp.coverImageUrl;

          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: cover == null || cover.isEmpty
                          ? Container(width: 38, height: 38, color: appTheme.backgroundSubColor)
                          : CachedNetworkImage(imageUrl: cover, width: 38, height: 38, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dp.showTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: appTheme.textMainColor, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            "${loc.episode} ${dp.epLinks[dp.state.currentEpIndex].episodeNumber}",
                            maxLines: 1,
                            style: TextStyle(color: appTheme.textSubColor, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => playing ? controller?.pause() : controller?.play(),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: appTheme.textMainColor,
                        size: 26,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _sheet.close(),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close_rounded, color: appTheme.textSubColor, size: 22),
                    ),
                  ],
                ),
                SeekbarProgressBar(
                  style: seekbarStyleFromString(currentUserSettings?.seekbarStyle),
                  value: progress,
                  activeColor: appTheme.accentColor,
                  height: 10,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
