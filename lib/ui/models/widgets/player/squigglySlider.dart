import 'dart:math';

import 'package:flutter/material.dart';

enum SeekbarStyle { standard, wavy, thick, circular, simple }

SeekbarStyle seekbarStyleFromString(String? value) {
  switch (value) {
    case 'wavy':
      return SeekbarStyle.wavy;
    case 'thick':
      return SeekbarStyle.thick;
    case 'circular':
      return SeekbarStyle.circular;
    case 'simple':
      return SeekbarStyle.simple;
    default:
      return SeekbarStyle.standard;
  }
}

class StyledSeekBar extends StatefulWidget {
  final SeekbarStyle style;
  final double value;
  final double max;
  final double? secondaryValue;
  final bool isPlaying;
  final bool showThumb;
  final Color activeColor;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  const StyledSeekBar({
    super.key,
    required this.style,
    required this.value,
    required this.max,
    required this.activeColor,
    this.secondaryValue,
    this.isPlaying = true,
    this.showThumb = true,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
  });

  @override
  State<StyledSeekBar> createState() => _StyledSeekBarState();
}

class _StyledSeekBarState extends State<StyledSeekBar> with TickerProviderStateMixin {
  late final AnimationController _phase;
  late final AnimationController _amplitude;
  double? _dragValue;
  double _width = 0;

  bool get _wavy => widget.style == SeekbarStyle.wavy || widget.style == SeekbarStyle.circular;

