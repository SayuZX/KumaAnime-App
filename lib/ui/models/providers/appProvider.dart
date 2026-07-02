import 'dart:io';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/theme.dart';
import 'package:kumaanime/ui/theme/themes.dart';
import 'package:kumaanime/ui/theme/types.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

// Handles app wide settings (themes, plugin sources etc..)
class AppProvider with ChangeNotifier {
  KumaAnimeTheme _theme = appTheme;

  bool _isDark = currentUserSettings?.darkMode ?? false;

  KumaAnimeTheme get theme => _theme;

  bool get isDark => _isDark;

  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;

  String _windowTitle = "Kuma Anime";

  String get windowTitle => _windowTitle;

  Color? _titleBarColor = null;

  Color? get titleBarColor => _titleBarColor;

  // For desktops
  bool _showTitleBar = false;

  bool get showTitleBar => _showTitleBar;

  set showTitleBar(bool pip) {
    _showTitleBar = pip;
    notifyListeners();
  }

  set windowTitle(String newTitle) {
    _windowTitle = newTitle;
    notifyListeners();
  }

  set isFullScreen(bool fs) {
    _isFullScreen = fs;
    notifyListeners();
  }

  set theme(KumaAnimeTheme selectedTheme) {
    _theme = selectedTheme;

    final dark = currentUserSettings?.darkMode ?? true;

    appTheme = KumaAnimeTheme(
      accentColor: selectedTheme.accentColor,
      //set background color only if dark theme and amoled bg are true, otherwise set respective theme's default bg
      backgroundColor:
          ((currentUserSettings?.amoledBackground ?? false) && dark) ? Colors.black : selectedTheme.backgroundColor,
      backgroundSubColor: selectedTheme.backgroundSubColor,
      textMainColor: selectedTheme.textMainColor,
      textSubColor: selectedTheme.textSubColor,
      modalSheetBackgroundColor: selectedTheme.modalSheetBackgroundColor,
      onAccent: selectedTheme.onAccent,
    );

    notifyListeners();
  }

  set isDark(bool dark) {
    _isDark = dark;
  }

  /// Set the title bar color (only works on windows)
  /// If null, default system color is used
  void setTitlebarColor(Color? color) {
    _titleBarColor = color;
    notifyListeners();
  }

  void applyTheme(KumaAnimeTheme t) {
    theme = t;
  }

  Future<void> applyThemeMode(bool dark) async {
    isDark = dark;
    final themeId = await getTheme();
    final theme = availableThemes.firstWhere((thm) => thm.id == themeId, orElse: () => availableThemes[0]);

    if (dark) {
      appTheme = KumaAnimeTheme(
        accentColor: theme.theme.accentColor,
        backgroundColor: (currentUserSettings?.amoledBackground ?? false) ? Colors.black : theme.theme.backgroundColor,
        backgroundSubColor: theme.theme.backgroundSubColor,
        textMainColor: theme.theme.textMainColor,
        textSubColor: theme.theme.textSubColor,
        modalSheetBackgroundColor: theme.theme.modalSheetBackgroundColor,
        onAccent: theme.theme.onAccent,
      );
    } else {
      appTheme = KumaAnimeTheme(
        accentColor: Color.alphaBlend(Colors.black.withValues(alpha: 0.16), theme.lightVariant.accentColor),
        backgroundColor: lightModeValues.backgroundColor,
        backgroundSubColor: lightModeValues.backgroundSubColor,
        textMainColor: lightModeValues.textMainColor,
        textSubColor: lightModeValues.textSubColor,
        modalSheetBackgroundColor: lightModeValues.modalSheetBackgroundColor,
        onAccent: theme.lightVariant.onAccent,
      );
    }

    notifyListeners();
  }

  /// Refresh the root Widget tree
  void justRefresh() {
    notifyListeners();
  }

  void applyAccentColor(int? argb) {
    if (argb == null) return;
    appTheme.accentColor = Color(argb);
    notifyListeners();
  }

  /// Set the window mode to fullscreen or windowed
  Future<void> setFullScreen(bool fs) async {
    if (Platform.isAndroid) return;
    await windowManager.setFullScreen(fs);
    isFullScreen = fs;
  }
}
