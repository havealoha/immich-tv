import 'dart:io';
import 'package:flutter/material.dart';

class CertificateTrustDialog extends StatelessWidget {
  const CertificateTrustDialog({
    super.key,
    required this.rawUrl,
    required this.onTrust,
  });

  final String rawUrl;
  final VoidCallback onTrust;

  @override
  Widget build(BuildContext context) {
    final host = Uri.tryParse(rawUrl)?.host ?? rawUrl;

    return AlertDialog(
      title: const Text('Untrusted Certificate'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Server: $host'),
          const SizedBox(height: 16),
          const Text(
            'This server is using a self-signed certificate.\n\n'
            'Do you want to trust it for this server?',
          ),
          const SizedBox(height: 16),
          const Text(
            'This decision will be remembered for this specific server.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            onTrust();
            Navigator.of(context).pop();
          },
          child: const Text('Trust Certificate'),
        ),
      ],
    );
  }
}
