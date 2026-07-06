import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kumaanime/core/security/securityInit.dart';

class KumaSecureWidget extends StatelessWidget {
  final Widget child;

  const KumaSecureWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode || !Platform.isAndroid) {
      return child;
    }

    return ValueListenableBuilder<bool>(
      valueListenable: SecurityInit.verified,
      builder: (context, verified, _) {
        return child;
      },
    );
  }
}

