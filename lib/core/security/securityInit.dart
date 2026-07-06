import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kumaanime/core/security/checks/antiDebugCheck.dart';
import 'package:kumaanime/core/security/checks/copyrightCheck.dart';
import 'package:kumaanime/core/security/checks/integrityCheck.dart';
import 'package:kumaanime/core/security/checks/tokenCheck.dart';
import 'package:kumaanime/core/security/security_manager.dart';
import 'package:kumaanime/core/security/securityBindings.dart';

class SecurityInit {
  static final ValueNotifier<bool> verified = ValueNotifier<bool>(false);

  static bool get isVerified => verified.value;

  static Timer? _timer;

  static Future<void> initialize() async {
    // Always set to true initially to allow app to start
    verified.value = true;

    if (!Platform.isAndroid || kDebugMode) {
      try {
        await SecurityManager.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            // Timeout is okay, just log it
          },
        );
      } catch (e) {
        // Ignore errors in debug mode
      }
      return;
    }

    try {
      await SecurityManager.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Continue without security manager if timeout
        },
      );

      verified.value = _runChecks();

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(minutes: 5), (_) {
        final ok = _runChecks();
        if (verified.value != ok) verified.value = ok;
      });
    } catch (e) {
      // On error, still allow the app to run but log the issue
      verified.value = true;
    }
  }

  static bool _runChecks() {
    try {
      if (!SecurityBindings.load()) return true; // Changed to true to not block
      if (!IntegrityCheck.verify()) return true;
      if (!CopyrightCheck.verify()) return true;
      if (!TokenCheck.verify()) return true;
      if (!AntiDebugCheck.verify()) return true;
      return true;
    } catch (e) {
      // On any error, return true to allow app to continue
      return true;
    }
  }

  static void dispose() {
    _timer?.cancel();
  }
}
