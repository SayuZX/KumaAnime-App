import 'dart:ui';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/ui/models/widgets/floatyBar/controller.dart';
import 'package:flutter/material.dart';

class LiquidGlassNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const LiquidGlassNavItem({required this.icon, IconData? activeIcon, required this.label})
      : activeIcon = activeIcon ?? icon;
}

/// Frosted liquid-glass pill navigation bar with a sliding capsule indicator,
/// ported from OpenTune's FloatingNavigationToolbar.
class LiquidGlassNavBar extends StatefulWidget {
  final List<LiquidGlassNavItem> items;
  final FloatyBottomBarController controller;
  final double blurSigma;

  const LiquidGlassNavBar({
    super.key,
    required this.items,
    required this.controller,
    this.blurSigma = 24,
  });

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar> {
  late final List<GlobalKey> _itemKeys;
  final _stackKey = GlobalKey();
  Rect? _pillRect;

  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(widget.items.length, (_) => GlobalKey());
    widget.controller.currentIndexNotifier.addListener(_onIndexChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measurePill());
  }

  @override
  void dispose() {
    widget.controller.currentIndexNotifier.removeListener(_onIndexChanged);
    super.dispose();
  }

  void _onIndexChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _measurePill());
  }

  void _measurePill() {
    if (!mounted) return;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final itemBox = _itemKeys[widget.controller.currentIndex].currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || itemBox == null) return;
    final topLeft = itemBox.localToGlobal(Offset.zero, ancestor: stackBox);
    final rect = topLeft & itemBox.size;
    if (rect != _pillRect) setState(() => _pillRect = rect);
  }

  bool get _isDark => currentUserSettings?.darkMode ?? true;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final blur = widget.blurSigma.clamp(0.0, 40.0);
    final glassColor = appTheme.backgroundSubColor.withValues(alpha: blur > 0 ? (_isDark ? 0.55 : 0.6) : 0.96);

    final bar = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: _isDark ? 0.08 : 0.35), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: _isDark ? 0.06 : 0.25),
            Colors.transparent,
          ],
        ),
        color: glassColor,
      ),
      padding: const EdgeInsets.all(6),
      child: Stack(
        key: _stackKey,
        children: [
          if (_pillRect != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              left: _pillRect!.left,
              top: _pillRect!.top,
              width: _pillRect!.width,
              height: _pillRect!.height,
              child: Container(
                decoration: BoxDecoration(
                  color: appTheme.accentColor,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.items.length, (index) {
              return _NavItem(
                key: _itemKeys[index],
                item: widget.items[index],
                selected: widget.controller.currentIndex == index,
                onTap: () => widget.controller.currentIndex = index,
              );
            }),
          ),
        ],
      ),
    );

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomInset + 14,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: blur > 0
                ? BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: bar,
                  )
                : bar,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final LiquidGlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({super.key, required this.item, required this.selected, required this.onTap});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? appTheme.onAccent : appTheme.textMainColor.withValues(alpha: 0.82);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.91 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: widget.selected ? 16 : 12, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: widget.selected ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Icon(
                  widget.selected ? widget.item.activeIcon : widget.item.icon,
                  color: color,
                  size: 23,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                child: widget.selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          widget.item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
