import 'dart:isolate';

import 'package:flutter/foundation.dart';

// some of them here are just for names lol
enum DownloadStatus { downloading, queued, paused, completed, cancelled, failed }

DownloadStatus getDownloadStatus(String status) => switch (status) {
      "downloading" => DownloadStatus.downloading,
      "queued" => DownloadStatus.queued,
      "paused" => DownloadStatus.paused,
      "completed" => DownloadStatus.completed,
      "cancelled" => DownloadStatus.cancelled,
      "failed" => DownloadStatus.failed,
      _ => throw Exception("Unknown DownloadStatus value")
    };

class DownloadItem {
  // The download ID
  final int id;

  // The URL to the media to download (can be stream or video file)
  String url;

  // File name to be saved as
  final String fileName;

  // Custom header for fetching (if any)
  Map<String, String> customHeaders;

  // Subtitle url
  final String? subtitleUrl;

  // Value to resume from after pausing
  int? lastDownloadedPart;

  // Notifier for UI updation
  final ValueNotifier<int> progressNotifier = ValueNotifier(0);

  int get progress => progressNotifier.value;

  set progress(int prg) {
    progressNotifier.value = prg;
  }

  // Again a notifier for status updation on UI
  final ValueNotifier<DownloadStatus> statusNotifier = ValueNotifier(DownloadStatus.queued);

  // The Download status
  DownloadStatus get status => statusNotifier.value;

  set status(DownloadStatus newStatus) {
    statusNotifier.value = newStatus;
  }

  final bool mock;

  // Structured properties for the Download Manager
  final String? animeName;
  final String? episodeTitle;
  final String? resolution;
  final String? serverName;
  final List<String> fallbackUrls;
  final List<Map<String, String>> fallbackHeaders;

  // Real-time speed & ETA & Size
  final ValueNotifier<double> speedNotifier = ValueNotifier(0.0); // bytes/second
  final ValueNotifier<int> etaNotifier = ValueNotifier(-1); // seconds
  final ValueNotifier<int> totalSizeNotifier = ValueNotifier(-1); // total bytes

  double get speed => speedNotifier.value;
  set speed(double val) => speedNotifier.value = val;

  int get eta => etaNotifier.value;
  set eta(int val) => etaNotifier.value = val;

  int get totalSize => totalSizeNotifier.value;
  set totalSize(int val) => totalSizeNotifier.value = val;

  DownloadItem({
    required this.id,
    required this.url,
    required DownloadStatus status,
    required this.fileName,
    this.customHeaders = const {},
    int progress = 0,
    this.subtitleUrl,
    this.lastDownloadedPart,
    this.mock = false,
    this.animeName,
    this.episodeTitle,
    this.resolution,
    this.serverName,
    this.fallbackUrls = const [],
    this.fallbackHeaders = const [],
    int totalSize = -1,
  }) {
    progressNotifier.value = progress;
    statusNotifier.value = status;
    totalSizeNotifier.value = totalSize;
  }

  DownloadItem copyWith({
    int? id,
    DownloadStatus? status,
    String? url,
    String? fileName,
    Map<String, String>? customHeaders,
    String? subtitleUrl,
    String? animeName,
    String? episodeTitle,
    String? resolution,
    String? serverName,
    List<String>? fallbackUrls,
    List<Map<String, String>>? fallbackHeaders,
    int? totalSize,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      status: status ?? this.status,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      customHeaders: customHeaders ?? this.customHeaders,
      subtitleUrl: subtitleUrl ?? this.subtitleUrl,
      animeName: animeName ?? this.animeName,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      resolution: resolution ?? this.resolution,
      serverName: serverName ?? this.serverName,
      fallbackUrls: fallbackUrls ?? this.fallbackUrls,
      fallbackHeaders: fallbackHeaders ?? this.fallbackHeaders,
      totalSize: totalSize ?? this.totalSize,
    );
  }

  @override
  String toString() {
    return 'DownloadItem(id: $id, status: $status, url: $url, fileName: $fileName, customHeaders: $customHeaders, subtitleUrl: $subtitleUrl, animeName: $animeName, episodeTitle: $episodeTitle, resolution: $resolution, serverName: $serverName)';
  }
}

// For isolates
class DownloadTaskIsolate {
  final String url;
  final String fileName;
  final int id;
  final Map<String, String> customHeaders;
  final int retryAttempts;
  final int parallelBatches;
  final String? subsUrl;
  final SendPort? sendPort;
  final int resumeFrom;
  String downloadPath;
  final List<String> fallbackUrls;
  final List<Map<String, String>> fallbackHeaders;

  DownloadTaskIsolate({
    required this.url,
    required this.fileName,
    required this.customHeaders,
    required this.retryAttempts,
    required this.parallelBatches,
    required this.subsUrl,
    required this.sendPort,
    required this.id,
    required this.downloadPath,
    this.resumeFrom = 0, // next segment index if stream, exact progress if mp4
    this.fallbackUrls = const [],
    this.fallbackHeaders = const [],
  });

