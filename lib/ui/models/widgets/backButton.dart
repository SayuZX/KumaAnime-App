import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:flutter/material.dart';

class KumaBackButton extends StatelessWidget {
  final Color? color;
  final double size;
  final VoidCallback? onTap;

  const KumaBackButton({super.key, this.color, this.size = 24, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap ?? () => Navigator.of(context).maybePop(),
      splashRadius: 22,
      icon: Icon(
        Icons.west_rounded,
        color: color ?? appTheme.textMainColor,
        size: size,
      ),
    );
  }
}
