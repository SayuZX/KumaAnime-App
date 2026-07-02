import 'package:kumaanime/ui/theme/amethyst.dart';
import 'package:kumaanime/ui/theme/coldPurple.dart';
import 'package:kumaanime/ui/theme/hotPink.dart';
import 'package:kumaanime/ui/theme/lime.dart';
import 'package:kumaanime/ui/theme/neonRed.dart';
import 'package:kumaanime/ui/theme/star.dart';
import 'package:kumaanime/ui/theme/mocha.dart';
import 'package:kumaanime/ui/theme/monochrome.dart';
import 'package:kumaanime/ui/theme/neonGreen.dart';
import 'package:kumaanime/ui/theme/sakura.dart';
import 'package:kumaanime/ui/theme/types.dart';
import 'package:kumaanime/ui/theme/cozyKoala.dart';
import 'package:kumaanime/ui/theme/kuma.dart';
import 'package:flutter/material.dart';

/** List of available themes.
 *
The theme list in UI screen is generated from this list */
List<ThemeItem> availableThemes = [
  LimeZest(), // ids are in order 0 -> n
  Monochrome(),
  ColdPurple(),
  HotPink(),
  Amethyst(),
  Mocha(),
  Sakura(),
  NeonGreen(),
  Star(),
  NeonRed(),
  CozyKoala(),
  Kuma(),
];
// Represents a generic light theme (used only for its values)
KumaAnimeTheme lightModeValues = KumaAnimeTheme(
  textMainColor: Color(0xff1A1A1A),
  textSubColor: Color(0xff707070),
  backgroundColor: Color(0xffF0F0F0),
  backgroundSubColor: Colors.white,
  modalSheetBackgroundColor: Colors.white,
  accentColor: Colors.black, // ignore this field
  onAccent: Colors.white
);

// Represents a generic dark theme (used only for its values)
KumaAnimeTheme darkModeValues = KumaAnimeTheme(
  backgroundColor: Color.fromARGB(255, 24, 24, 24),
  backgroundSubColor: const Color.fromARGB(255, 36, 36, 36),
  textMainColor: Colors.white,
  textSubColor: Color.fromARGB(255, 180, 180, 180),
  modalSheetBackgroundColor: Color(0xff121212),
  accentColor: Colors.black, // ignore this field
  onAccent: Colors.white
);
