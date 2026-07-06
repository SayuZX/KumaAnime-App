class SubtitleTrack {
  final String language;
  final String url;
  final String format;

  const SubtitleTrack({
    required this.language,
    required this.url,
    required this.format,
  });

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'url': url,
      'format': format,
    };
  }

  factory SubtitleTrack.fromMap(Map<String, dynamic> map) {
    return SubtitleTrack(
      language: map['language'] as String,
      url: map['url'] as String,
      format: map['format'] as String,
    );
  }
}
