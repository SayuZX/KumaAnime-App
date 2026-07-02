import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/core/database/anilist/types.dart';
import 'package:kumaanime/ui/theme/types.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

//saved anilist data
UserModal? storedUserData;

//saved settings
SettingsModal? currentUserSettings;

//user prefs
UserPreferencesModal? userPreferences;

//saved theme
late KumaAnimeTheme appTheme;

late String animeOnsenToken;