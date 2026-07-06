import 'package:flutter/material.dart';
import '../../../../core/auth/services/account_linking_service.dart';

class AccountLinkingDialog extends StatelessWidget {
  const AccountLinkingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Account Upgrade'),
      content: const Text(
        'You are currently using a Guest account. How would you like to handle your existing data (bookmarks, history)?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, LinkStrategy.continueAsGuest),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, LinkStrategy.startFresh),
          child: const Text('Start Fresh'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, LinkStrategy.mergeData),
          child: const Text('Merge Data'),
        ),
      ],
    );
  }
}

Future<LinkStrategy?> showAccountLinkingDialog(BuildContext context) {
  return showDialog<LinkStrategy>(
    context: context,
    builder: (context) => const AccountLinkingDialog(),
  );
}
