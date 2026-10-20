import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the browser or matching app. Returns false if nothing could.
Future<bool> openLink(String url) async {
  try {
    // Not guarded by canLaunchUrl: on Android 11+ that needs <queries>
    // entries and wrongly reports false without them.
    return await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    debugPrint('Could not open $url: $e');
    return false;
  }
}
