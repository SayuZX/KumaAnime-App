import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:encrypt/encrypt.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/ui/models/notification.dart';
import 'package:kumaanime/ui/models/snackBar.dart';

class DownloaderHelper {
  static final _idSet = <int>{};

  final NotificationService _notifierService = NotificationService();

  Future<bool> checkAndRequestPermission() async {
    if (Platform.isWindows || Platform.isLinux) return true;

    Permission fileAccessPermission;

    final os = await DeviceInfoPlugin().androidInfo;
    final sdk = os.version.sdkInt;

    if (sdk > 32) {
      fileAccessPermission = Permission.manageExternalStorage;
    } else {
      fileAccessPermission = Permission.storage;
    }

    final status = await fileAccessPermission.status;

    if (status.isPermanentlyDenied) {
      return false;
    }

    if (status.isDenied) {
      showToast("Provide storage access for downloading!");
      return (await fileAccessPermission.request()).isGranted;
    } else {
      return true;
    }
  }

  static int generateId() {
    int id = Random().nextInt(1 << 31);
    while (_idSet.contains(id)) {
      id = Random().nextInt(1 << 31);
    }
    _idSet.add(id);
    return id;
  }

  Future<String> getDownloadsPath() async {
    String defDownloadPath;

    if (currentUserSettings?.downloadPath != null) {
      return currentUserSettings!.downloadPath!;
    } else {
      try {
        defDownloadPath = (await getDownloadsDirectory())!.path;
      } catch (err) {
        defDownloadPath = '${Platform.environment['USERPROFILE']}\\Downloads';
      }
      return Platform.isWindows ? defDownloadPath : '/storage/emulated/0/Download/KumaAnime';
    }
  }

  Future<String> makeDirectory({
    required String fileName,
    required String downloadPath,
    bool isImage = false,
    String? fileExtension,
  }) async {
    final basePath = downloadPath;
    final downPath = Directory(basePath);
    String finalPath;

    fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');

    final ext = fileExtension ?? (isImage ? "png" : "mp4");
    final animeName = fileName.replaceAll(RegExp(r'\s+ep\s*\d+\s*$', caseSensitive: false), '').trim();

    final directory = Directory("${downPath.path}/$animeName");
    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }

    finalPath = '$basePath/$animeName/$fileName.$ext';
    return finalPath;
  }

  Uint8List? encryptionKey;

  Future<Response> downloadSegment(String url, {Map<String, String> customHeaders = const {}}) async {
    try {
      final res = await get(Uri.parse(url), headers: customHeaders);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return res;
      }
      throw Exception("Segment download failed with status code ${res.statusCode}");
    } catch (err) {
      throw Exception("Failed to download segment: $err");
    }
  }

  Uint8List decryptSegment(Uint8List buffer) {
    try {
      final encrypt = Encrypter(AES(Key(encryptionKey!), mode: AESMode.cbc));
      final decryptedBuffer = encrypt.decryptBytes(Encrypted(buffer), iv: IV.fromLength(16));
      return Uint8List.fromList(decryptedBuffer);
    } catch (err) {
      rethrow;
    }
  }

  Future<Response> downloadSegmentWithRetries(
    String url,
    int totalAttempts, {
    Map<String, String> customHeaders = const {},
  }) async {
    int currentAttempt = 0;
    while (currentAttempt < totalAttempts) {
      try {
        currentAttempt++;
        final res = await downloadSegment(url, customHeaders: customHeaders)
            .timeout(const Duration(seconds: 10), onTimeout: () => throw Exception("FAILED DOWNLOAD ATTEMPT"));
        return res;
      } catch (err) {
        if (currentAttempt >= totalAttempts) {
          throw Exception("NUMBER OF DOWNLOAD ATTEMPTS EXCEEDED, KILLING THE DOWNLOAD.");
        }
      }
    }
    throw Exception("Retries exceeded");
  }

  Future<List<String>> getSegments(String url, {Map<String, String> customHeaders = const {}}) async {
    final List<String> segments = [];
    final res = await get(Uri.parse(url), headers: customHeaders);
    final lines = res.body.split('\n');
    for (final line in lines) {
      if (!line.startsWith("#")) {
        if (line.contains("EXT")) continue;

        if (line.endsWith(".m3u8")) {
          return await getSegments(
            line.startsWith("http") ? line : "${makeBaseLink(url)}/$line",
            customHeaders: customHeaders,
          );
        }
        segments.add(line.trim());
      } else {
        if (encryptionKey == null && line.startsWith("#EXT-X-KEY:METHOD=")) {
          final regex = RegExp(r'#EXT-X-KEY:METHOD=([^"]+),URI="([^"]+)"');
          final match = regex.firstMatch(line);
          if (match != null) {
            if (match.group(1) == null || match.group(2) == null) {
              continue;
            }
            String keyLink = match.group(2)!;
            keyLink = keyLink.startsWith("http") ? keyLink : "${makeBaseLink(url)}/$keyLink";
            encryptionKey = (await get(Uri.parse(keyLink), headers: customHeaders)).bodyBytes;
          }
        }
      }
    }
    return segments;
  }

  String makeBaseLink(String uri) {
    final split = uri.split('/');
    split.removeLast();
    return split.join('/');
  }

  Future<String?> getMimeType(String url, Map<String, String> headers) async {
    final client = HttpClient();
    try {
      final request = await client.headUrl(Uri.parse(url));
      headers.forEach((k, v) => request.headers.set(k, v));
      final res = await request.close();
      return res.headers.contentType?.mimeType;
    } finally {
      client.close();
    }
  }

  String? extractExtension(String url) {
    final match = RegExp(r'\.([a-zA-Z0-9]+)(?:\?|#|$)').firstMatch(url);
    if (match == null) return null;

    final ext = match.group(1)?.toLowerCase();
    return ext;
  }

  Future<bool> checkRangeSupport(Uri url, {Map<String, String> customHeaders = const {}}) async {
    final client = HttpClient();
    try {
      final req = await client.headUrl(url);
      customHeaders.forEach((k, v) {
        req.headers.add(k, v, preserveHeaderCase: true);
      });
      final res = await req.close();
      client.close();
      return res.headers.value('accept-ranges')?.toLowerCase() == "bytes";
    } catch (err) {
      client.close();
      return false;
    }
  }

  void sendProgressNotif(int id, int progress, String fileName, String downloadPath) {
    _notifierService.updateNotificationProgressBar(
      id: id,
      currentStep: progress,
      maxStep: 100,
      fileName: fileName,
      path: downloadPath,
    );
  }

  void sendCancelledNotif(int id, {bool failed = false}) {
    _notifierService.pushBasicNotification(
      id,
      "Download ${failed ? 'Failed' : 'Cancelled'}",
      "Download ${failed ? "failed due to an error. Check logs for details" : "was cancelled"}",
    );
  }

  void sendCompletedNotif(int id, String fileName, String downloadPath) {
    _notifierService.downloadCompletionNotification(id: id, fileName: fileName, path: downloadPath);
  }
}
