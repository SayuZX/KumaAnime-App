import 'package:kumaanime/core/security/securityBindings.dart';

class IntegrityCheck {
  static const int expectedChecksum = 0xc313a344;

  static bool verify() {
    try {
      return SecurityBindings.selfChecksum() == expectedChecksum;
    } catch (_) {
      return false;
    }
  }
}
