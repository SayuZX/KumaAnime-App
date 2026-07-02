

import 'package:kumaanime/ui/theme/types.dart';
import 'package:flutter/material.dart';

class CozyKoala implements ThemeItem {
  @override
  int get id => 11;

  @override
  bool get dev => true;

  @override
  KumaAnimeTheme get lightVariant => KumaAnimeTheme(
        accentColor: Color(0xFF6EADBC),
        backgroundColor: Color(0xFFF1F7D4),
        backgroundSubColor: Color(0xFF9FCBAD),
        textMainColor: Color(0xFF4A4466),
        textSubColor: Color(0xFF666666),
        modalSheetBackgroundColor: Color(0xFFF1F7D4),
        onAccent: Color(0xFF4A4466),
      );

  @override KumaAnimeTheme get theme => KumaAnimeTheme(
        accentColor: Color(0xFF6EADBC),
        backgroundColor: Color.fromARGB(255, 49, 47, 61),
        backgroundSubColor: Color.fromARGB(255, 101, 129, 110),
        textMainColor: Color(0xFFF1F7D4),
        textSubColor: Color.fromARGB(255, 245, 231, 240),
        modalSheetBackgroundColor: Color.fromARGB(255, 49, 47, 61),
        onAccent: Color.fromARGB(255, 49, 47, 61),
      );

  @override
  String get name => "Cozy Koala";
  
  
}