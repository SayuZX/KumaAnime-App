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

/// Frosted liquid-glass pill navigation bar with an animated capsule indicator,
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
  @override
  void initState() {
    super.initState();
    widget.controller.currentIndexNotifier.addListener(_onIndexChanged);
  }

  @override
  void dispose() {
    widget.controller.currentIndexNotifier.removeListener(_onIndexChanged);
    super.dispose();
  }

  void _onIndexChanged() {
    if (mounted) setState(() {});
  }

  bool get _isDark => currentUserSettings?.darkMode ?? true;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final blur = widget.blurSigma.clamp(0.0, 40.0);
    final glassColor = _isDark
        ? appTheme.backgroundSubColor.withValues(alpha: blur > 0 ? 0.55 : 0.96)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.06), appTheme.backgroundSubColor)
            .withValues(alpha: blur > 0 ? 0.85 : 1.0);

    final bar = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.08), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: _isDark ? 0.06 : 0.45),
            Colors.transparent,
          ],
        ),
        color: glassColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(widget.items.length, (index) {
          return _NavItem(
            item: widget.items[index],
            selected: widget.controller.currentIndex == index,
            onTap: () => widget.controller.currentIndex = index,
          );
        }),
      ),
    );

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomInset + 14,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
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
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final LiquidGlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.item, required this.selected, required this.onTap});

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
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: widget.selected ? 16 : 12, vertical: 11),
          decoration: BoxDecoration(
            color: widget.selected ? appTheme.accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
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
                  size: 22,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                child: widget.selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: Text(
                          widget.item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontSize: 12.5,
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
