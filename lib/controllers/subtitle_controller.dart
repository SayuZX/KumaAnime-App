import 'package:flutter/foundation.dart';
import 'package:kumaanime/models/subtitle.dart';
import 'package:kumaanime/services/subtitle_provider.dart';
import 'package:kumaanime/services/subtitle_repository.dart';
import 'package:kumaanime/services/subtitle_service.dart';
import 'package:kumaanime/ui/models/widgets/subtitles/subtitle.dart' as model;

class SubtitleController extends ChangeNotifier {
  final SubtitleRepository _repository = ApiSubtitleRepositoryImpl();
  final SubtitleService _service = SubtitleService();

  List<SubtitleTrack> _availableTracks = [];
  SubtitleTrack? _selectedTrack;
  List<model.Subtitle> _parsedSubtitles = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SubtitleTrack> get availableTracks => _availableTracks;
  SubtitleTrack? get selectedTrack => _selectedTrack;
  List<model.Subtitle> get parsedSubtitles => _parsedSubtitles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSubtitlesForEpisode(int animeId, int episodeNumber, String defaultLang) async {
    _isLoading = true;
    _errorMessage = null;
    _parsedSubtitles = [];
    _selectedTrack = null;
    _availableTracks = [];
    notifyListeners();

    try {
      _availableTracks = await _repository.fetchSubtitleTracks(animeId, episodeNumber);
      if (_availableTracks.isEmpty) {
        _errorMessage = "Subtitle belum tersedia";
        _isLoading = false;
        notifyListeners();
        return;
      }

      final initialTrack = _selectInitialTrack(defaultLang);
      if (initialTrack != null) {
        await _loadAndParseTrack(initialTrack);
      } else {
        _errorMessage = "Subtitle tidak ditemukan untuk bahasa pilihan";
      }
    } catch (e) {
      _errorMessage = "Gagal memuat subtitle: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  SubtitleTrack? _selectInitialTrack(String defaultLang) {
    var track = _findTrackForLanguage(defaultLang);
    if (track != null) return track;

    final fallbackPriorities = ["Indonesia", "Jepang", "English"];
    for (final lang in fallbackPriorities) {
      track = _findTrackForLanguage(lang);
      if (track != null) return track;
    }

    if (_availableTracks.isNotEmpty) {
      return _availableTracks.first;
    }

    return null;
  }

  SubtitleTrack? _findTrackForLanguage(String languageName) {
    final searchName = languageName.toLowerCase();
    for (final track in _availableTracks) {
      final trackLang = track.language.toLowerCase();
      if (trackLang == searchName ||
          (searchName == "id" && trackLang == "indonesia") ||
          (searchName == "ja" && trackLang == "jepang") ||
          (searchName == "en" && trackLang == "english")) {
        return track;
      }
    }
    return null;
  }

  Future<void> _loadAndParseTrack(SubtitleTrack track) async {
    try {
      _parsedSubtitles = await _service.loadAndParseSubtitle(track);
      _selectedTrack = track;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Gagal memuat ${track.language} subtitle, mencoba fallback...";
      
      final fallbacks = _availableTracks.where((t) => t.url != track.url).toList();
      bool loadedFallback = false;
      
      final priorityLangs = ["Indonesia", "Jepang", "English"];
      for (final lang in priorityLangs) {
        final fallbackTrack = fallbacks.where((t) => t.language.toLowerCase() == lang.toLowerCase() || 
            (lang == "Indonesia" && t.language.toLowerCase() == "id") ||
            (lang == "Jepang" && t.language.toLowerCase() == "ja") ||
            (lang == "English" && t.language.toLowerCase() == "en")).firstOrNull;
            
        if (fallbackTrack != null) {
          try {
            _parsedSubtitles = await _service.loadAndParseSubtitle(fallbackTrack);
            _selectedTrack = fallbackTrack;
            _errorMessage = null;
            loadedFallback = true;
            break;
          } catch (_) {
            continue;
          }
        }
      }

      if (!loadedFallback && fallbacks.isNotEmpty) {
        for (final remainingTrack in fallbacks) {
          try {
            _parsedSubtitles = await _service.loadAndParseSubtitle(remainingTrack);
            _selectedTrack = remainingTrack;
            _errorMessage = null;
            loadedFallback = true;
            break;
          } catch (_) {
            continue;
          }
        }
      }

      if (!loadedFallback) {
        _parsedSubtitles = [];
        _selectedTrack = null;
        _errorMessage = "Subtitle tidak tersedia";
      }
    }
  }

  Future<void> changeTrack(SubtitleTrack? track) async {
    if (track == null) {
      _selectedTrack = null;
      _parsedSubtitles = [];
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _parsedSubtitles = await _service.loadAndParseSubtitle(track);
      _selectedTrack = track;
    } catch (e) {
      _errorMessage = "Gagal memuat subtitle ${track.language}: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _availableTracks = [];
    _selectedTrack = null;
    _parsedSubtitles = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
