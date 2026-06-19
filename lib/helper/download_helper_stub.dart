import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

void downloadCsvFile(BuildContext context, String filename, String csvContent) {
  // Since cross-platform path_provider is not in the pubspec.yaml,
  // we display the CSV in a dialog as a friendly non-web fallback.
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("CSV Exported: $filename"),
      content: SizedBox(
        width: 400,
        height: 300,
        child: SingleChildScrollView(
          child: SelectableText(csvContent),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    ),
  );
}

void openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
