import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import 'package:kumaanime/core/anime/downloader/downloaders/baseDownloader.dart';
import 'package:kumaanime/core/anime/downloader/types.dart';

class StreamDownloader extends BaseDownloader {
  StreamDownloader(DownloadTaskIsolate task) : super(task);

  IOSink? _outSink;
  Client? _client;

  Future<Response> _downloadSegmentWithClient(
    Client client,
    String url, {
    Map<String, String> customHeaders = const {},
  }) async {
    final response = await client.get(Uri.parse(url), headers: customHeaders);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    throw Exception("HTTP Status ${response.statusCode} for segment");
  }

  Future<Response> _downloadSegmentWithRetries(
    Client client,
    String url,
    int totalAttempts, {
    Map<String, String> customHeaders = const {},
  }) async {
    int currentAttempt = 0;
    while (currentAttempt < totalAttempts) {
      try {
        currentAttempt++;
        final res = await _downloadSegmentWithClient(client, url,
                customHeaders: customHeaders)
            .timeout(const Duration(seconds: 12));
        return res;
      } catch (err) {
        if (currentAttempt >= totalAttempts) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: currentAttempt * 2));
      }
    }
    throw Exception("Max retries exceeded");
  }

  Future<List<String>> _getSegmentsWithClient(
    Client client,
    String url, {
    Map<String, String> customHeaders = const {},
  }) async {
    final List<String> segments = [];
    final res = await client.get(Uri.parse(url), headers: customHeaders);
    final lines = res.body.split('\n');
    for (final line in lines) {
      if (!line.startsWith("#")) {
        if (line.contains("EXT")) continue;
        if (line.endsWith(".m3u8")) {
          final subUrl = line.startsWith("http")
              ? line
              : helper.makeBaseLink(url) + "/$line";
          return await _getSegmentsWithClient(client, subUrl,
              customHeaders: customHeaders);
        }
        segments.add(line.trim());
      } else {
        if (helper.encryptionKey == null &&
            line.startsWith("#EXT-X-KEY:METHOD=")) {
          final regex = RegExp(r'#EXT-X-KEY:METHOD=([^"]+),URI="([^"]+)"');
          final match = regex.firstMatch(line);
          if (match != null) {
            if (match.group(1) == null || match.group(2) == null) {
              continue;
            }
            String keyLink = match.group(2)!;
            keyLink = keyLink.startsWith("http")
                ? keyLink
                : helper.makeBaseLink(url) + "/$keyLink";
            final keyRes =
                await client.get(Uri.parse(keyLink), headers: customHeaders);
            helper.encryptionKey = keyRes.bodyBytes;
          }
        }
      }
    }
    return segments;
  }

  @override
  Future<void> download() async {
    await super.setUpPorts(task);

    final finalPath = await helper.makeDirectory(
      fileName: task.fileName,
      fileExtension: "mp4",
      downloadPath: task.downloadPath,
    );

    if (task.subsUrl != null) {
      await downloadSubs(task.subsUrl!, task.fileName, finalPath);
    }

    var currentUrl = task.url;
    var currentHeaders = Map<String, String>.from(task.customHeaders);
    final fallbackQueue = List<String>.from(task.fallbackUrls);
    final fallbackHeadersQueue =
        List<Map<String, String>>.from(task.fallbackHeaders);

    _client = Client();
    bool downloadSuccess = false;
    String lastError = "";

    while (!downloadSuccess && status != DownloadStatus.cancelled) {
      final output = File(finalPath);
      final resumeIndex = task.resumeFrom;

      _outSink = await output.openWrite(
          mode: resumeIndex == 0 ? FileMode.write : FileMode.append);

      try {
        if (kDebugMode) {
          print("[Downloader Debug] Parsing HLS playlist from: $currentUrl");
        }

        final List<String> segments = await _getSegmentsWithClient(
            _client!, currentUrl,
            customHeaders: currentHeaders);
        final Map<int, String> segmentsFiltered = {};

        for (int i = 0; i < segments.length; i++) {
          if (segments[i].isNotEmpty) {
            segmentsFiltered[i] = segments[i];
          }
        }

        final entries = segmentsFiltered.entries.toList();
        final parallelDownloadsBatchSize = task.parallelBatches;

        int totalBytesDownloaded = 0;
        int speedBytes = 0;
        DateTime speedStart = DateTime.now();

        int lastUpdatedProgress = 0;
        int lastDownloadedSegmentIndex = resumeIndex;

        final streamBaseLink = helper.makeBaseLink(currentUrl);

        for (int i = resumeIndex;
            i < entries.length;
            i += parallelDownloadsBatchSize) {
          if (status == DownloadStatus.cancelled) {
            break;
          }

          if (status == DownloadStatus.paused) {
            if (completer != null && !completer!.isCompleted) {
              return;
            }
            setPausedStatus(
                lastUpdatedProgress, lastDownloadedSegmentIndex, finalPath);
            completer = Completer();
            try {
              timer = Timer(const Duration(minutes: 1),
                  () => completer!.completeError(Exception("Pause timeout")));
              await completer!.future;
              completer = null;
              timer?.cancel();
              timer = null;
            } catch (err) {
              timer?.cancel();
              timer = null;
              completer = null;
              task.sendPort?.send(
                  DownloadMessage(status: 'isolate_timeout', id: task.id));
              break;
            }
          }

          final batchEnd = (i + parallelDownloadsBatchSize < entries.length)
              ? i + parallelDownloadsBatchSize
              : entries.length;

          final batch = entries.sublist(i, batchEnd);
          final List<BufferItem> buffers = [];

          if (kDebugMode) {
            print(
                "[Downloader Debug] Fetching segments [$i-$batchEnd of ${entries.length}]");
          }

          final futures = batch.map((entry) async {
            final segment = entry.value;
            final segmentNumber = entry.key + 1;
            final uri = segment.startsWith('http')
                ? segment
                : "$streamBaseLink/$segment";

            final res = await _downloadSegmentWithRetries(
              _client!,
              uri,
              task.retryAttempts,
              customHeaders: currentHeaders,
            );

            if (status == DownloadStatus.cancelled) {
              return;
            }

            final Uint8List segmentData;
            if (helper.encryptionKey != null) {
              segmentData = helper.decryptSegment(res.bodyBytes);
            } else {
              segmentData = res.bodyBytes;
            }

            buffers.add(BufferItem(index: segmentNumber, buffer: segmentData));
            totalBytesDownloaded += segmentData.length;
            speedBytes += segmentData.length;

            final progress = (segmentNumber * 100 ~/ entries.length);
            final now = DateTime.now();
            final diff = now.difference(speedStart).inMilliseconds;

            if (diff >= 1000) {
              final speed = speedBytes / (diff / 1000.0); // bytes/sec

              // Estimate total size
              final double avgSegmentSize =
                  totalBytesDownloaded / (segmentNumber - resumeIndex);
              final int estimatedTotalSize =
                  (avgSegmentSize * entries.length).toInt();
              final int eta = (speed > 0)
                  ? ((estimatedTotalSize - totalBytesDownloaded) ~/ speed)
                  : -1;

              updateProgress(progress, finalPath,
                  speed: speed, eta: eta, totalSize: estimatedTotalSize);

              speedBytes = 0;
              speedStart = now;
              lastUpdatedProgress = progress;
            }
          });

          await Future.wait(futures);

          if (status == DownloadStatus.cancelled) {
            buffers.clear();
            break;
          }

          buffers.sort((a, b) => a.index.compareTo(b.index));
          for (final b in buffers) {
            _outSink?.add(b.buffer);
          }

          lastDownloadedSegmentIndex = batchEnd;
        }

        if (status == DownloadStatus.cancelled) {
          await _outSink?.close();
          if (output.existsSync()) output.deleteSync();
          setCancelledStatus();
        } else if (status == DownloadStatus.paused) {
          await _outSink?.close();
        } else {
          await _outSink?.close();
          downloadSuccess = true;
          setCompletedStatus(finalPath);
        }
      } catch (err) {
        lastError = err.toString();
        if (kDebugMode) {
          print("[Downloader Debug] HLS download error: $err");
        }

        await _outSink?.close();

        if (fallbackQueue.isNotEmpty && status != DownloadStatus.cancelled) {
          currentUrl = fallbackQueue.removeAt(0);
          currentHeaders = fallbackHeadersQueue.isNotEmpty
              ? Map<String, String>.from(fallbackHeadersQueue.removeAt(0))
              : {};
          task.sendPort?.send(DownloadMessage(
            status: 'fallback_switch',
            id: task.id,
            extras: [currentUrl, currentHeaders],
          ));
          if (kDebugMode) {
            print(
                "[Downloader Debug] Switching to fallback server: $currentUrl");
          }
          await Future.delayed(const Duration(seconds: 2));
        } else {
          if (status != DownloadStatus.cancelled) {
            setFailedStatus(lastError);
          }
          break;
        }
      }
    }

    _client?.close();
  }

  Future<void> downloadSubs(
      String url, String fileName, String downloadPath) async {
    try {
      final folder = File(downloadPath).parent;
      fileName =
          fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '') + " Subtitles";

      final ext = url.split(".").lastOrNull ?? "txt";
      final file = File("${folder.path}/$fileName.$ext");
      final res = await get(Uri.parse(url));
      await file.writeAsString(res.body);
    } catch (_) {}
  }

  @override
  Future<void> onCancel() async {
    _client?.close();
    await _outSink?.close();
  }
}
