import 'dart:io';

import 'package:kumaanime/ui/models/playerControllers/videoController.dart';
import 'package:kumaanime/ui/models/widgets/subtitles/subtitle.dart';
import 'package:kumaanime/ui/models/widgets/subtitles/subtitleSettings.dart';
import 'package:kumaanime/ui/models/widgets/subtitles/subtitleText.dart';
import 'package:flutter/material.dart';

class SubViewer extends StatefulWidget {
  final VideoController controller;
  final List<Subtitle> subs;
  final bool isLoading;
  final SubtitleSettings settings;

  const SubViewer({
    super.key,
    required this.controller,
    required this.subs,
    required this.settings,
    this.isLoading = false,
  });

  @override
  State<SubViewer> createState() => _SubViewerState();
}

class _SubViewerState extends State<SubViewer> {
  List<Subtitle> activeSubtitles = [];
  int lastLineIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateSubtitle);
    _updateSubtitle();
  }

  @override
  void didUpdateWidget(SubViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subs != widget.subs) {
      lastLineIndex = 0;
      activeSubtitles = [];
      _updateSubtitle();
    }
  }

  void _updateSubtitle() {
    final rawPosition = widget.controller.position;

    if (rawPosition == null || widget.subs.isEmpty) {
      if (activeSubtitles.isNotEmpty) {
        setState(() {
          activeSubtitles = [];
        });
      }
      return;
    }

    final currentPosition = rawPosition + (widget.settings.offset * 1000).round();

    if (lastLineIndex >= widget.subs.length ||
        (lastLineIndex > 0 && widget.subs[lastLineIndex].start.inMilliseconds > currentPosition)) {
      lastLineIndex = 0;
    }

    while (lastLineIndex < widget.subs.length && widget.subs[lastLineIndex].end.inMilliseconds < currentPosition) {
      lastLineIndex++;
    }

    List<Subtitle> newMatches = [];

    for (int i = lastLineIndex; i < widget.subs.length; i++) {
      final sub = widget.subs[i];

      if (sub.start.inMilliseconds > currentPosition) {
        break;
      }

      if (sub.end.inMilliseconds >= currentPosition) {
        newMatches.add(sub);
      }
    }

    if (!_areSubtitleListsEqual(activeSubtitles, newMatches)) {
      if (mounted) {
        setState(() {
          activeSubtitles = newMatches;
        });
      }
    }
  }

  bool _areSubtitleListsEqual(List<Subtitle> a, List<Subtitle> b) {
    if (a.length != b.length) return false;
    if (a.isEmpty && b.isEmpty) return true;

    return a.first.start.inMilliseconds == b.first.start.inMilliseconds &&
        a.first.end.inMilliseconds == b.first.end.inMilliseconds &&
        a.last.start.inMilliseconds == b.last.start.inMilliseconds &&
        a.last.end.inMilliseconds == b.last.end.inMilliseconds;
  }

  TextStyle subTextStyle() {
    return TextStyle(
      fontSize: (Platform.isWindows || Platform.isLinux) ? widget.settings.fontSize * 1.5 : widget.settings.fontSize,
      fontFamily: widget.settings.fontFamily ?? "Rubik",
      color: widget.settings.textColor,
      fontWeight: widget.settings.bold ? FontWeight.w700 : FontWeight.w500,
      fontFamilyFallback: const ["Poppins"],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.only(bottom: widget.settings.bottomMargin + 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 8),
              Text("Memuat Subtitle...", style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    final Map<SubtitleAlignment, List<Subtitle>> subsGrouped = {};
    for (final sub in activeSubtitles) {
      subsGrouped.putIfAbsent(sub.alignment, () => []).add(sub);
    }

    for (var list in subsGrouped.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }

    final size = MediaQuery.of(context).size;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Stack(
        children: subsGrouped.entries.map((group) {
          final alignment = group.key;
          final subs = group.value;

          return Align(
            alignment: getLineAlignment(alignment),
            child: Container(
              margin: EdgeInsets.only(bottom: widget.settings.bottomMargin, top: widget.settings.bottomMargin),
              constraints: BoxConstraints(maxWidth: size.width / 1.4, maxHeight: size.height * 0.7),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: size.width / 1.4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: subs
                        .map(
                          (sub) => Opacity(
                            opacity: widget.settings.opacity,
                            child: SubtitleText(
                              text: sub.dialogue,
                              style: subTextStyle(),
                              strokeColor: widget.settings.strokeColor,
                              strokeWidth: widget.settings.strokeWidth,
                              backgroundColor: widget.settings.backgroundColor,
                              backgroundTransparency: widget.settings.backgroundTransparency,
                              enableShadows: widget.settings.enableShadows,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Alignment getLineAlignment(SubtitleAlignment alignment) {
    switch (alignment) {
      case SubtitleAlignment.topLeft:
        return Alignment.topLeft;
      case SubtitleAlignment.topCenter:
        return Alignment.topCenter;
      case SubtitleAlignment.topRight:
        return Alignment.topRight;
      case SubtitleAlignment.centerLeft:
        return Alignment.centerLeft;
      case SubtitleAlignment.center:
        return Alignment.center;
      case SubtitleAlignment.centerRight:
        return Alignment.centerRight;
      case SubtitleAlignment.bottomLeft:
        return Alignment.bottomLeft;
      case SubtitleAlignment.bottomCenter:
        return Alignment.bottomCenter;
      case SubtitleAlignment.bottomRight:
        return Alignment.bottomRight;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateSubtitle);
    super.dispose();
  }
}
