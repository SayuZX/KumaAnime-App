import 'package:flutter/material.dart';
import 'package:kumaanime/core/security/securityInit.dart';

class KumaSecureWidget extends StatelessWidget {
  final Widget child;

  const KumaSecureWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SecurityInit.verified,
      builder: (context, verified, _) {
        if (!verified) return const _SecureErrorScreen();
        return child;
      },
    );
  }
}

class _SecureErrorScreen extends StatelessWidget {
  const _SecureErrorScreen();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Colors.black,
        child: Center(child: SizedBox.shrink()),
      ),
    );
  }
}
