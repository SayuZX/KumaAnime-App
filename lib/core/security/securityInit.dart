import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kumaanime/core/security/checks/antiDebugCheck.dart';
import 'package:kumaanime/core/security/checks/copyrightCheck.dart';
import 'package:kumaanime/core/security/checks/integrityCheck.dart';
import 'package:kumaanime/core/security/checks/tokenCheck.dart';
import 'package:kumaanime/core/security/securityBindings.dart';

class SecurityInit {
  static final ValueNotifier<bool> verified = ValueNotifier<bool>(false);

  static bool get isVerified => verified.value;

  static Timer? _timer;

  static Future<void> initialize() async {
    if (!Platform.isAndroid) {
      verified.value = true;
      return;
    }

    verified.value = _runChecks();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      final ok = _runChecks();
      if (verified.value != ok) verified.value = ok;
    });
  }

  static bool _runChecks() {
    if (!SecurityBindings.load()) return false;
    if (!IntegrityCheck.verify()) return false;
    if (!CopyrightCheck.verify()) return false;
    if (!TokenCheck.verify()) return false;
    if (!AntiDebugCheck.verify()) return false;
    return true;
  }
}
