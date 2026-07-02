import 'package:kumaanime/ui/theme/types.dart';
import 'package:flutter/material.dart';

/// Netflix-inspired dark theme with a teal accent
class Kuma implements ThemeItem {
  @override
  int get id => 12;

  @override
  String get name => "Kuma";

  @override
  bool get dev => false;

  @override
  KumaAnimeTheme get lightVariant => KumaAnimeTheme(
        accentColor: Color(0xff00C897),
        backgroundColor: Colors.white,
        textMainColor: Colors.black,
        textSubColor: Color.fromARGB(255, 82, 82, 82),
        modalSheetBackgroundColor: Colors.white,
        backgroundSubColor: Color.fromARGB(255, 224, 224, 224),
        onAccent: Colors.white,
      );

  @override
  KumaAnimeTheme get theme => KumaAnimeTheme(
        accentColor: Color(0xff00C897),
        backgroundColor: Color(0xff111111),
        backgroundSubColor: Color(0xff222222),
        textMainColor: Colors.white,
        textSubColor: Color(0xffAAAAAA),
        modalSheetBackgroundColor: Color(0xff1A1A1A),
        onAccent: Colors.black,
      );
}
