import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import 'package:kumaanime/core/anime/downloader/downloaders/baseDownloader.dart';
import 'package:kumaanime/core/anime/downloader/types.dart';

class VideoDownloader extends BaseDownloader {
  VideoDownloader(DownloadTaskIsolate task) : super(task);

  IOSink? sink;
  Client? _client;

  Future<StreamedResponse> _sendRequestWithRedirects(
    Client client,
    String method,
    Uri uri,
    Map<String, String> headers,
    int resumeFrom,
  ) async {
    var currentUri = uri;
    var redirectCount = 0;

    while (redirectCount < 5) {
      final request = Request(method, currentUri);
      request.headers.addAll(headers);
      request.followRedirects = false; // Handle manually for logging

      if (resumeFrom > 0) {
        request.headers['Range'] = 'bytes=$resumeFrom-';
      }

      if (kDebugMode) {
        print("[Downloader Debug] ID: ${task.id} | Request: $method $currentUri");
        print("[Downloader Debug] Headers: ${request.headers}");
      }

      final response = await client.send(request);

      if (kDebugMode) {
        print("[Downloader Debug] ID: ${task.id} | Status Code: ${response.statusCode}");
        print("[Downloader Debug] Headers: ${response.headers}");
      }

      if (response.statusCode >= 300 && response.statusCode < 400) {
        final location = response.headers['location'];
        if (location != null && location.isNotEmpty) {
          final targetUri = currentUri.resolve(location);
          if (kDebugMode) {
            print("[Downloader Debug] ID: ${task.id} | Redirected from $currentUri to $targetUri");
          }
          currentUri = targetUri;
          redirectCount++;
          continue;
        }
      }

      return response;
    }

    throw Exception("Too many redirects");
  }

  @override
  Future<void> download() async {
    await setUpPorts(task);

    String? extensionGuess = helper.extractExtension(task.url);
    extensionGuess = ['mp4', 'mkv', 'avi', 'webm', 'flv'].contains(extensionGuess) ? extensionGuess : null;

    final filepath = await helper.makeDirectory(
      fileName: task.fileName,
      fileExtension: extensionGuess,
      downloadPath: task.downloadPath,
    );

    var currentUrl = task.url;
    var currentHeaders = Map<String, String>.from(task.customHeaders);
    final fallbackQueue = List<String>.from(task.fallbackUrls);
    final fallbackHeadersQueue = List<Map<String, String>>.from(task.fallbackHeaders);

    _client = Client();
    bool downloadSuccess = false;
    String lastError = "";

    while (!downloadSuccess && status != DownloadStatus.cancelled) {
      final file = File(filepath);
      int resumePosition = 0;
      if (file.existsSync()) {
        resumePosition = file.lengthSync();
      }

      sink = file.openWrite(mode: resumePosition == 0 ? FileMode.write : FileMode.append);

      try {
        final res = await _sendRequestWithRedirects(
          _client!,
          "GET",
          Uri.parse(currentUrl),
          currentHeaders,
          resumePosition,
        );

        if (res.statusCode == 416) {
          // Range Not Satisfiable: means the file is already fully downloaded or invalid range
          if (kDebugMode) {
            print("[Downloader Debug] Range 416 received. Assuming download complete.");
          }
          await sink!.close();
          downloadSuccess = true;
          setCompletedStatus(filepath);
          break;
        }

        if (!(res.statusCode >= 200 && res.statusCode < 300)) {
          throw Exception("Server returned HTTP ${res.statusCode}");
        }

        // If we requested range but server ignored it (sent 200 instead of 206),
        // we must restart writing from 0 to avoid prepending/corrupting.
        if (resumePosition > 0 && res.statusCode != 206) {
          if (kDebugMode) {
            print("[Downloader Debug] Server returned 200 instead of 206. Overwriting file from scratch.");
          }
          await sink!.close();
          sink = file.openWrite(mode: FileMode.write);
          resumePosition = 0;
        }

        final int totalSize = (res.contentLength ?? -1) + (res.statusCode == 206 ? resumePosition : 0);
        int downloadedBytes = resumePosition;

        int speedBytes = 0;
        DateTime speedStart = DateTime.now();
        int lastProgress = 0;

        final completer = Completer<void>();
        StreamSubscription<List<int>>? subscription;

        subscription = res.stream.listen(
          (chunk) {
            if (status == DownloadStatus.cancelled) {
              subscription?.cancel();
              sink?.close();
              if (file.existsSync()) file.deleteSync();
              completer.complete();
              setCancelledStatus();
              return;
            }

            sink?.add(chunk);
            downloadedBytes += chunk.length;
            speedBytes += chunk.length;

            final now = DateTime.now();
            final diff = now.difference(speedStart).inMilliseconds;
            if (diff >= 1000) {
              final speed = speedBytes / (diff / 1000.0); // bytes/sec
              final eta = (totalSize > 0 && speed > 0) ? ((totalSize - downloadedBytes) / speed).toInt() : -1;
              final progress = (totalSize > 0) ? (downloadedBytes * 100 ~/ totalSize) : 0;

              updateProgress(progress, filepath, speed: speed, eta: eta, totalSize: totalSize);

              speedBytes = 0;
              speedStart = now;
              lastProgress = progress;
            }

            if (status == DownloadStatus.paused) {
              subscription?.pause();
              final progress = (totalSize > 0) ? (downloadedBytes * 100 ~/ totalSize) : 0;
              setPausedStatus(progress, downloadedBytes, filepath);

              super.completer = Completer();
              timer = Timer(const Duration(minutes: 1), () => super.completer?.completeError(Exception("Pause timeout")));
              super.completer!.future.then((_) {
                subscription?.resume();
                super.completer = null;
                timer?.cancel();
                timer = null;
              }).catchError((err) {
                subscription?.cancel();
                super.completer = null;
                timer?.cancel();
                timer = null;
                task.sendPort?.send(DownloadMessage(status: 'isolate_timeout', id: task.id));
              });
            }
          },
          onDone: () async {
            await sink?.close();
            completer.complete();
          },
          onError: (err) async {
            completer.completeError(err);
          },
        );

        await completer.future;
        downloadSuccess = true;
        setCompletedStatus(filepath);

      } catch (err) {
        lastError = err.toString();
        if (kDebugMode) {
          print("[Downloader Debug] Download attempt failed: $err");
        }

        await sink?.close();

        // Fallback to next mirror URL
        if (fallbackQueue.isNotEmpty && status != DownloadStatus.cancelled) {
          currentUrl = fallbackQueue.removeAt(0);
          currentHeaders = fallbackHeadersQueue.isNotEmpty ? Map<String, String>.from(fallbackHeadersQueue.removeAt(0)) : {};
          task.sendPort?.send(DownloadMessage(
            status: 'fallback_switch',
            id: task.id,
            extras: [currentUrl, currentHeaders],
          ));
          if (kDebugMode) {
            print("[Downloader Debug] Switching to fallback server: $currentUrl");
          }
          await Future.delayed(const Duration(seconds: 2));
        } else {
          // If no fallback URLs left or user cancelled, stop
          if (status != DownloadStatus.cancelled) {
            setFailedStatus(lastError);
          }
          break;
        }
      }
    }

    _client?.close();
  }

  @override
  Future<void> onCancel() async {
    _client?.close();
    await sink?.close();
  }
}
