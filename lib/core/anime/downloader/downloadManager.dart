import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

import 'package:kumaanime/core/commons/enums/hiveEnums.dart';
import 'package:kumaanime/core/anime/downloader/downloader.dart';
import 'package:kumaanime/core/anime/downloader/downloaderHelper.dart';
import 'package:kumaanime/core/anime/downloader/types.dart';
import 'package:kumaanime/core/app/logging.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/data/downloadHistory.dart';
import 'package:kumaanime/ui/models/snackBar.dart';

/// Manages and Keeps track of downloads.
class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  
  DownloadManager._internal() {
    _loadQueueFromDatabase();
  }

  /// The currently downloading items (includes queue)
  static final List<DownloadItem> _downloadingItems = [];

  /// The count for UI updates
  static final ValueNotifier<int> downloadsCount = ValueNotifier(0);

  /// Getter for public usage
  static List<DownloadItem> get downloadingItems => _downloadingItems;

  final Downloader _downloader = Downloader(logger: Logs.downloader);

  Future<void> _loadQueueFromDatabase() async {
    try {
      final boxName = HiveBox.downloadHistory.boxName;
      if (!Hive.isBoxOpen(boxName)) {
        await DownloadHistory.initBox();
      }
      final historyItems = DownloadHistory.getDownloadHistory(status: null);
      for (final item in historyItems) {
        if (item.status != DownloadStatus.completed && item.status != DownloadStatus.cancelled) {
          if (_downloadingItems.any((it) => it.id == item.id)) continue;

          final dlItem = DownloadItem(
            id: item.id,
            url: item.url,
            status: item.status,
            fileName: item.fileName,
            customHeaders: item.headers ?? const {},
            progress: 0,
            lastDownloadedPart: item.lastDownloadedPart,
            animeName: item.animeName,
            episodeTitle: item.episodeTitle,
            resolution: item.resolution,
            serverName: item.serverName,
            fallbackUrls: item.fallbackUrls,
            fallbackHeaders: item.fallbackHeaders,
            totalSize: item.totalSize ?? -1,
          );

          if (item.filePath != null && item.totalSize != null && item.totalSize! > 0) {
            final file = File(item.filePath!);
            if (file.existsSync()) {
              final len = file.lengthSync();
              dlItem.progress = ((len / item.totalSize!) * 100).toInt().clamp(0, 100);
              dlItem.lastDownloadedPart = len;
            }
          }

          _downloadingItems.add(dlItem);
          downloadsCount.value++;
        }
      }
    } catch (_) {}
  }

  /// The queue is managed from [Downloader] class
  static void enqueue(DownloadItem item) {
    if (!_downloadingItems.contains(item)) {
      _downloadingItems.add(item);
      downloadsCount.value++;
    }
    Logs.downloader.log(
        "Added item to queue. Items in queue: ${downloadsCount.value}. [queue mode: ${(currentUserSettings?.useQueuedDownloads ?? false)}]");
  }

  /// The queue is managed from [Downloader] class
  static void dequeue(int id) {
    _downloadingItems.removeWhere((it) => it.id == id);
    downloadsCount.value = _downloadingItems.length;
  }

  /// Adds a new download task to the downloader
  Future<void> addDownloadTask(
    String url,
    String filename, {
    String? subtitleUrl,
    Map<String, String> customHeaders = const {},
    List<String> fallbackUrls = const [],
    List<Map<String, String>> fallbackHeaders = const [],
    bool mock = false,
    String? animeName,
    String? episodeTitle,
    String? resolution,
    String? serverName,
  }) async {
    if (!(await DownloaderHelper().checkAndRequestPermission())) {
      floatingSnackBar("Allow 'All files access' to download files.");
      Logs.downloader.log("Storage permission not granted. Rejecting download request...");
      return;
    }

    final existing = _downloadingItems.firstWhereOrNull((it) => it.fileName == filename);
    if (existing != null) {
      if (existing.status == DownloadStatus.failed || existing.status == DownloadStatus.cancelled) {
        existing.status = DownloadStatus.queued;
        existing.progress = 0;
        await _downloader.startDownload(existing);
      } else {
        floatingSnackBar("This episode is already in the download queue!");
      }
      return;
    }

    final id = DownloaderHelper.generateId();

    final item = DownloadItem(
      id: id,
      url: url,
      status: DownloadStatus.queued,
      fileName: filename,
      customHeaders: customHeaders,
      progress: 0,
      subtitleUrl: subtitleUrl,
      mock: mock,
      animeName: animeName,
      episodeTitle: episodeTitle,
      resolution: resolution,
      serverName: serverName,
      fallbackUrls: fallbackUrls,
      fallbackHeaders: fallbackHeaders,
    );

    await DownloadHistory.saveItem(DownloadHistoryItem(
      id: id,
      status: DownloadStatus.queued,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      filePath: null,
      url: url,
      headers: customHeaders,
      fileName: filename,
      size: 0,
      lastDownloadedPart: null,
      animeName: animeName,
      episodeTitle: episodeTitle,
      resolution: resolution,
      serverName: serverName,
      fallbackUrls: fallbackUrls,
      fallbackHeaders: fallbackHeaders,
    ));

    await _downloader.startDownload(item);
  }

  void cancelDownload(int id) {
    _downloader.requestCancellation(id);
  }

  void pauseDownload(int id) {
    _downloader.requestPause(id);
  }

  void resumeDownload(int id) {
    _downloader.requestResume(id);
  }

  Future<void> retryDownload(int id) async {
    final item = _downloadingItems.firstWhereOrNull((it) => it.id == id);
    if (item != null) {
      item.status = DownloadStatus.queued;
      item.progress = 0;
      await DownloadHistory.saveItem(DownloadHistoryItem(
        id: item.id,
        status: DownloadStatus.queued,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        filePath: null,
        url: item.url,
        headers: item.customHeaders,
        fileName: item.fileName,
        size: 0,
        lastDownloadedPart: null,
        animeName: item.animeName,
        episodeTitle: item.episodeTitle,
        resolution: item.resolution,
        serverName: item.serverName,
        fallbackUrls: item.fallbackUrls,
        fallbackHeaders: item.fallbackHeaders,
      ));
      await _downloader.startDownload(item);
    }
  }
}
