import 'dart:convert';

/// Turns whatever the user pasted into a project URL: accepts the API URL
/// with or without a path, or a dashboard link such as
/// https://supabase.com/dashboard/project/abcd1234.
String normalizeSupabaseUrl(String input) {
  final uri = Uri.tryParse(input.trim());
  if (uri == null || uri.host.isEmpty) return input.trim();
  final dashboard = RegExp(
    r'^/dashboard/project/([a-z0-9]+)',
  ).firstMatch(uri.path);
  if (uri.host == 'supabase.com' && dashboard != null) {
    return 'https://${dashboard.group(1)}.supabase.co';
  }
  return uri.origin;
}

/// Returns a message explaining what's wrong, or null when the values look usable.
String? validateSupabaseCredentials(String url, String key) {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !(uri.scheme == 'https' || uri.scheme == 'http') ||
      !uri.host.contains('.')) {
    return 'Enter your Project URL, for example https://abcd1234.supabase.co';
  }
  if (key.trim().isEmpty) return 'Paste the publishable (anon) key';
  if (isSecretKey(key.trim())) {
    return 'That is a secret key, which bypasses all security. '
        'Use the publishable (anon) key instead.';
  }
  return null;
}

/// Detects `sb_secret_…` keys and legacy service_role JWTs.
bool isSecretKey(String key) {
  if (key.startsWith('sb_secret_')) return true;
  final parts = key.split('.');
  if (parts.length != 3) return false;
  try {
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    return (jsonDecode(payload) as Map<String, dynamic>)['role'] ==
        'service_role';
  } catch (_) {
    return false;
  }
}