  @override
  void initState() {
    super.initState();
    _phase = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _amplitude = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: widget.isPlaying ? 1 : 0,
    );
    _amplitude.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) _phase.stop();
    });
    _syncPhase();
  }

  void _syncPhase() {
    if (_wavy && widget.isPlaying) {
      if (!_phase.isAnimating) _phase.repeat();
    } else if (_amplitude.value == 0 && _phase.isAnimating) {
      _phase.stop();
    }
  }

  @override
  void didUpdateWidget(covariant StyledSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      widget.isPlaying ? _amplitude.forward() : _amplitude.reverse();
    }
    _syncPhase();
  }

  @override
  void dispose() {
    _phase.dispose();
    _amplitude.dispose();
    super.dispose();
  }

  double _valueFromDx(double dx) {
    if (_width <= 0 || widget.max <= 0) return 0;
    return (dx / _width).clamp(0.0, 1.0) * widget.max;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) {
            final v = _valueFromDx(d.localPosition.dx);
            setState(() => _dragValue = v);
            widget.onChangeStart?.call(v);
          },
          onHorizontalDragUpdate: (d) {
            final v = _valueFromDx(d.localPosition.dx);
            setState(() => _dragValue = v);
            widget.onChanged?.call(v);
          },
          onHorizontalDragEnd: (d) {
            final v = _dragValue ?? widget.value;
            widget.onChangeEnd?.call(v);
            setState(() => _dragValue = null);
          },
          onTapDown: (d) {
            final v = _valueFromDx(d.localPosition.dx);
            widget.onChangeStart?.call(v);
            widget.onChanged?.call(v);
            widget.onChangeEnd?.call(v);
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_phase, _amplitude]),
            builder: (context, _) {
              return CustomPaint(
                size: const Size(double.infinity, 24),
                painter: _SeekBarPainter(
                  style: widget.style,
                  value: _dragValue ?? widget.value,
                  max: widget.max <= 0 ? 1 : widget.max,
                  buffered: widget.secondaryValue,
                  phase: _phase.value * 2 * pi,
                  amplitude: _wavy ? _amplitude.value * 2.5 : 0,
                  showThumb: widget.showThumb,
                  activeColor: widget.activeColor,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class SeekbarStylePreview extends StatefulWidget {
  final SeekbarStyle style;
  final Color activeColor;

  const SeekbarStylePreview({super.key, required this.style, required this.activeColor});

  @override
  State<SeekbarStylePreview> createState() => _SeekbarStylePreviewState();
}

class _SeekbarStylePreviewState extends State<SeekbarStylePreview> with SingleTickerProviderStateMixin {
  late final AnimationController _phase;

  bool get _wavy => widget.style == SeekbarStyle.wavy || widget.style == SeekbarStyle.circular;

  @override
  void initState() {
    super.initState();
    _phase = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    if (_wavy) _phase.repeat();
  }

  @override
  void dispose() {
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _phase,
      builder: (context, _) => CustomPaint(
        size: const Size(64, 24),
        painter: _SeekBarPainter(
          style: widget.style,
          value: 0.5,
          max: 1,
          buffered: null,
          phase: _phase.value * 2 * pi,
          amplitude: _wavy ? 2.5 : 0,
          showThumb: true,
          activeColor: widget.activeColor,
        ),
      ),
    );
  }
}

class _SeekBarPainter extends CustomPainter {
  final SeekbarStyle style;
  final double value;
  final double max;
  final double? buffered;
  final double phase;
  final double amplitude;
  final bool showThumb;
  final Color activeColor;

  _SeekBarPainter({
    required this.style,
    required this.value,
    required this.max,
    required this.buffered,
    required this.phase,
    required this.amplitude,
    required this.showThumb,
    required this.activeColor,
  });

  double get _trackStroke {
    switch (style) {
      case SeekbarStyle.thick:
        return 12;
      case SeekbarStyle.simple:
        return 3;
      default:
        return 3.5;
    }
  }

  double get _activeStroke {
    switch (style) {
      case SeekbarStyle.wavy:
      case SeekbarStyle.circular:
        return 5;
      case SeekbarStyle.thick:
        return 12;
      case SeekbarStyle.simple:
        return 3;
      case SeekbarStyle.standard:
        return 4;
    }
  }

  double get _inactiveAlpha {
    switch (style) {
      case SeekbarStyle.thick:
        return 0.2;
      case SeekbarStyle.simple:
        return 0.1;
      default:
        return 0.15;
    }
  }

  Color get _activeEffective =>
      style == SeekbarStyle.simple ? activeColor.withValues(alpha: 0.8) : activeColor;

  bool get _hasThumb => style == SeekbarStyle.standard || style == SeekbarStyle.circular;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final width = size.width;
    final valueX = (value / max).clamp(0.0, 1.0) * width;

    canvas.drawLine(
      Offset(valueX, centerY),
      Offset(width, centerY),
      Paint()
        ..color = Colors.white.withValues(alpha: _inactiveAlpha)
        ..strokeWidth = _trackStroke
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    if (buffered != null) {
      final bufferedX = (buffered! / max).clamp(0.0, 1.0) * width;
      if (bufferedX > valueX) {
        canvas.drawLine(
          Offset(valueX, centerY),
          Offset(bufferedX, centerY),
          Paint()
            ..color = Colors.white.withValues(alpha: _inactiveAlpha + 0.15)
            ..strokeWidth = _trackStroke
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
      }
    }

    final activePaint = Paint()
      ..color = _activeEffective
      ..strokeWidth = _activeStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (amplitude >= 0.15 && valueX > 1) {
      const wavelength = 22.0;
      final path = Path()..moveTo(0, centerY);
      for (double x = 0; x <= valueX; x += 2) {
        final y = centerY + amplitude * sin((x / wavelength) * 2 * pi + phase);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, activePaint);
    } else {
      canvas.drawLine(Offset(0, centerY), Offset(valueX, centerY), activePaint);
    }

    if (showThumb && _hasThumb) {
      canvas.drawCircle(Offset(valueX, centerY), 7, Paint()..color = activeColor);
    }
  }

  @override
  bool shouldRepaint(covariant _SeekBarPainter old) {
    return old.value != value ||
        old.phase != phase ||
        old.amplitude != amplitude ||
        old.buffered != buffered ||
        old.max != max ||
        old.style != style ||
        old.activeColor != activeColor;
  }
}
