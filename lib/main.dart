import 'dart:async';
import 'dart:io';

import 'package:kumaanime/core/app/values.dart';
import 'package:app_links/app_links.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'package:kumaanime/core/anime/providers/animeonsen.dart';
import 'package:kumaanime/core/app/dohResolver.dart';
import 'package:kumaanime/core/app/logging.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/app/version.dart';
import 'package:kumaanime/core/data/preferences.dart';
import 'package:kumaanime/core/data/settings.dart';
import 'package:kumaanime/core/data/theme.dart';
import 'package:kumaanime/core/security/securityInit.dart';
import 'package:kumaanime/core/social/socialService.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/notification.dart';
import 'package:kumaanime/ui/models/widgets/kumaSecureWidget.dart';
import 'package:kumaanime/ui/models/providers/appProvider.dart';
import 'package:kumaanime/ui/models/providers/mainNavProvider.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/sources.dart';
import 'package:kumaanime/ui/models/widgets/appWrapper.dart';
import 'package:kumaanime/ui/pages/info.dart';
import 'package:kumaanime/ui/pages/mainNav.dart';
import 'package:kumaanime/ui/theme/lime.dart';
import 'package:kumaanime/ui/theme/themes.dart';
import 'package:kumaanime/ui/theme/types.dart';
import 'package:fvp/fvp.dart' as fvp;

class _HttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context)..userAgent = AppValues.defaultClientUserAgent;
    client.connectionFactory = (uri, proxyHost, proxyPort) {
      if (proxyHost != null) return Socket.startConnect(proxyHost, proxyPort ?? uri.port);
      final dns = currentUserSettings?.dnsProvider ?? 'auto';
      if (dns == 'off') return Socket.startConnect(uri.host, uri.port);
      return DohResolver.resolve(uri.host, provider: dns).then((ip) => Socket.startConnect(ip ?? uri.host, uri.port));
    };
    return client;
  }
}

void main(List<String> args) async {
  try {
    if (runWebViewTitleBarWidget(args)) {
      return;
    }

    WidgetsFlutterBinding.ensureInitialized();

    await SecurityInit.initialize();

    // Initialise app version instance
    AppVersion.init();

    await Hive.initFlutter(!Platform.isAndroid ? "kumaanime" : null);

    await loadAndAssignSettings();

    if (Platform.isAndroid) await SocialService.instance.init();

    if (!Platform.isAndroid) {
      fvp.registerWith();
    }

    if (Platform.isWindows || Platform.isLinux) {
      await windowManager.ensureInitialized();
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);

      // No frameless for now!
      // if (currentUserSettings?.useFramelessWindow ?? true) await windowManager.setAsFrameless();

      await windowManager.setResizable(true);
    }

    AnimeOnsen().checkAndUpdateToken();

    NotificationService().init();

    /// Load sources. we adding inbuilt sources till migrated
    final sm = SourceManager.instance;

    sm
      ..addSources(sm.inbuiltSources)
      ..loadProviders(clearBeforeLoading: false);

    HttpOverrides.global = _HttpOverrides();

    // await dotenv.load(fileName: ".env");

    // if (currentUserSettings?.enableDiscordPresence ?? false) {
    //   await FlutterDiscordRPC.initialize("1362858832266657812");
    // }

    // FlutterError.onError = (FlutterErrorDetails details) async {
    //   FlutterError.presentError(details);

    //   // force add these error to logs
    //   Logs.app.log(details.exceptionAsString() + "\n${details.stack.toString()}", addToBuffer: true);
    //   await Logs.writeAllLogs();

    //   print("[ERROR] logged the error to logs folder");
    // };

    runApp(
      ChangeNotifierProvider(
        create: (context) => AppProvider(),
        child: const KumaSecureWidget(child: KumaAnime()),
      ),
    );
  } catch (err) {
    // These are critical errors, so we force log them
    Logs.app.log(err.toString(), addToBuffer: true);
    Logs.app.log("state: Crashed", addToBuffer: true);
    await Logs.writeAllLogs();

    print("[CRASH] logged the error to logs folder");
    rethrow;
  }
}

