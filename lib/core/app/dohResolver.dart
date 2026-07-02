import 'dart:convert';
import 'dart:io';

class DohResolver {
  static final Map<String, _DnsCacheEntry> _cache = {};
  static const Duration _ttl = Duration(minutes: 10);
  static final RegExp _ipv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');

  static const Map<String, String> providers = {
    'cloudflare': 'https://1.1.1.1/dns-query',
    'google': 'https://8.8.8.8/resolve',
    'quad9': 'https://9.9.9.9/dns-query',
    'adguard': 'https://94.140.14.14/dns-query',
    'opendns': 'https://208.67.222.222/dns-query',
    'dnssb': 'https://185.222.222.222/dns-query',
  };

  static bool _isIp(String host) => _ipv4.hasMatch(host) || host.contains(':');

  static List<String> _endpointsFor(String provider) {
    if (provider == 'auto') {
      return const ['https://1.1.1.1/dns-query', 'https://8.8.8.8/resolve', 'https://9.9.9.9/dns-query'];
    }
    final endpoint = providers[provider];
    return endpoint != null ? [endpoint] : const ['https://1.1.1.1/dns-query'];
  }

  static Future<String?> resolve(String host, {String provider = 'auto'}) async {
    if (host.isEmpty || _isIp(host)) return host;

    final cached = _cache[host];
    if (cached != null && DateTime.now().isBefore(cached.expiry)) return cached.ip;

    String? ip;
    for (final endpoint in _endpointsFor(provider)) {
      ip = await _query(endpoint, host);
      if (ip != null) break;
    }
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