  @override
  String toString() {
    return 'DownloadTaskIsolate(url: $url, fileName: $fileName, id: $id, customHeaders: $customHeaders, retryAttempts: $retryAttempts, parallelBatches: $parallelBatches, subsUrl: $subsUrl, sendPort: $sendPort, resumeFrom: $resumeFrom, downloadPath: $downloadPath, fallbackUrls: $fallbackUrls)';
  }
}

class DownloadMessage {
  final int progress;
  final String status;
  final int id;
  final String? message;
  final List<Object> extras; // ik, not a good way to do it! might refactor later, lazy rn
  final bool silent;
  final double speed;
  final int eta;
  final int totalSize;

  DownloadMessage({
    required this.status,
    required this.id,
    this.message,
    this.progress = 0,
    this.extras = const [],
    this.silent = false,
    this.speed = 0.0,
    this.eta = -1,
    this.totalSize = -1,
  });
}

class DownloadHistoryItem {
  final int id; // This id is different from DownloadItem.id!!!
  final DownloadStatus status;
  final int timestamp; // Time of save
  final String? filePath; // Saved path
  final String url; // The download url for pauses/failures?
  final Map<String, String>? headers; // custom headers
  final String fileName;
  final int size; // for confirmation of file (incase of resume after app death)
  final int? lastDownloadedPart; // segment or the data byte

  // Structured properties for the Download Manager
  final String? animeName;
  final String? episodeTitle;
  final String? resolution;
  final String? serverName;
  final int? totalSize;
  final List<String> fallbackUrls;
  final List<Map<String, String>> fallbackHeaders;

  DownloadHistoryItem({
    required this.id,
    required this.status,
    required this.timestamp,
    required this.filePath,
    required this.url,
    required this.headers,
    required this.fileName,
    required this.size,
    required this.lastDownloadedPart,
    this.animeName,
    this.episodeTitle,
    this.resolution,
    this.serverName,
    this.totalSize,
    this.fallbackUrls = const [],
    this.fallbackHeaders = const [],
  });

  DownloadHistoryItem copyWith({
    int? id,
    DownloadStatus? status,
    int? timestamp,
    String? filePath,
    String? url,
    Map<String, String>? headers,
    String? fileName,
    int? size,
    int? lastDownloadedPart,
    String? animeName,
    String? episodeTitle,
    String? resolution,
    String? serverName,
    int? totalSize,
    List<String>? fallbackUrls,
    List<Map<String, String>>? fallbackHeaders,
  }) {
    return DownloadHistoryItem(
      id: id ?? this.id,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      filePath: filePath ?? this.filePath,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      fileName: fileName ?? this.fileName,
      size: size ?? this.size,
      lastDownloadedPart: lastDownloadedPart ?? this.lastDownloadedPart,
      animeName: animeName ?? this.animeName,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      resolution: resolution ?? this.resolution,
      serverName: serverName ?? this.serverName,
      totalSize: totalSize ?? this.totalSize,
      fallbackUrls: fallbackUrls ?? this.fallbackUrls,
      fallbackHeaders: fallbackHeaders ?? this.fallbackHeaders,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'status': status.name,
      'timestamp': timestamp,
      'filePath': filePath,
      'url': url,
      'headers': headers,
      'fileName': fileName,
      'size': size,
      'lastDownloadedPart': lastDownloadedPart,
      'animeName': animeName,
      'episodeTitle': episodeTitle,
      'resolution': resolution,
      'serverName': serverName,
      'totalSize': totalSize,
      'fallbackUrls': fallbackUrls,
      'fallbackHeaders': fallbackHeaders,
    };
  }

  factory DownloadHistoryItem.fromMap(Map<String, dynamic> map) {
    return DownloadHistoryItem(
      id: map['id'] as int,
      status: getDownloadStatus(map['status']),
      timestamp: map['timestamp'] as int,
      filePath: map['filePath'] != null ? map['filePath'] as String : null,
      url: map['url'] as String,
      headers: map['headers'] != null ? Map<String, String>.from((Map.castFrom(map['headers']))) : null,
      fileName: map['fileName'] as String,
      size: map['size'] as int,
      lastDownloadedPart: map['lastDownloadedPart'] as int?,
      animeName: map['animeName'] as String?,
      episodeTitle: map['episodeTitle'] as String?,
      resolution: map['resolution'] as String?,
      serverName: map['serverName'] as String?,
      totalSize: map['totalSize'] as int?,
      fallbackUrls: map['fallbackUrls'] != null ? List<String>.from(map['fallbackUrls']) : const [],
      fallbackHeaders: map['fallbackHeaders'] != null
          ? (map['fallbackHeaders'] as List<dynamic>).map((e) => Map<String, String>.from(e)).toList()
          : const [],
    );
  }

  @override
  String toString() {
    return 'DownloadHistoryItem(id: $id, status: $status, timestamp: $timestamp, filePath: $filePath, url: $url, headers: $headers,'
        'fileName: $fileName, size: $size, lastDownloadedPart: $lastDownloadedPart, animeName: $animeName, episodeTitle: $episodeTitle, resolution: $resolution, serverName: $serverName)';
  }
}

class BufferItem {
  final int index;
  final Uint8List buffer;

  BufferItem({required this.index, required this.buffer});
}