Future<void> loadAndAssignSettings() async {
  await Settings().getSettings().then((settings) => {
        currentUserSettings = settings,
        Logs.app.log("[STARTUP] Loaded user settings"),
      });

  await UserPreferences.getUserPreferences().then((pref) {
    userPreferences = pref;
    Logs.app.log("[STARTUP] Loaded user preferences");
  });

  //load and apply theme
  await getTheme().then((themeId) {
    // ignore the themeid limit checks for debug mode
    if ((themeId > availableThemes.length && !kDebugMode) || themeId < 1) {
      Logs.app.log("[STARTUP] Failed to apply theme with ID $themeId, Applying default theme");
      showToast("Failed to apply theme. Using default theme");
      setTheme(01);
      themeId = 01;
    }

    final darkMode = currentUserSettings!.darkMode!;

    ThemeItem? theme = availableThemes.where((theme) => theme.id == themeId).toList().firstOrNull;

    if (theme == null) {
      // Set default theme incase of any corruptions/issues n stuff
      theme = LimeZest();
      Logs.app.log("[STARTUP] Failed to apply theme with ID $themeId, Applying default theme");
    }

    if (darkMode) {
      appTheme = theme.theme;
      appTheme.backgroundColor =
          (currentUserSettings!.amoledBackground ?? false) ? Colors.black : theme.theme.backgroundColor;
    } else {
      appTheme = KumaAnimeTheme(
        accentColor: Color.alphaBlend(Colors.black.withValues(alpha: 0.16), theme.lightVariant.accentColor),
        textMainColor: lightModeValues.textMainColor,
        textSubColor: lightModeValues.textSubColor,
        backgroundColor: lightModeValues.backgroundColor,
        backgroundSubColor: lightModeValues.backgroundSubColor,
        modalSheetBackgroundColor: lightModeValues.modalSheetBackgroundColor,
        onAccent: theme.lightVariant.onAccent,
      );
    }

    final accentOverride = currentUserSettings?.accentColorValue;
    if (accentOverride != null) appTheme.accentColor = Color(accentOverride);

    Logs.app.log("[STARTUP] Loaded theme of ID $themeId (${theme.name})");
  });
}

class KumaAnime extends StatefulWidget {
  const KumaAnime({super.key});

  static final GlobalKey<ScaffoldMessengerState> snackbarKey = GlobalKey<ScaffoldMessengerState>();

  static final navigatorKey = GlobalKey<NavigatorState>();
  @override
  State<KumaAnime> createState() => _KumaAnimeState();
}

class _KumaAnimeState extends State<KumaAnime> {
  StreamSubscription<Uri>? _sub;
  late AppLinks _appLinks;

  @override
  void initState() {
    listenDeepLinkCall();

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod,
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    // if (currentUserSettings?.enableDiscordPresence ?? false)
    // FlutterDiscordRPC.instance.connect(autoRetry: true, retryDelay: Duration(seconds: 10));

    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();

    // if (currentUserSettings?.enableDiscordPresence ?? false) {
    //   FlutterDiscordRPC.instance.clearActivity();
    //   FlutterDiscordRPC.instance.disconnect();
    //   FlutterDiscordRPC.instance.dispose();
    // }
    super.dispose();
  }

