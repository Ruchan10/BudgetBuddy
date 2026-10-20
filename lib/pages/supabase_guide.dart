import 'package:budgget_buddy/core/app_info.dart';
import 'package:budgget_buddy/core/links.dart';
import 'package:budgget_buddy/core/routes.dart';
import 'package:budgget_buddy/core/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Step-by-step Supabase setup with copy-paste SQL and function code.
class SupabaseGuidePage extends StatefulWidget {
  const SupabaseGuidePage({super.key});

  // Bundled from the repo's supabase/ folder (see pubspec.yaml).
  static const sqlAsset = 'supabase/setup.sql';
  static const functionAsset = 'supabase/functions/categorize/index.ts';

  @override
  State<SupabaseGuidePage> createState() => _SupabaseGuidePageState();
}

class _SupabaseGuidePageState extends State<SupabaseGuidePage> {
  late final Future<(String, String)> _code = (
    rootBundle.loadString(SupabaseGuidePage.sqlAsset),
    rootBundle.loadString(SupabaseGuidePage.functionAsset),
  ).wait;

  /// Goes back to Cloud sync if it's already open, otherwise opens it.
  void _openCloudSync() {
    var found = false;
    Navigator.popUntil(context, (route) {
      found = route.settings.name == AppRoute.cloudSyncRoute;
      return found || route.isFirst;
    });
    if (!found) Navigator.pushNamed(context, AppRoute.cloudSyncRoute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase setup'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: FutureBuilder(
        future: _code,
        builder: (context, snapshot) {
          final (sql, function) = snapshot.data ?? ('', '');
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                'Takes about 5 minutes and is free. Your data goes to your '
                'own Supabase project, protected by your login.',
                style: theme.textTheme.bodyMedium,
              ),
              _Step(
                number: 1,
                title: 'Create a Supabase project',
                lines: const [
                  'Open supabase.com and sign up for a free account.',
                  'Click New project. Pick a name, a database password and the '
                      'region closest to you, then Create new project.',
                  'Wait a minute or two until the project is ready.',
                ],
                action: OutlinedButton.icon(
                  onPressed: () => openLink(AppInfo.supabaseDashboardUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Supabase'),
                ),
              ),
              _Step(
                number: 2,
                title: 'Create the tables',
                lines: const [
                  'In your project open SQL Editor in the left sidebar and '
                      'start a new query.',
                  'Tap Copy below, paste everything into the editor and '
                      'press Run.',
                  'You should see "Success. No rows returned". Running it '
                      'again later is safe.',
                ],
                code: sql,
              ),
              const _Step(
                number: 3,
                title: 'Create your login',
                lines: [
                  'Open Authentication > Users > Add user > Create new user.',
                  'Enter the email and password you want to use in the app, '
                      'tick Auto Confirm User and press Create user.',
                  'Want to use Create account in the app instead? First turn '
                      'off "Confirm email" under Authentication > Sign In / '
                      'Providers > Email.',
                ],
              ),
              const _Step(
                number: 4,
                title: 'Copy your project URL and key',
                lines: [
                  'Click Connect at the top of your project page (the same '
                      'values are under Project Settings > API Keys).',
                  'Copy the Project URL (https://….supabase.co) and the '
                      'publishable key (sb_publishable_…). An older "anon" '
                      'key works too.',
                  'Never use the secret or service_role key: it bypasses all '
                      'security. The app refuses it.',
                ],
              ),
              _Step(
                number: 5,
                title: 'Connect the app',
                lines: const [
                  'Open Cloud sync, paste the URL and key and tap Connect.',
                  'Sign in with the login from step 3.',
                  'Done. Transactions already on this device upload, and the '
                      'app syncs whenever it is online.',
                ],
                action: FilledButton.icon(
                  onPressed: _openCloudSync,
                  icon: const Icon(Icons.cloud_sync_outlined),
                  label: const Text('Open Cloud sync'),
                ),
              ),
              _Step(
                number: 6,
                title: 'Optional: AI categorization',
                lines: const [
                  'Fills in categories the app could not guess, using '
                      "Supabase's built-in gte-small model. No API key or "
                      'extra account needed.',
                  'Open Edge Functions > Deploy a new function > Via Editor.',
                  'Name it categorize, replace all the example code with the '
                      'code below and press Deploy function.',
                  'In the app turn on AI categorization in Cloud sync.',
                ],
                code: function,
              ),
              const SizedBox(height: 16),
              Text('Troubleshooting', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              const _Tip(
                problem: '"Your Supabase project is not set up yet"',
                fix: 'Run the SQL from step 2 again.',
              ),
              const _Tip(
                problem: '"Invalid login credentials"',
                fix:
                    'Check the email and password, or create the user (step 3).',
              ),
              const _Tip(
                problem: '"Email not confirmed"',
                fix:
                    'Tick Auto Confirm User when creating the user, or turn '
                    'off "Confirm email" (step 3).',
              ),
              const _Tip(
                problem: '"Invalid API key"',
                fix:
                    'Disconnect in Cloud sync and paste the publishable key '
                    'again (step 4).',
              ),
              const _Tip(
                problem: 'Sync stopped after a while',
                fix:
                    'Free projects pause after about a week without use. Open '
                    'the Supabase dashboard and restore the project.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.lines,
    this.code,
    this.action,
  });

  final int number;
  final String title;
  final List<String> lines;
  final String? code;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                child: Text('$number', style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(left: 40, bottom: 6),
              child: Text(line, style: theme.textTheme.bodyMedium),
            ),
          if (code != null)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4),
              child: _CodeBlock(code!),
            ),
          if (action != null)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4),
              child: action,
            ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock(this.code);

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: code.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (!context.mounted) return;
                      showSnackBar(context: context, message: 'Copied');
                    },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  code,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.problem, required this.fix});

  final String problem;
  final String fix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$problem\n',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: fix),
          ],
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
