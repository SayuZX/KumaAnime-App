import 'dart:async';
import 'dart:io';

import 'package:kumaanime/core/anime/downloader/downloadManager.dart';
import 'package:kumaanime/core/app/logging.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/commons/systemBars.dart';
import 'package:kumaanime/core/data/animeSpecificPreference.dart';
import 'package:kumaanime/core/data/resumeSession.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/core/social/socialService.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/bottomSheets/watchSocialSheet.dart';
import 'package:kumaanime/ui/models/playerControllers/betterPlayer.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/player/controls.dart';
import 'package:kumaanime/ui/models/widgets/player/gestureOverlay.dart';
import 'package:kumaanime/ui/models/widgets/subtitles/subViewer.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:kumaanime/controllers/subtitle_controller.dart';
import 'package:kumaanime/core/commons/enums.dart';
import 'package:kumaanime/core/data/watching.dart';
import 'package:kumaanime/ui/models/widgets/player/playerUtils.dart';
import 'package:kumaanime/ui/models/providers/playerDataProvider.dart';
import 'package:kumaanime/ui/models/providers/playerProvider.dart';
import 'package:kumaanime/ui/models/providers/appProvider.dart';
import 'package:kumaanime/ui/models/playerControllers/videoController.dart';
import 'package:screen_brightness/screen_brightness.dart';

class Watch extends StatefulWidget {
  final VideoController controller;
  final bool localSource;
  const Watch({
    super.key,
    required this.controller,
    this.localSource = false,
  });

  @override
  State<Watch> createState() => _WatchState();
}

class _WatchState extends State<Watch> with WidgetsBindingObserver {
  late VideoController controller;
  late final SubtitleController _subController;
  VoidCallback? _dataProviderListener;
  bool? _lastYoutubeLayout;

  int? _countedEpIndex;

