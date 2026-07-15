import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/ui/models/widgets/floatyBar/controller.dart';

/// Satu item navigasi sidebar Fluent.
class FluentNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FluentNavItem({
    required this.icon,
    IconData? activeIcon,
    required this.label,
  }) : activeIcon = activeIcon ?? icon;
}

/// Sidebar navigasi bergaya Windows 11 Fluent Design.
///
/// Pada lebar layar ≥ [expandBreakpoint] (default 900) sidebar menampilkan
/// icon + label (expanded). Di bawah breakpoint hanya ikon (collapsed) dengan
/// tooltip.
///
/// Digunakan sebagai pengganti NavigationRail pada platform Windows/Linux.
class FluentSideNav extends StatefulWidget {
  final List<FluentNavItem> items;
  final FloatyBottomBarController controller;

  /// Lebar saat expanded (icon + label).
  final double expandedWidth;

  /// Lebar saat collapsed (icon saja).
  final double collapsedWidth;

  /// Breakpoint layar untuk auto-collapse.
  final double expandBreakpoint;

  const FluentSideNav({
    super.key,
    required this.items,
    required this.controller,
    this.expandedWidth = 200,
    this.collapsedWidth = 64,
    this.expandBreakpoint = 900,
  });

  @override
  State<FluentSideNav> createState() => _FluentSideNavState();
}

class _FluentSideNavState extends State<FluentSideNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandAnim;
  late Animation<double> _widthFactor;

  bool _hoverExpand = false; // manual expand saat hover di collapsed mode
  final Set<int> _hoveredItems = {};

  bool get _isDark => currentUserSettings?.darkMode ?? true;

  @override
  void initState() {
    super.initState();
    _expandAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _widthFactor = CurvedAnimation(
      parent: _expandAnim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    widget.controller.currentIndexNotifier.addListener(_onIndexChanged);
  }

  @override
  void dispose() {
    _expandAnim.dispose();
    widget.controller.currentIndexNotifier.removeListener(_onIndexChanged);
    super.dispose();
  }

  void _onIndexChanged() {
    if (mounted) setState(() {});
  }

  bool _isExpanded(double screenWidth) {
    final autoExpand = screenWidth >= widget.expandBreakpoint;
    return autoExpand || _hoverExpand;
  }

  void _onHoverSidebar(bool hovering, bool autoExpanded) {
    if (autoExpanded) return; // sudah expanded, tidak perlu override
    setState(() => _hoverExpand = hovering);
    if (hovering) {
      _expandAnim.forward();
    } else {
      _expandAnim.reverse();
    }
  }

  // ─── Warna Fluent ──────────────────────────────────────────────────────────

  Color get _bgColor => _isDark
      ? appTheme.backgroundColor.withValues(alpha: 0.96)
      : appTheme.backgroundColor.withValues(alpha: 0.97);

  Color get _borderColor => (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);

  Color get _activeColor => appTheme.accentColor;

  Color get _activeIconColor => appTheme.onAccent;

  Color get _inactiveIconColor => appTheme.textMainColor.withValues(alpha: 0.75);

  Color get _hoverColor => (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final autoExpanded = _isExpanded(screenWidth);

    // Lebar sidebar: saat auto-expanded selalu expandedWidth,
    // saat collapsed + hover → animasi dari collapsedWidth ke expandedWidth.
    final targetWidth = autoExpanded
        ? widget.expandedWidth
        : Tween<double>(
            begin: widget.collapsedWidth,
            end: widget.expandedWidth,
          ).evaluate(_widthFactor);

    return MouseRegion(
      onEnter: (_) => _onHoverSidebar(true, autoExpanded),
      onExit: (_) => _onHoverSidebar(false, autoExpanded),
      child: AnimatedBuilder(
        animation: _expandAnim,
        builder: (context, _) {
          final width =
              autoExpanded ? widget.expandedWidth : targetWidth;
          final showLabel = autoExpanded || _hoverExpand;

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: width,
                decoration: BoxDecoration(
                  color: _bgColor,
                  border: Border(
                    right: BorderSide(color: _borderColor, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Logo/Brand area ──────────────────────────────────
                    _buildHeader(showLabel),
                    const SizedBox(height: 8),

                    // ── Nav items ────────────────────────────────────────
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        itemCount: widget.items.length - 1,
                        itemBuilder: (context, index) =>
                            _buildNavItem(index, showLabel),
                      ),
                    ),

                    // ── Bottom divider ───────────────────────────────────
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: _borderColor,
                      indent: 12,
                      endIndent: 12,
                    ),
                    const SizedBox(height: 4),

                    // ── Settings item (pinned at the bottom) ─────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildNavItem(widget.items.length - 1, showLabel),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool showLabel) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'lib/assets/icons/logo_foreground.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: showLabel
                ? Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      'Kuma Anime',
                      style: TextStyle(
                        color: appTheme.textMainColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─── Nav item ──────────────────────────────────────────────────────────────

  Widget _buildNavItem(int index, bool showLabel) {
    final item = widget.items[index];
    final isSelected =
        widget.controller.currentIndex == index;
    final isHovered = _hoveredItems.contains(index);

    Color bgColor;
    if (isSelected) {
      bgColor = _activeColor;
    } else if (isHovered) {
      bgColor = _hoverColor;
    } else {
      bgColor = Colors.transparent;
    }

    Color iconColor =
        isSelected ? _activeIconColor : _inactiveIconColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoveredItems.add(index)),
        onExit: (_) => setState(() => _hoveredItems.remove(index)),
        child: Tooltip(
          message: showLabel ? '' : item.label,
          preferBelow: false,
          verticalOffset: 0,
          decoration: BoxDecoration(
            color: _isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: TextStyle(
            color: appTheme.textMainColor,
            fontSize: 12,
          ),
          child: GestureDetector(
            onTap: () => widget.controller.currentIndex = index,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    // Indicator bar (Fluent active indicator)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 3 : 0,
                      height: isSelected ? 16 : 0,
                      margin: EdgeInsets.only(right: isSelected ? 8 : 0),
                      decoration: BoxDecoration(
                        color: _activeIconColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    // Icon
                    Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: iconColor,
                      size: 20,
                    ),

                    // Label
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: showLabel
                          ? Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: iconColor,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
