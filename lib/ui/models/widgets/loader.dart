import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Four dots arranged as a square that spins inward and collapses to a
/// single point, then expands back out. Used as the app-wide loading spinner.
class KumaAnimeLoading extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const KumaAnimeLoading({
    Key? key,
    this.color = Colors.purple,
    this.size = 44.0,
    this.duration = const Duration(milliseconds: 1400),
  }) : super(key: key);

  @override
  _KumaAnimeLoadingState createState() => _KumaAnimeLoadingState();
}

class _KumaAnimeLoadingState extends State<KumaAnimeLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _DotSquarePainter(
              color: widget.color,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _DotSquarePainter extends CustomPainter {
  final Color color;
  final double progress;

  _DotSquarePainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 * 0.82;
    final baseDot = math.min(size.width, size.height) * 0.11;

    // Eased shrink: 1 (square) -> 0 (single point) -> 1
    final t = Curves.easeInOut.transform((1 - math.cos(progress * 2 * math.pi)) / 2);
    final spread = maxRadius * t;
    final rotation = progress * 2 * math.pi;
    final dotRadius = baseDot * (1 + (1 - t) * 0.6);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = math.pi / 4 + i * math.pi / 2 + rotation;
      final pos = Offset(
        center.dx + spread * math.cos(angle),
        center.dy + spread * math.sin(angle),
      );
      canvas.drawCircle(pos, dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(_DotSquarePainter oldDelegate) => oldDelegate.progress != progress;
}
