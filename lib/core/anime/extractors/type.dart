import 'package:kumaanime/core/anime/providers/types.dart';

abstract class AnimeExtractor {
  Future<List<VideoStream>> extract(String streamUrl);
}
