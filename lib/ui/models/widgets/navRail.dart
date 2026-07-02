import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/ui/models/widgets/bottomBar.dart';
import 'package:flutter/material.dart';

class KumaAnimeNavDestination {
  final IconData icon;
  final String label;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedIconColor;
  final Color? unselectedIconColor;
  final VoidCallback? onClick;

  const KumaAnimeNavDestination({
    required this.icon,
    required this.label,
    this.selectedColor,
    this.unselectedColor,
    this.selectedIconColor,
    this.unselectedIconColor,
    this.onClick,
  });
}

class KumaAnimeNavRail extends StatefulWidget {
  final List<KumaAnimeNavDestination> destinations;
  final KumaAnimeBottomBarController controller;
  final int initialIndex;
  final bool shouldExpand;
  final bool autoCollapse;
  const KumaAnimeNavRail({
    super.key,
    required this.destinations,
    required this.controller,
    required this.initialIndex,
    this.shouldExpand = false, // Expanded mode
    this.autoCollapse = true, // Collapse under split width (1200)
  });

  @override
  State<KumaAnimeNavRail> createState() => _KumaAnimeNavRailState();
}

class _KumaAnimeNavRailState extends State<KumaAnimeNavRail> {
  @override
  void initState() {
    super.initState();
    widget.controller.currentIndex = widget.initialIndex;
  }

  final Set<int> hoveredIndices = {};

  @override
  Widget build(BuildContext context) {
    final shouldCollapse = (MediaQuery.sizeOf(context).width < 1200) && widget.autoCollapse;

    //
    final double width = shouldCollapse || !widget.shouldExpand ? 60 : MediaQuery.sizeOf(context).width;
    return Container(
      margin: shouldCollapse ? null : EdgeInsets.only(left: 8),
      width: width,
      constraints: BoxConstraints(minWidth: 60, maxWidth: 220),
      child: ValueListenableBuilder(
          valueListenable: widget.controller.currentIndexNotifier,
          builder: (context, currentIndex, child) {
            return ListView.builder(
                itemCount: widget.destinations.length,
                itemBuilder: (context, index) {
                  final item = widget.destinations[index];
                  final controller = widget.controller;
                  final isNonNavButton = controller.nonViewIndices.contains(index);

                  final hovered = hoveredIndices.contains(index);

                  return MouseRegion(
                    onEnter: (_) => setState(() {
                      hoveredIndices.add(index);
                    }),
                    onExit: (_) => setState(() {
                      hoveredIndices.remove(index);
                    }),
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        if (item.onClick != null)
                          return item.onClick?.call();
                        else if (!isNonNavButton) controller.currentIndex = index;
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: widget.controller.animDuration),
                        height: 50,
                        // width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: currentIndex == index && !isNonNavButton
                              ? (item.selectedColor ?? appTheme.accentColor)
                              : hovered
                                  ? appTheme.backgroundSubColor.withAlpha(150)
                                  : (item.unselectedColor ?? appTheme.backgroundSubColor),
                        ),
                        margin: EdgeInsets.all(5),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: shouldCollapse ? MainAxisAlignment.center : MainAxisAlignment.start,
                            children: [
                              Icon(
                                item.icon,
                                size: 30,
                                color: currentIndex == index && !isNonNavButton
                                    ? (item.selectedIconColor ?? appTheme.onAccent)
                                    : (item.unselectedIconColor ?? appTheme.textMainColor),
                              ),
                              if (!shouldCollapse && widget.shouldExpand)
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    widget.destinations[index].label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: currentIndex == index && !isNonNavButton
                                          ? (item.selectedIconColor ?? appTheme.onAccent)
                                          : (item.unselectedIconColor ?? appTheme.textMainColor),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                });
          }),
    );
  }
}
