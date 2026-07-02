import 'dart:convert';
import 'dart:io';

class DohResolver {
  static final Map<String, _DnsCacheEntry> _cache = {};
  static const Duration _ttl = Duration(minutes: 10);
  static final RegExp _ipv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');

  static bool _isIp(String host) => _ipv4.hasMatch(host) || host.contains(':');

  static Future<String?> resolve(String host) async {
    if (host.isEmpty || _isIp(host)) return host;

    final cached = _cache[host];
    if (cached != null && DateTime.now().isBefore(cached.expiry)) return cached.ip;

    final ip = await _query('https://1.1.1.1/dns-query', host) ?? await _query('https://8.8.8.8/resolve', host);
    if (ip != null) _cache[host] = _DnsCacheEntry(ip, DateTime.now().add(_ttl));
    return ip;
  }

  static Future<String?> _query(String endpoint, String host) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final request = await client.getUrl(Uri.parse('$endpoint?name=${Uri.encodeQueryComponent(host)}&type=A'));
      request.headers.set(HttpHeaders.acceptHeader, 'application/dns-json');
      final response = await request.close().timeout(const Duration(seconds: 6));
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);
      final answers = data['Answer'];
      if (answers is List) {
        for (final answer in answers) {
          if (answer is Map && answer['type'] == 1 && answer['data'] is String) {
            return answer['data'] as String;
          }
        }
      }
    } catch (_) {
    } finally {
      client?.close();
    }
    return null;
  }
}

class _DnsCacheEntry {
  final String ip;
  final DateTime expiry;

  _DnsCacheEntry(this.ip, this.expiry);
}
