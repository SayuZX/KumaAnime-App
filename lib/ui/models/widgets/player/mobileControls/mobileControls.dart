import 'package:kumaanime/ui/models/bottomSheets/customControlsSheet.dart';
import 'package:kumaanime/ui/models/widgets/loader.dart';
import 'package:kumaanime/ui/models/providers/playerDataProvider.dart';
import 'package:kumaanime/ui/models/providers/playerProvider.dart';
import 'package:kumaanime/ui/models/widgets/player/mobileControls/bottomControls.dart';
import 'package:kumaanime/ui/models/widgets/player/mobileControls/topControls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/commons/enums.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';

class MobileControls extends StatefulWidget {
  const MobileControls({
    super.key,
  });

  @override
  State<MobileControls> createState() => _MobileControlsState();
}

class _MobileControlsState extends State<MobileControls> {
  bool startedLoadingNext = false;

  bool calledAutoNext = false;

  @override
  void initState() {
    super.initState();
  }

  int? skipDuration = currentUserSettings?.skipDuration ?? 10;
  int? megaSkipDuration = currentUserSettings?.megaSkipDuration ?? 85;

  @override
  void dispose() {
    super.dispose();
    WakelockPlus.disable();
    _fn.dispose();
  }

  final _fn = FocusNode();

  void _keyListenerEvent(KeyEvent event) {
    if (event is KeyUpEvent) return;
    print("Key pressed: ${event.logicalKey.keyLabel}");
    print(event);
    switch (event.logicalKey) {
      case LogicalKeyboardKey.mediaPlayPause:
      case LogicalKeyboardKey.mediaPause:
        provider.controller.pause();
        break;
      case LogicalKeyboardKey.mediaPlay:
        provider.controller.play();
        break;
      case LogicalKeyboardKey.mediaTrackNext:
        if (dataProvider.state.currentEpIndex + 1 == dataProvider.epLinks.length) return;
        provider.playPreloadedEpisode(dataProvider);
        break;
      case LogicalKeyboardKey.mediaTrackPrevious:
        if (dataProvider.state.currentEpIndex == 0) return;
        showSheet(
            context,
            CustomControlsBottomSheet(
                index: dataProvider.state.currentEpIndex - 1, dataProvider: dataProvider, playerProvider: provider));
        break;
      case LogicalKeyboardKey.mediaFastForward:
        provider.fastForward(skipDuration ?? 10);
        break;
      case LogicalKeyboardKey.mediaRewind:
        provider.fastForward(-(skipDuration ?? 10));
        break;
      case LogicalKeyboardKey.select:
        {
          if (!provider.state.controlsVisible) {
            provider.toggleControlsVisibility();
          }
          break;
        }
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowRight:
        {
          if (!provider.state.controlsVisible) {
            provider.toggleControlsVisibility();
          }
        }

      default:
        print("Unhandled key: ${event.logicalKey.keyLabel} (${event.logicalKey.keyId}) type: ${event.deviceType.name}");
    }
  }

  late PlayerProvider provider;
  late PlayerDataProvider dataProvider;