  @override
  void initState() {
    super.initState();
    setWatchMode();

    controller = widget.controller;
    _subController = SubtitleController();
    _subController.addListener(_onSubtitleError);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
      _initCallbacks(context);
    });

    WidgetsBinding.instance.addObserver(this);
  }

  void _onSubtitleError() {
    if (_subController.errorMessage != null && mounted) {
      floatingSnackBar(_subController.errorMessage!);
    }
  }

  void _loadExternalSubtitles() {
    if (!widget.localSource && mounted) {
      final dataProvider = context.read<PlayerDataProvider>();
      final animeId = dataProvider.showId;
      final epNum = dataProvider.epLinks[dataProvider.state.currentEpIndex].episodeNumber;
      final defaultLang = dataProvider.subtitleSettings.defaultLanguage;
      _subController.loadSubtitlesForEpisode(animeId, epNum, defaultLang);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // only android and ios has the 'paused' state
    if (state == (Platform.isWindows ? AppLifecycleState.inactive : AppLifecycleState.hidden) &&
        (currentUserSettings?.enablePipOnMinimize ?? false)) {
      // context.read<PlayerProvider>().setPip(true);
    }
    // else if (state == AppLifecycleState.resumed) {
    // context.read<PlayerProvider>().setPip(false);
    // setWatchMode();
    // }
  }

  final _channel = MethodChannel('kumaanime.app/utils');

  void _initCallbacks(BuildContext context) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "onUserLeaveHint") {
        if (currentUserSettings?.enablePipOnMinimize ?? false) {
          context.read<PlayerProvider>().setPip(true);
        }
      }
    });
  }

  void setWatchMode() {
    _lastYoutubeLayout = null;
    SystemChrome.setPreferredOrientations(watchPreferredOrientations());
  }

  void _initialize() async {
    /// Set black title bar
    context.read<AppProvider>().setTitlebarColor(appTheme.backgroundColor);

    final dataProvider = context.read<PlayerDataProvider>();

    Logs.player.log("Initializing stream ${dataProvider.state.currentStream}");

    dataProvider.initSubsettings();

    int lastEpIndex = dataProvider.state.currentEpIndex;
    _dataProviderListener = () {
      if (dataProvider.state.currentEpIndex != lastEpIndex) {
        lastEpIndex = dataProvider.state.currentEpIndex;
        _loadExternalSubtitles();
      }
    };
    dataProvider.addListener(_dataProviderListener!);
    _loadExternalSubtitles();

    if (!widget.localSource) {
      await dataProvider.extractCurrentStreamQualities();

      final q = dataProvider.getPreferredQualityStreamFromQualities();

      dataProvider.updateCurrentQuality(q);

      await controller.initiateVideo(dataProvider.state.currentStream.url,
          headers: dataProvider.state.currentStream.customHeaders);

      controller.setQuality(q);

      // Fetch those skips
      dataProvider.getSkipTimesForCurrentEpisode(videoDuration: (controller.duration ?? 0).toDouble());

      if (dataProvider.state.audioTracks.isNotEmpty) {
        // gamble on this setting :)
        dataProvider.updateCurrentAudioTrack(dataProvider.state.audioTracks.first);
        controller.setAudioTrack(dataProvider.state.currentAudioTrack);
      } else {
        Logs.player.log("Couldnt find audio tracks for this stream");
      }
    } else {
      await controller.initiateVideo(dataProvider.state.currentStream.url, offline: true);
    }

    final lastWatchPct = (dataProvider.lastWatchDuration ?? 0).clamp(0, 100);
    final totalMs = controller.duration ?? 0;
    final lastWatchDuration = totalMs <= 0 ? 0 : ((lastWatchPct / 100) * totalMs).toInt();

    // await dataProvider.updateDiscordPresence();

    // Seek to last watched part
    await controller.seekTo(Duration(milliseconds: lastWatchDuration)); //percentage to value

    if (mounted) context.read<PlayerProvider>().toggleSubs(action: dataProvider.state.currentStream.subtitle != null);

    _triedStreamUrls.add(dataProvider.state.currentStream.url);

    // Placed here for safety. placing it above might cause issues with custom controls functions
    setState(() {
      isInitiated = true;
      _isPlayerReady = true;
    });

    controller.addListener(_listener);

    if (controller is BetterPlayerWrapper) {
      (controller as BetterPlayerWrapper).controller.addEventsListener((ev) {
        if (ev.betterPlayerEventType == BetterPlayerEventType.exception) {
          _handlePlaybackError(ev.parameters?["exception"]?.toString() ?? ev.parameters?.toString());
        }
      });
    }

    // Since pip is only for android! (f* IOS)
    if (Platform.isAndroid) {
      try {
        // quirky hack... but we gotta do what we gotta do
        (controller as BetterPlayerWrapper).controller.addEventsListener((ev) {
          if (ev.betterPlayerEventType == BetterPlayerEventType.pipStop) {
            // The delay is required (cus its ignored without the delay for some reason)
            Future.delayed(Duration(milliseconds: 250), () {
              if (mounted) {
                setWatchMode();
                context.read<PlayerProvider>().handleWakelock();
              }
            });
          }
        });
      } catch (e) {
        Logs.player.log("PiP listener couldnt be added: ${e.toString()}");
      }
    }
  }

  void _listener() {
    if (!mounted) return;

    final playerProvider = context.read<PlayerProvider>();
    final dataProvider = context.read<PlayerDataProvider>();

    if (playerProvider.state.controlsVisible) {
      hideControlsOnTimeout(dataProvider, playerProvider);
    }

    final playState = (controller.isBuffering ?? false)
        ? PlayerState.buffering
        : (controller.isPlaying ?? false)
            ? PlayerState.playing
            : PlayerState.paused;

    playerProvider.updatePlayState(playState);

    final currentPositionInSeconds = (controller.position ?? 0) ~/ 1000;
    final durationInSeconds = (controller.duration ?? 0) ~/ 1000;

    final newState = dataProvider.state.copyWith(
      currentTimeStamp: getFormattedTime(currentPositionInSeconds),
      maxTimeStamp: getFormattedTime(durationInSeconds),
      sliderValue: currentPositionInSeconds,
    );

    // Update timestamps and slider position
    dataProvider.update(newState);

    playerProvider.handleWakelock(); // Yes, it handles wakelock state

    if (!widget.localSource) {
      final currentByTotal = (controller.position ?? 0) / (controller.duration ?? 0);
      if (currentByTotal * 100 >= 75 && !dataProvider.state.preloadStarted && (controller.isPlaying ?? false)) {
        dataProvider.preloadNextEpisode();
        updateWatching(
          dataProvider.showId,
          dataProvider.showTitle,
          dataProvider.state.currentEpIndex + 1,
          dataProvider.altDatabases,
        );
      }
    }

    final watchedFraction =
        (controller.duration ?? 0) > 0 ? (controller.position ?? 0) / (controller.duration ?? 1) : 0.0;
    if (watchedFraction >= 0.5 && _countedEpIndex != dataProvider.state.currentEpIndex) {
      _countedEpIndex = dataProvider.state.currentEpIndex;
      SocialService.instance.recordEpisodeWatched();
    }

    final finalEpReached = dataProvider.state.currentEpIndex + 1 == dataProvider.epLinks.length;

    //play the loaded episode if equal to duration
    if (!finalEpReached &&
        controller.duration != null &&
        (controller.position ?? 0) / 1000 == (controller.duration ?? 0) / 1000) {
      if (controller.isPlaying ?? false) {
        controller.pause();
      }
      playerProvider.playPreloadedEpisode(dataProvider);
    }

    if ((currentUserSettings?.autoOpEdSkip ?? false) && !_isSkippingOpOrEd) {
      final isAtOp = dataProvider.state.opSkip != null &&
          currentPositionInSeconds >= dataProvider.state.opSkip!.start &&
          currentPositionInSeconds <= dataProvider.state.opSkip!.end;

      final isAtEd = dataProvider.state.edSkip != null &&
          currentPositionInSeconds >= dataProvider.state.edSkip!.start &&
          currentPositionInSeconds <= dataProvider.state.edSkip!.end - 1;

      if (isAtOp) {
        _isSkippingOpOrEd = true;
        Logs.player
            .log("Auto skipping OP from ${dataProvider.state.opSkip!.start}s to ${dataProvider.state.opSkip!.end}s");
        playerProvider
            .fastForward(dataProvider.state.opSkip!.end - currentPositionInSeconds + 1)
            .then((_) => _isSkippingOpOrEd = false);
      } else if (isAtEd) {
        _isSkippingOpOrEd = true;
        Logs.player
            .log("Auto skipping ED from ${dataProvider.state.edSkip!.start}s to ${dataProvider.state.edSkip!.end}s");
        playerProvider
            .fastForward(dataProvider.state.edSkip!.end - currentPositionInSeconds)
            .then((_) => _isSkippingOpOrEd = false);
      }
    }
  }

  // Mutex to avoid multiple skips at once
  bool _isSkippingOpOrEd = false;

  bool get isDesktop => Platform.isWindows || Platform.isLinux;

  void hideControlsOnTimeout(PlayerDataProvider dp, PlayerProvider pp, {int timeoutSeconds = 5}) {
    if (!_isPlayerReady || !(controller.isInitialized ?? false)) return;
    if (_controlsTimer == null && (controller.isPlaying ?? false)) {
      _controlsTimer = Timer(Duration(seconds: timeoutSeconds), () {
        if (controller.isPlaying ?? false) {
          pp.toggleControlsVisibility(action: false);
        }
        _controlsTimer = null;
      });
    }
  }

  void _handlePlaybackError(String? message) {
    if (!mounted || _handlingError || widget.localSource) return;
    _handlingError = true;

    final loc = AppLocalizations.of(context);
    final lower = (message ?? '').toLowerCase();
    final is403 = lower.contains("403") || lower.contains("source error") || lower.contains("forbidden");
    Logs.player.log("Playback error: $message");
    floatingSnackBar(is403 ? loc.watchServerDenied403 : loc.watchPlaybackFailed);

    _tryFallbackStream().whenComplete(() => _handlingError = false);
  }

  Future<void> _tryFallbackStream() async {
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    final dataProvider = context.read<PlayerDataProvider>();
    final candidates = dataProvider.state.streams.where((s) => !_triedStreamUrls.contains(s.url)).toList();

    if (candidates.isEmpty) {
      floatingSnackBar(loc.watchNoOtherServers);
      return;
    }

    final next = candidates.first;
    _triedStreamUrls.add(next.url);
    _isPlayerReady = false;
    dataProvider.update(dataProvider.state.copyWith(currentStream: next));

    try {
      await controller.initiateVideo(next.url, headers: next.customHeaders);
      if (!mounted) return;
      setState(() => _isPlayerReady = true);
      floatingSnackBar(loc.watchSwitchedToServer(next.server));
    } catch (e) {
      Logs.player.log("Fallback stream failed: $e");
    }
  }

  Timer? _controlsTimer = null;

  Timer? pointerHideTimer = null;

  // This is required to avoid *controller is not initiate error*
  bool isInitiated = false;

  bool _isPlayerReady = false;
  bool _handlingError = false;
  final Set<String> _triedStreamUrls = {};

  // Just a smol logic to handle taps since gesture dectector doesnt do the job with double taps
  Timer? _tapTimer;
  int lastTapTime = 0;
  final int doubleTapThreshold = 300; // in ms
  // bool _waitingForSecondTap = false;

  bool _showRewindAnim = false;
  bool _showForwardAnim = false;
  Timer? _animTimer;

  void _showFastForwardAnim(bool isForward) {
    skipCount++;

    _animTimer?.cancel();

    setState(() {
      if (isForward) {
        _showForwardAnim = true;
        _showRewindAnim = false;
      } else {
        _showRewindAnim = true;
        _showForwardAnim = false;
      }
    });

    _animTimer = Timer(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showRewindAnim = false;
          _showForwardAnim = false;
        });
      }
    });
  }

  // void _handleTap() {
  //   // New Logic Baby!
  //   if (_waitingForSecondTap) {
  //     // event where the 2nd tap is detected
  //     _waitingForSecondTap = false;
  //     _tapTimer?.cancel();
  //     _handleDoubleTap();
  //     return;
  //   }

  //   _handleSingleTap();
  //   _waitingForSecondTap = true;
  //   _tapTimer = Timer(Duration(milliseconds: doubleTapThreshold), () {
  //     // after threshold time, if no 2nd tap, treat it as succesful single tap
  //     if (mounted) {
  //       setState(() {
  //         _waitingForSecondTap = false;
  //       });
  //     }
  //   });

  //   // if (_tapTimer != null && _tapTimer!.isActive) {
  //   //   // Double tap
  //   //   _tapTimer!.cancel();
  //   //   _handleDoubleTap();
  //   // } else {
  //   //   // Single tap
  //   //   _tapTimer = Timer(Duration(milliseconds: doubleTapThreshold), () {
  //   //     _handleSingleTap();
  //   //   });
  //   // }
  // }

  void _handleSingleTap() {
    final playerProvider = context.read<PlayerProvider>();
    playerProvider.toggleControlsVisibility();
    if (!playerProvider.state.controlsVisible) {
      _controlsTimer?.cancel();
      _controlsTimer = null;
    }
  }

  void _handleDoubleTap() {
    if (!isDesktop) return;
    if (context.read<PlayerProvider>().state.pip) return;
    final themeProvider = context.read<AppProvider>();
    themeProvider.setFullScreen(!themeProvider.isFullScreen);
  }

  bool hidePointer = false;

  // for tap gesures
  bool lTapped = false, rTapped = false;

  bool spedUp = false;

  int skipCount = 0;

  // double? _lastSpeedChangeOffset = 0.0;
  double lastSpeed = 1.0;

  double? _displayVolume;
  double? _displayBrightness;
  Timer? _indicatorTimer;

  void _showIndicator({double? volume, double? brightness}) {
    setState(() {
      if (volume != null) _displayVolume = volume;
      if (brightness != null) _displayBrightness = brightness;
    });

    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _displayVolume = null;
          _displayBrightness = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final playerDataProvider = context.watch<PlayerDataProvider>();

    final youtubeLayout = _useYoutubeLayout(MediaQuery.orientationOf(context));
    _applySystemUiForLayout(youtubeLayout);

    return ChangeNotifierProvider<SubtitleController>.value(
      value: _subController,
      child: PopScope(
        canPop: youtubeLayout || !Platform.isAndroid,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // back from fullscreen returns to the portrait player instead of leaving
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          showSystemBars();
          SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
          return;
        }
        // save the last watched duration
        if (isInitiated && (controller.duration ?? 0) > 0) {
          final pos = (controller.position ?? 0).toDouble();
          final dur = controller.duration!.toDouble();
          double watchPercentage = (dur <= 0) ? 0.0 : (pos / dur);
          watchPercentage = watchPercentage.clamp(0.0, 1.0);
          await saveAnimeSpecificPreference(
            playerDataProvider.showId.toString(),
            AnimeSpecificPreference(
              lastWatchDuration: {playerDataProvider.state.currentEpIndex + 1: watchPercentage * 100},
            ),
          );

          if (watchPercentage >= 0.9 || widget.localSource) {
            await ResumeSession.clear();
          } else {
            await ResumeSession.save({
              'showId': playerDataProvider.showId,
              'title': playerDataProvider.showTitle,
              'cover': playerDataProvider.coverImageUrl,
              'episodeIndex': playerDataProvider.state.currentEpIndex,
              'episodeNumber': playerDataProvider.epLinks[playerDataProvider.state.currentEpIndex].episodeNumber,
              'progress': watchPercentage,
              'positionMs': pos.toInt(),
              'durationMs': dur.toInt(),
              'stream': playerDataProvider.state.currentStream.toMap(),
              'epLinks': playerDataProvider.epLinks.map((e) => e.toMap()).toList(),
              'selectedSource': playerDataProvider.selectedSource,
              'preferDubs': playerDataProvider.preferDubs,
            });
          }
        }
        await context.read<AppProvider>()
          ..setFullScreen(false)
          ..setTitlebarColor(null);
        // playerDataProvider.clearDiscordPresence();
      },
      child: Scaffold(
        backgroundColor: youtubeLayout ? appTheme.backgroundColor : Colors.black,
        body: _layoutBody(
          youtubeLayout,
          playerDataProvider,
          GestureOverlay(
            isDesktop: isDesktop,
            controlsLocked: playerDataProvider.state.controlsLocked,
            enableHoldToSpeedUp: currentUserSettings?.enableHoldToSpeedUp ?? true,
            getInitialBrightness: () => ScreenBrightness.instance.application,
            getInitialVolume: () async => playerProvider.state.volume,
            onBrightnessUpdate: (val) {
              ScreenBrightness.instance.setApplicationScreenBrightness(val);
              _showIndicator(brightness: val);
            },
            onDoubleTapCenter: _handleDoubleTap,
            onDoubleTapLeft: () {
              // desktop shouldnt be having double tap to skip functionality
              if (playerDataProvider.state.controlsLocked || isDesktop) return;
              if (currentUserSettings?.doubleTapToSkip ?? true) {
                playerProvider.fastForward(-(currentUserSettings?.skipDuration ?? 10));
                if (!_showRewindAnim) skipCount = 0;
                _showFastForwardAnim(false);
              }
            },
            onDoubleTapRight: () {
              // desktop shouldnt be having double tap to skip functionality
              if (playerDataProvider.state.controlsLocked || isDesktop) return;
              if (currentUserSettings?.doubleTapToSkip ?? true) {
                playerProvider.fastForward(currentUserSettings?.skipDuration ?? 10);
                if (!_showForwardAnim) skipCount = 0;
                _showFastForwardAnim(true);
              }
            },
            onSingleTap: () => _handleSingleTap(),
            onSpeedChange: (increase) {
              final currSpeed = playerProvider.state.speed;
              if (increase) {
                playerProvider
                    .setSpeed(playerProvider.playbackSpeeds.firstWhere((s) => s > currSpeed, orElse: () => currSpeed));
              } else {
                playerProvider.setSpeed(
                    playerProvider.playbackSpeeds.lastWhere((s) => s < currSpeed && s >= 2, orElse: () => currSpeed));
              }
              print(increase);
            },
            onSpeedUpStart: () {
              if (playerProvider.state.playerState == PlayerState.playing &&
                  !isDesktop &&
                  !playerDataProvider.state.controlsLocked) {
                spedUp = true;
                lastSpeed = playerProvider.state.speed;
                // ensure atleast 2x speed on long press and max of 10x (max available speed)
                playerProvider.setSpeed((lastSpeed * 2).clamp(2, playerProvider.playbackSpeeds.last));
              }
            },
            onSpeedUpEnd: () {
              if (!spedUp || isDesktop) return;
              spedUp = false;
              if (playerProvider.state.speed < 2) return;
              // reset speed
              playerProvider.setSpeed(lastSpeed);
              print("Reduced speed to: ${playerProvider.state.speed}x");
            },
            onVerticalDragEnd: () {},
            onVolumeUpdate: (val) {
              playerProvider.updateVolume(val);
              _showIndicator(volume: val);
            },
            onPointerHover: (event) {
              // show controls on mouse movement
              if (!playerProvider.state.controlsVisible) playerProvider.toggleControlsVisibility(action: true);
              hideControlsOnTimeout(playerDataProvider, playerProvider, timeoutSeconds: 3);

              // Hide the pointer when controls arent visible and mouse is unmoved for 3 seconds
              // if (playerProvider.state.controlsVisible) return;
              if (hidePointer) {
                setState(() {
                  hidePointer = false;
                });
              }
              pointerHideTimer?.cancel();
              pointerHideTimer = Timer(Duration(seconds: 3), () {
                if (mounted && !hidePointer)
                  setState(() {
                    hidePointer = true;
                    pointerHideTimer = null;
                  });
              });
            },
            child: MouseRegion(
              cursor: playerProvider.state.controlsVisible || !hidePointer
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.none,
              child: Stack(
                children: [
                  Player(controller),
                  if (playerProvider.state.showSubs)
                    ListenableBuilder(
                      listenable: _subController,
                      builder: (context, _) {
                        return SubViewer(
                          controller: controller,
                          subs: _subController.parsedSubtitles,
                          isLoading: _subController.isLoading,
                          settings: playerDataProvider.subtitleSettings,
                        );
                      },
                    ),
                  isInitiated
                      ? AnimatedOpacity(
                          duration: Duration(milliseconds: 150),
                          opacity: playerProvider.state.controlsVisible ? 1 : 0,
                          child: Stack(
                            children: [
                              IgnorePointer(ignoring: true, child: overlay()),
                              IgnorePointer(ignoring: !playerProvider.state.controlsVisible, child: Controls()),
                            ],
                          ),
                        )
                      : (isDesktop)
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 10, left: 10),
                                  child: IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: Icon(
                                        Icons.arrow_back,
                                        color: Colors.white,
                                        size: 35,
                                      )),
                                ),
                                PlayerLoadingWidget(),
                                SizedBox.shrink()
                              ],
                            )
                          : Container(),
                  _buildSpeedIndicator(),
                  _skipIndicators(),
                  _buildVolumeBrightnessIndicators(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  bool _useYoutubeLayout(Orientation orientation) {
    switch (currentUserSettings?.playerOrientation ?? 'auto') {
      case 'landscape':
        return false;
      case 'portrait':
        return true;
      default:
        return orientation == Orientation.portrait;
    }
  }

  void _applySystemUiForLayout(bool youtube) {
    if (youtube == _lastYoutubeLayout && isInitiated) return;
    _lastYoutubeLayout = youtube;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SystemChrome.setEnabledSystemUIMode(youtube ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky);
      youtube ? showSystemBars() : hideSystemBars();
    });
  }

  double _minimizeDrag = 0;
  bool _minimizeDragging = false;

  Widget _layoutBody(bool youtube, PlayerDataProvider dataProvider, Widget player) {
    if (!youtube) {
      return Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: player,
      );
    }
    final screenHeight = MediaQuery.sizeOf(context).height;
    return AnimatedContainer(
      duration: _minimizeDragging ? Duration.zero : const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      transform: Matrix4.translationValues(0, _minimizeDrag, 0)
        ..scaleByDouble(1 - (_minimizeDrag / screenHeight) * 0.12, 1 - (_minimizeDrag / screenHeight) * 0.12, 1, 1),
      transformAlignment: Alignment.topCenter,
      child: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragStart: (details) => setState(() => _minimizeDragging = true),
              onVerticalDragUpdate: (details) {
                setState(() => _minimizeDrag = (_minimizeDrag + details.delta.dy).clamp(0.0, screenHeight));
              },
              onVerticalDragEnd: (details) {
                final fling = (details.primaryVelocity ?? 0) > 700;
                if (_minimizeDrag > 140 || fling) {
                  Navigator.of(context).maybePop();
                } else {
                  setState(() {
                    _minimizeDragging = false;
                    _minimizeDrag = 0;
                  });
                }
              },
              onVerticalDragCancel: () => setState(() {
                _minimizeDragging = false;
                _minimizeDrag = 0;
              }),
              child: Container(
                color: Colors.black,
                child: ClipRect(child: AspectRatio(aspectRatio: 16 / 9, child: player)),
              ),
            ),
            Expanded(
              child: WatchSocialPanel(
                animeId: dataProvider.showId,
                title: dataProvider.showTitle,
                onDownload: _downloadCurrent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadCurrent() {
    final dp = context.read<PlayerDataProvider>();
    final stream = dp.state.currentStream;
    DownloadManager().addDownloadTask(
      stream.url,
      "${dp.showTitle} - Ep ${dp.state.currentEpIndex + 1}",
      subtitleUrl: stream.subtitle,
      customHeaders: stream.customHeaders ?? const {},
    );
    floatingSnackBar(AppLocalizations.of(context).watchDownloadingEpisode);
  }

  Widget _buildVolumeBrightnessIndicators() {
    if (_displayVolume == null && _displayBrightness == null) return const SizedBox.shrink();

    final isVolume = _displayVolume != null;
    final value = isVolume ? _displayVolume! : _displayBrightness!;
    final icon = isVolume ? (value == 0 ? Icons.volume_off : Icons.volume_up) : Icons.light_mode;

    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: appTheme.backgroundSubColor.withAlpha(220),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 16),
              Text(
                "${(value * 100).toInt()}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Align _buildSpeedIndicator() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 200,
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(top: 10),
        child: IgnorePointer(
          ignoring: true,
          child: AnimatedOpacity(
              opacity: spedUp ? 1 : 0,
              duration: Duration(milliseconds: 100),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _playbackSpeedIndicator(),
                _playbackSpeedSlider(),
              ])),
        ),
      ),
    );
  }

  Widget _playbackSpeedSlider() {
    final speed = context.read<PlayerProvider>().state.speed;
    final playbackSpeeds = context.read<PlayerProvider>().playbackSpeeds;
    final divisions = playbackSpeeds.where((e) => e >= 2).length - 1;
    return SliderTheme(
      data: SliderThemeData(
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
        trackHeight: 4,
        activeTrackColor: Colors.transparent,
        inactiveTrackColor: Colors.transparent,
        thumbColor: appTheme.accentColor,
        year2023: false,
      ),
      child: Slider(
        value: speed.clamp(2, playbackSpeeds.last),
        min: 2,
        max: playbackSpeeds.last,
        divisions: divisions > 0 ? divisions : null,
        label: "${speed}x",
        onChanged: (value) {
          context.read<PlayerProvider>().setSpeed(value);
        },
      ),
    );
  }

  Widget _playbackSpeedIndicator() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: appTheme.backgroundSubColor.withAlpha(100),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        "${context.read<PlayerProvider>().state.speed}x",
        style: TextStyle(
          fontSize: 14,
        ),
      ),
    );
  }

  IgnorePointer _skipIndicators() {
    return IgnorePointer(
      ignoring: true,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedOpacity(
                duration: Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                opacity: _showRewindAnim ? 1 : 0,
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    // color: appTheme.backgroundSubColor.withAlpha(200),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    "- ${(currentUserSettings?.skipDuration ?? 10) * skipCount}s",
                    style: TextStyle(
                      fontSize: 23,
                    ),
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: Duration(milliseconds: 400),
                opacity: _showForwardAnim ? 1 : 0,
                curve: Curves.easeInOut,
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    // color: appTheme.backgroundSubColor.withAlpha(200),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    "+ ${(currentUserSettings?.skipDuration ?? 10) * skipCount}s",
                    style: TextStyle(
                      fontSize: 23,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Container overlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [
              Color.fromARGB(220, 0, 0, 0),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.7]),
      ),
      child: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  Color.fromARGB(220, 0, 0, 0),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.0, 0.7])),
      ),
    );
  }

  @override
  void dispose() {
    _subController.removeListener(_onSubtitleError);
    _subController.dispose();
    if (_dataProviderListener != null) {
      context.read<PlayerDataProvider>().removeListener(_dataProviderListener!);
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    showSystemBars();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    if (controller.duration != null && controller.duration! > 0) {
      //store the exact percentage of watched
      if (!widget.localSource) print("SAVED WATCH DURATION");
    }

    controller.removeListener(_listener);
    controller.dispose();
    _controlsTimer?.cancel();
    _tapTimer?.cancel();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
