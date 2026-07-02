import 'package:kumaanime/core/security/securityBindings.dart';

class AntiDebugCheck {
  static bool verify() {
    try {
      return SecurityBindings.antiDebug() == 0;
    } catch (_) {
      return false;
    }
  }
}
