import 'dart:async';

import 'package:kumaanime/core/anime/downloader/downloaders/imageDownloader.dart';
import 'package:kumaanime/core/anime/downloader/downloaders/mockDownloader.dart';
import 'package:kumaanime/core/anime/downloader/downloaders/streamDownloader.dart';
import 'package:kumaanime/core/anime/downloader/downloaders/videoDownloader.dart';
import 'package:kumaanime/core/anime/downloader/types.dart';

class DownloaderCore {
  static Future<void> downloadStream(DownloadTaskIsolate task) => StreamDownloader(task).download();
  static Future<void> downloadVideo(DownloadTaskIsolate task) => VideoDownloader(task).download();
  static Future<void> downloadImage(DownloadTaskIsolate task) => ImageDownloader(task).download();
  static Future<void> downloadMock(DownloadTaskIsolate task) => MockDownloader(task).download();
}
