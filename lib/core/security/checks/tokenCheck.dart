import 'package:kumaanime/core/security/securityBindings.dart';

class TokenCheck {
  static bool verify() {
    try {
      final hwSeed = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFFFFFF;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final token = SecurityBindings.sessionToken(hwSeed, timestamp);
      return SecurityBindings.validateToken(token, hwSeed, timestamp) == 1;
    } catch (_) {
      return false;
    }
  }
}
