import 'package:kumaanime/ui/theme/types.dart';
import 'package:flutter/material.dart';

class NeonRed implements ThemeItem {
  @override
  int get id => 10;

  @override
  bool get dev => false;

  @override
  KumaAnimeTheme get lightVariant => KumaAnimeTheme(
        accentColor: Color(0xffff4d4d),
        backgroundColor: Color(0xfffdf5f6),
        modalSheetBackgroundColor: Color(0xffffffff),
        backgroundSubColor: Color(0xfff2dede),
        textMainColor: Color(0xff2a0f12),
        textSubColor: Color(0xff7a4a4f),
        onAccent: Colors.white,
      );

  @override
  String get name => "Neon Red";

  @override
  KumaAnimeTheme get theme => KumaAnimeTheme(
        accentColor: Color(0xffff2e2e),
        backgroundColor: Color(0xff17191f),
        modalSheetBackgroundColor: Color(0xff20242b),
        backgroundSubColor: Color.fromARGB(255, 102, 47, 47),
        textMainColor: Color(0xffffffff),
        textSubColor: Color.fromARGB(255, 212, 190, 190),
        onAccent: Colors.white,
      );
}
