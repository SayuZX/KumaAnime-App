import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

class ThemeTransition {
  static final boundaryKey = GlobalKey();
  static bool _running = false;

  static Future<void> run(
      BuildContext originContext, Future<void> Function() switchTheme) async {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    final overlay = Overlay.maybeOf(originContext, rootOverlay: true);
    if (_running || boundary == null || overlay == null) {
      await switchTheme();
      return;
    }

    _running = true;

    ui.Image? image;
    try {
      image = await boundary.toImage(
          pixelRatio: View.of(originContext).devicePixelRatio);
    } catch (_) {
      _running = false;
      await switchTheme();
      return;
    }

    Offset origin;
    Size screenSize;
    final box = originContext.findRenderObject() as RenderBox?;
    screenSize = MediaQuery.of(originContext).size;
    if (box != null && box.attached) {
      origin = box.localToGlobal(box.size.center(Offset.zero));
    } else {
      origin = screenSize.center(Offset.zero);
    }

    final maxRadius = [
      origin.distance,
      (origin - Offset(screenSize.width, 0)).distance,
      (origin - Offset(0, screenSize.height)).distance,
      (origin - Offset(screenSize.width, screenSize.height)).distance,
    ].reduce(max);

    final controller = AnimationController(
        vsync: _TransitionTicker(),
        duration: const Duration(milliseconds: 650));
    final animation =
        CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);

    final capturedImage = image;
    final entry = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _RevealPainter(
              image: capturedImage,
              progress: animation.value,
              origin: origin,
              maxRadius: maxRadius,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    try {
      await switchTheme();
      await SchedulerBinding.instance.endOfFrame;
      await controller.forward();
    } finally {
      entry.remove();
      controller.dispose();
      capturedImage.dispose();
      _running = false;
    }
  }
}

class _TransitionTicker extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

class _RevealPainter extends CustomPainter {
  final ui.Image image;
  final double progress;
  final Offset origin;
  final double maxRadius;

  _RevealPainter({
    required this.image,
    required this.progress,
    required this.origin,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = maxRadius * progress;
    final screen = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addOval(Rect.fromCircle(center: origin, radius: radius));
    canvas.clipPath(Path.combine(PathOperation.difference, screen, hole));
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(covariant _RevealPainter old) =>
      old.progress != progress || old.image != image || old.origin != origin;
}
