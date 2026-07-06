import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:kumaanime/core/commons/enums.dart';
import 'package:kumaanime/core/commons/subtitleParsers/subtitleParsers.dart';
import 'package:kumaanime/models/subtitle.dart';
import 'package:kumaanime/ui/models/widgets/subtitles/subtitle.dart' as model;

class SubtitleService {
  final Subtitleparsers _parsers = Subtitleparsers();

  Future<List<model.Subtitle>> loadAndParseSubtitle(SubtitleTrack track, {Map<String, String>? headers}) async {
    String content;

    if (track.url.startsWith("https://mock-subtitle-service.kumaanime.app")) {
      content = _getMockSubtitleContent(track.language, track.format);
    } else {
      try {
        final uri = Uri.parse(track.url);
        final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
        if (response.statusCode >= 200 && response.statusCode <= 299) {
          content = response.body;
        } else {
          throw Exception("Server returned code ${response.statusCode}");
        }
      } on TimeoutException {
        throw Exception("API Timeout - Gagal mengambil subtitle");
      } on Exception catch (e) {
        throw Exception("API Offline atau Gagal mengambil subtitle: $e");
      }
    }

    try {
      final format = SubtitleFormat.fromName(track.format);
      switch (format) {
        case SubtitleFormat.VTT:
          return await _parsers.parseVtt(content);
        case SubtitleFormat.SRT:
          return await _parsers.parseSrt(content);
        case SubtitleFormat.ASS:
        case SubtitleFormat.SSA:
          return await _parsers.parseAss(content);
      }
    } catch (e) {
      throw FormatException("Format subtitle tidak valid atau corrupt: $e");
    }
  }

  String _getMockSubtitleContent(String language, String format) {
    if (format == "vtt") {
      return """WEBVTT

00:00:02.000 --> 00:00:08.000
[$language - VTT] Selamat datang di KumaAnime! Nikmati episode ini.

00:00:10.000 --> 00:00:16.000
[$language - VTT] Fitur Subtitle Eksternal (Beta) berjalan dengan lancar.

00:00:18.000 --> 00:00:24.000
[$language - VTT] Subtitle ini dipisahkan dari video stream dan dimuat via API.

00:00:26.000 --> 00:00:32.000
[$language - VTT] Anda dapat menyesuaikan ukuran, warna, outline, background, dan delay offset di pengaturan.

00:00:35.000 --> 00:00:42.000
[$language - VTT] Terima kasih telah menggunakan KumaAnime!
""";
    } else if (format == "srt") {
      return """1
00:00:02,000 --> 00:00:08,000
[$language - SRT] Selamat datang di KumaAnime! Nikmati episode ini.

2
00:00:10,000 --> 00:00:16,000
[$language - SRT] Fitur Subtitle Eksternal (Beta) berjalan dengan lancar.

3
00:00:18,000 --> 00:00:24,000
[$language - SRT] Subtitle ini dipisahkan dari video stream dan dimuat via API.

4
00:00:26,000 --> 00:00:32,000
[$language - SRT] Anda dapat menyesuaikan ukuran, warna, outline, background, dan delay offset di pengaturan.
""";
    } else if (format == "ass" || format == "ssa") {
      final scriptType = format == "ssa" ? "v4.00" : "v4.00+";
      final stylesHeader = format == "ssa"
          ? "[V4 Styles]\nFormat: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, TertiaryColour, BackColour, Bold, Italic, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, AlphaLevel, Encoding\nStyle: Default,Arial,16,16777215,65535,0,0,-1,0,1,2,2,2,20,20,15,0,1"
          : "[V4+ Styles]\nFormat: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding\nStyle: Default,Arial,16,&Hffffff,&H00ffff,&H000000,&H000000,-1,0,0,0,100,100,0,0,1,2,2,2,20,20,15,1";
      final eventsFormat = format == "ssa"
          ? "Format: Marked, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text"
          : "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text";
      final dialoguePrefix = format == "ssa" ? "Dialogue: Marked=0," : "Dialogue: 0,";

      return """[Script Info]
Title: Mock $language Subtitles
ScriptType: $scriptType
PlayResX: 384
PlayResY: 288

$stylesHeader

[Events]
$eventsFormat
${dialoguePrefix}0:00:02.00,0:00:08.00,Default,,0,0,0,,[$language - ${format.toUpperCase()}] Selamat datang di KumaAnime! Nikmati episode ini.
${dialoguePrefix}0:00:10.00,0:00:16.00,Default,,0,0,0,,[$language - ${format.toUpperCase()}] Fitur Subtitle Eksternal (Beta) berjalan dengan lancar.
${dialoguePrefix}0:00:18.00,0:00:24.00,Default,,0,0,0,,[$language - ${format.toUpperCase()}] Subtitle ini dipisahkan dari video stream dan dimuat via API.
${dialoguePrefix}0:00:26.00,0:00:32.00,Default,,0,0,0,,[$language - ${format.toUpperCase()}] Anda dapat menyesuaikan ukuran, warna, outline, background, dan delay offset di pengaturan.
${dialoguePrefix}0:00:35.00,0:00:42.00,Default,,0,0,0,,[$language - ${format.toUpperCase()}] Terima kasih telah menggunakan KumaAnime!
""";
    }
    return "";
  }
}