  @override
  Widget build(BuildContext context) {
    dataProvider = context.watch<PlayerDataProvider>();
    provider = context.watch<PlayerProvider>();
    final loc = AppLocalizations.of(context);
    return KeyboardListener(
      focusNode: _fn,
      autofocus: true,
      onKeyEvent: _keyListenerEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMini = constraints.maxHeight < 260;
          final double LRpadding = isMini ? 10 : 30;
          return Padding(
            padding: EdgeInsets.only(top: isMini ? 6 : 15, left: LRpadding, right: LRpadding, bottom: 5),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TopControls(provider: provider, dataProvider: dataProvider, context: context),
                      Expanded(
                        child: dataProvider.state.controlsLocked ? lockedCenterControls() : centerControls(context),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      dataProvider.state.currentTimeStamp,
                                      style: TextStyle(color: Colors.white, ),
                                    ),
                                    const Text(
                                      " / ",
                                      style: TextStyle(color: Colors.white, ),
                                    ),
                                    Text(
                                      dataProvider.state.maxTimeStamp,
                                      style: TextStyle(color: Colors.white, ),
                                    ),
                                  ],
                                ),
                                if (!dataProvider.state.controlsLocked)
                                  Row(
                                    children: [
                                      if (megaSkipDuration != null && (currentUserSettings?.enableMegaSkip ?? true))
                                        megaSkipButton(loc),
                                      _fullscreenButton(isMini),
                                    ],
                                  ),
                              ],
                            ),
                            Container(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 20,
                                child: IgnorePointer(
                                  ignoring: dataProvider.state.controlsLocked,
                                  child: Container(
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                          trackHeight: 1.3,
                                          thumbColor: appTheme.accentColor,
                                          activeTrackColor: appTheme.accentColor,
                                          inactiveTrackColor: Color.fromARGB(255, 121, 121, 121),
                                          secondaryActiveTrackColor: Color.fromARGB(255, 167, 167, 167),
                                          thumbShape: dataProvider.state.controlsLocked
                                              ? SliderComponentShape.noThumb
                                              : RoundSliderThumbShape(enabledThumbRadius: 6),
                                          trackShape: EdgeToEdgeTrackShape(),
                                          overlayShape: SliderComponentShape.noThumb),
                                      child: Slider(
                                        value: dataProvider.state.sliderValue.toDouble(),
                                        secondaryTrackValue: provider.controller.buffered?.toDouble(),
                                        onChanged: (val) {
                                          setState(() {
                                            // provider.state = provider.state.copyWith();
                                            provider.controller.seekTo(Duration(seconds: val.toInt()));
                                          });
                                        },
                                        onChangeStart: (value) {
                                          provider.controller.pause();
                                        },
                                        onChangeEnd: (value) {
                                          provider.controller.play();
                                        },
                                        min: 0,
                                        max: (provider.controller.duration ?? 0) / 1000,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (!isMini) BottomControls(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _fullscreenButton(bool isMini) {
    return InkWell(
      onTap: () {
        SystemChrome.setPreferredOrientations(isMini
            ? const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
            : const [DeviceOrientation.portraitUp]);
      },
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          isMini ? Icons.fullscreen_rounded : Icons.fullscreen_exit_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  ElevatedButton megaSkipButton(AppLocalizations loc) {
    int posInSec = (provider.controller.position! / 1000).toInt();
    final isAtOp = dataProvider.state.opSkip != null &&
        posInSec >= dataProvider.state.opSkip!.start &&
        posInSec <= dataProvider.state.opSkip!.end;
    final isAtEd = dataProvider.state.edSkip != null &&
        posInSec >= dataProvider.state.edSkip!.start &&
        posInSec <= dataProvider.state.edSkip!.end;

    return ElevatedButton(
      onPressed: () {
        provider.fastForward(isAtOp
            ? dataProvider.state.opSkip!.end - posInSec
            : isAtEd
                ? dataProvider.state.edSkip!.end - posInSec
                : megaSkipDuration!);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(68, 0, 0, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: appTheme.accentColor),
        ),
      ),
      child: Container(
        height: 50,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Text(
                isAtOp
                    ? loc.mcSkipOp
                    : isAtEd
                        ? loc.mcSkipEd
                        : loc.mcMegaSkipSeconds(megaSkipDuration ?? 0),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),
            ),
            Icon(
              Icons.fast_forward_rounded,
              color: Colors.white,
            )
          ],
        ),
      ),
    );
  }

  Container lockedCenterControls() {
    return Container(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (provider.controller.isBuffering ?? false)
            Container(
              width: 40,
              height: 40,
              child: Center(
                child: KumaAnimeLoading(color: appTheme.accentColor, size: 40),
              ),
            ),
        ],
      ),
    );
  }

  Container centerControls(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.only(right: 5),
              height: 65,
              width: 65,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  if (dataProvider.state.currentEpIndex == 0) return floatingSnackBar(loc.mcAlreadyFirstEpisode);
                  showSheet(
                    context,
                    CustomControlsBottomSheet(
                      index: dataProvider.state.currentEpIndex - 1,
                      dataProvider: dataProvider,
                      playerProvider: provider,
                    ),
                  );
                },
                child: Icon(
                  Icons.skip_previous_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          // ),
          Material(
            color: Colors.transparent,
            child: Container(
              height: 65,
              width: 65,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  provider.fastForward(skipDuration != null ? -skipDuration! : -10);
                },
                child: Icon(
                  Icons.fast_rewind_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          Container(
            // padding: EdgeInsets.only(left: 35, right: 35),
            child: !(provider.controller.isBuffering ?? false)
                ? Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: EdgeInsets.only(left: 5, right: 5),
                      height: 65,
                      width: 65,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          if (provider.state.playerState == PlayerState.playing) {
                            // playPause = Icons.play_arrow_rounded;
                            provider.controller.pause();
                          } else {
                            // playPause = Icons.pause_rounded;
                            provider.controller.play();
                          }
                        },
                        child: Icon(
                          provider.state.playerState == PlayerState.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 45,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 65,
                    height: 65,
                    margin: EdgeInsets.only(left: 5, right: 5),
                    child: Center(
                      child: KumaAnimeLoading(color: appTheme.accentColor, size: 40),
                    ),
                  ),
          ),
          Material(
            color: Colors.transparent,
            child: Container(
              height: 65,
              width: 65,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  provider.fastForward(skipDuration ?? 10);
                },
                child: Icon(
                  Icons.fast_forward_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.only(left: 5),
              height: 65,
              width: 65,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  //get next episode sources!
                  if (dataProvider.state.currentEpIndex + 1 == dataProvider.epLinks.length)
                    return floatingSnackBar(loc.mcAlreadyFinalEpisode);
                  if (dataProvider.state.preloadedSources.isNotEmpty) {
                    print("from preload");
                    provider.playPreloadedEpisode(dataProvider);
                  } else {
                    showSheet(
                      context,
                      CustomControlsBottomSheet(
                        index: dataProvider.state.currentEpIndex + 1,
                        dataProvider: dataProvider,
                        playerProvider: provider,
                      ),
                    );
                  }
                },
                child: Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          // ),
        ],
      ),
    );
  }

  void showSheet(BuildContext context, Widget child) => showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      context: context,
      builder: (BuildContext context) {
        return child;
      });
}

class EdgeToEdgeTrackShape extends RoundedRectSliderTrackShape {
  // Override getPreferredRect to adjust the track's dimensions
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2.0;
    final double trackWidth = parentBox.size.width;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(offset.dx, trackTop, trackWidth, trackHeight);
  }
}