  void listenDeepLinkCall() {
    _appLinks = AppLinks();
    _sub = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == "kumaanime") {
        Logs.app.log("Invoked DeepLink uri: ${uri.toString()}");
        String host = uri.host;
        switch (host) {
          case "info":
            {
              final id = int.tryParse(uri.queryParameters['id'] ?? "nothing");
              if (id != null) {
                KumaAnime.navigatorKey.currentState?.push(
                      MaterialPageRoute(
                        builder: (context) => AppWrapper(
                          firstPage: Info(id: id),
                        ),
                      ),
                    ) ??
                    print("Nah");
                break;
              }
            }
          default:
            floatingSnackBar("BAD-DEEPLINK: Host $host not recognized!");
        }
      }
    });
  }

  // This widget is the root of *my* application.
  @override
  Widget build(BuildContext context) {
    final isDarkMode = currentUserSettings?.darkMode ?? true;
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: appTheme.backgroundColor,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: appTheme.backgroundColor,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: DynamicColorBuilder(
        builder: (lightScheme, darkScheme) {
          late KumaAnimeTheme scheme;

          //just checks for dark mode and sets the appTheme variable with suitable theme
          if (currentUserSettings?.darkMode ?? true) {
            scheme = KumaAnimeTheme(
              accentColor: darkScheme?.primary ?? appTheme.accentColor,
              backgroundColor: (currentUserSettings?.amoledBackground ?? false)
                  ? Colors.black
                  : darkScheme?.surface ?? appTheme.backgroundColor,
              backgroundSubColor: darkScheme?.secondaryContainer ?? appTheme.backgroundSubColor,
              textMainColor: darkScheme?.onSurface ?? appTheme.textMainColor,
              textSubColor: darkScheme?.onSurfaceVariant ?? appTheme.textSubColor,
              modalSheetBackgroundColor: darkScheme?.surface ?? appTheme.modalSheetBackgroundColor,
              onAccent: darkScheme?.onPrimary ?? appTheme.onAccent,
            );
          } else {
            scheme = KumaAnimeTheme(
              accentColor: lightScheme?.primary ?? appTheme.accentColor,
              backgroundColor: lightScheme?.surface ?? appTheme.accentColor,
              backgroundSubColor: lightScheme?.secondaryContainer ?? appTheme.backgroundSubColor,
              textMainColor: lightScheme?.onSurface ?? appTheme.textMainColor,
              textSubColor: lightScheme?.onSurfaceVariant ?? appTheme.textSubColor,
              modalSheetBackgroundColor: lightScheme?.surface ?? appTheme.modalSheetBackgroundColor,
              onAccent: lightScheme?.onPrimary ?? appTheme.onAccent,
            );
          }

          if (currentUserSettings?.materialTheme ?? false) {
            appTheme = scheme;
            // print("[THEME] Applying Material You Theme");
          } else {
            // lmao we can make it follow material theme XD
            // final t = ThemeData.from(
            //   colorScheme: ColorScheme.fromSeed(
            //       seedColor: appTheme.accentColor,
            //       brightness: (currentUserSettings?.darkMode ?? true) ? Brightness.dark : Brightness.light),
            // ).colorScheme;
            // appTheme = KumaAnimeTheme(
            //   accentColor: t.primary,
            //   backgroundColor: t.surface,
            //   backgroundSubColor: t.secondaryContainer,
            //   textMainColor: t.onSurface,
            //   textSubColor: t.outline,
            //   modalSheetBackgroundColor: t.surface,
            //   onAccent: t.onPrimary,
            // );
          }

          final themeProvider = Provider.of<AppProvider>(context);

          return MaterialApp(
            title: 'Kuma Anime',
            navigatorKey: KumaAnime.navigatorKey,
            scaffoldMessengerKey: KumaAnime.snackbarKey,
            locale: Locale(currentUserSettings?.locale ?? 'en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: ThemeData(
                useMaterial3: true,
                brightness: themeProvider.isDark ? Brightness.dark : Brightness.light,
                fontFamily: currentUserSettings?.fontFamily ?? "NotoSans",
                textTheme: Theme.of(context)
                    .textTheme
                    .apply(bodyColor: appTheme.textMainColor, fontFamily: currentUserSettings?.fontFamily ?? "NotoSans"),
                scaffoldBackgroundColor: appTheme.backgroundColor,
                bottomSheetTheme: BottomSheetThemeData(backgroundColor: appTheme.modalSheetBackgroundColor),
                colorScheme: ColorScheme.fromSeed(
                  brightness: themeProvider.isDark ? Brightness.dark : Brightness.light,
                  seedColor: (currentUserSettings?.materialTheme ?? false) ? scheme.accentColor : appTheme.accentColor,
                ),
                iconTheme: IconThemeData(color: appTheme.textMainColor)),
            builder: (context, child) {
              final scale = (currentUserSettings?.textScale ?? 1.0).clamp(0.8, 1.4);
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              );
            },
            home: ChangeNotifierProvider(
              create: (context) => MainNavProvider(),
              child: Platform.isWindows || Platform.isLinux ? AppWrapper(firstPage: MainNavigator()) : MainNavigator(),
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
