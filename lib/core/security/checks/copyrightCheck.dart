import 'package:kumaanime/core/security/securityBindings.dart';

class CopyrightCheck {
  static const int expectedHash = 0x861d5490;
  static const String owner = "RAIHAN NUGROHO";

  static bool verify() {
    try {
      final hash = SecurityBindings.copyrightHash();
      final text = SecurityBindings.copyright();
      return hash == expectedHash && text.contains(owner);
    } catch (_) {
      return false;
    }
  }
}
