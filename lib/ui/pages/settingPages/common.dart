import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/ui/models/widgets/backButton.dart';
import 'package:flutter/material.dart';

Widget topRow(BuildContext context, String title) {
  return Row(
    children: [
      const KumaBackButton(),
      Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 23,
            color: appTheme.textMainColor,
          ),
        ),
      ),
    ],
  );
}

PreferredSizeWidget settingPagesAppBar(BuildContext context) {
  return PreferredSize(
    preferredSize: Size(double.infinity, 70),
    child: Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: MediaQuery.of(context).padding.left + 10,
        right: MediaQuery.of(context).padding.right + 10,
        bottom: 10,
      ),
      child: const KumaBackButton(),
    ),
  );
}

Widget settingPagesTitleHeader(BuildContext context, String title) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(
          // top: 5,
          left: 10,
          right: 10,
          bottom: 10,
        ),
        child: const KumaBackButton(),
      ),
      Container(
        padding: EdgeInsets.only(top: 40, left: 20, bottom: 40),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 40,
            color: appTheme.textMainColor,
          ),
        ),
      ),
    ],
  );
}

TextStyle textStyle() {
  return TextStyle(
    color: appTheme.textMainColor,
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );
}

EdgeInsets pagePadding(BuildContext context, {bool bottom = false}) {
  final paddingQuery = MediaQuery.of(context).padding;
  return EdgeInsets.only(
    top: paddingQuery.top + 10,
    left: paddingQuery.left,
    right: paddingQuery.right,
    bottom: bottom ? paddingQuery.bottom : 0,
  );
}

Widget resetCategoryButton(BuildContext context, String label, VoidCallback onReset) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onReset,
        style: OutlinedButton.styleFrom(
          foregroundColor: appTheme.accentColor,
          side: BorderSide(color: appTheme.accentColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.restart_alt_rounded),
        label: Text(label),
      ),
    ),
  );
}

Widget optionTile({required String label, required bool selected, required VoidCallback onTap, String? description}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(
      color: selected ? appTheme.accentColor : appTheme.backgroundSubColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? appTheme.onAccent : appTheme.textMainColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (description != null)
                    Text(
                      description,
                      style: TextStyle(
                        color: selected ? appTheme.onAccent.withValues(alpha: 0.8) : appTheme.textSubColor,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              if (selected) Icon(Icons.check_rounded, color: appTheme.onAccent),
            ],
          ),
        ),
      ),
    ),
  );
}
