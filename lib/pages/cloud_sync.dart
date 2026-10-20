import 'package:budgget_buddy/core/routes.dart';
import 'package:budgget_buddy/provider/settings_provider.dart';
import 'package:budgget_buddy/provider/sync_provider.dart';
import 'package:budgget_buddy/provider/transaction_provider.dart';
import 'package:budgget_buddy/services/supabase_credentials.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One-line sync status for Settings and this page.
String describeSyncState(SyncState sync) {
  if (!sync.configured) return 'Off. Your data stays on this device.';
  if (!sync.signedIn) return 'Signed out';
  if (sync.syncing) return 'Syncing…';
  if (sync.error != null) return sync.error!;
  final last = sync.lastSyncedAt;
  if (last == null) return 'Signed in as ${sync.email}';
  final ago = DateTime.now().difference(last);
  if (ago.inMinutes < 1) return 'Synced just now';
  if (ago.inHours < 1) return 'Synced ${ago.inMinutes} min ago';
  if (ago.inDays < 1) return 'Synced ${ago.inHours} h ago';
  return 'Synced ${DateFormat.yMMMd().format(last)}';
}

/// Something the user typed needs fixing; [message] says what.
class _InputError implements Exception {
  const _InputError(this.message);

  final String message;
}

class CloudSyncPage extends ConsumerStatefulWidget {
  const CloudSyncPage({super.key});

  @override
  ConsumerState<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends ConsumerState<CloudSyncPage> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Runs [action] with a spinner; its result (or error) is shown on the page.
  Future<void> _run(Future<String?> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    String? message;
    var isError = false;
    try {
      message = await action();
    } on _InputError catch (e) {
      message = e.message;
      isError = true;
    } on AuthException catch (e) {
      message = e.message;
      isError = true;
    } catch (e) {
      message = describeSyncError(e);
      isError = true;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = message;
      _messageIsError = isError;
    });
  }

  Future<void> _connect() => _run(() async {
    final url = normalizeSupabaseUrl(_urlController.text);
    final key = _keyController.text.trim();
    final problem = validateSupabaseCredentials(url, key);
    if (problem != null) throw _InputError(problem);
    await ref.read(syncProvider.notifier).connect(url, key);
    return 'Connected. Now sign in with the login from step 3 of the guide.';
  });

  Future<void> _signIn({required bool createAccount}) => _run(() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      throw const _InputError('Enter your email and password');
    }
    final sync = ref.read(syncProvider.notifier);
    if (!createAccount) {
      await sync.signIn(email, password);
    } else if (!await sync.signUp(email, password)) {
      return 'Account created, but Supabase wants the email confirmed first. '
          'Open the link in that email, or turn off "Confirm email" '
          '(guide, step 3), then sign in.';
    }
    _passwordController.clear();
    return null;
  });

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect project?'),
        content: const Text(
          'Syncing stops and this device forgets the project. '
          'Your transactions stay on this device and in Supabase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await ref.read(syncProvider.notifier).disconnect();
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sync = ref.watch(syncProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud sync'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Back up your transactions and use them on several devices '
            'through your own free Supabase project. The app keeps working '
            'offline; changes sync automatically when you are online.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (!sync.signedIn)
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoute.supabaseGuideRoute),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Step-by-step setup guide'),
            ),
          const SizedBox(height: 8),
          if (!sync.configured)
            ..._projectForm()
          else if (!sync.signedIn)
            ..._signInForm(sync)
          else
            ..._signedIn(sync),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _message!,
                style: TextStyle(
                  color: _messageIsError
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _projectForm() => [
    const SizedBox(height: 8),
    TextField(
      controller: _urlController,
      keyboardType: TextInputType.url,
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: 'Project URL',
        hintText: 'https://abcd1234.supabase.co',
        prefixIcon: Icon(Icons.link),
      ),
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _keyController,
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: 'Publishable (anon) key',
        hintText: 'sb_publishable_…',
        helperText: 'Never use the secret or service_role key.',
        prefixIcon: Icon(Icons.vpn_key),
      ),
    ),
    const SizedBox(height: 16),
    FilledButton.icon(
      onPressed: _busy ? null : _connect,
      icon: const Icon(Icons.power_outlined),
      label: const Text('Connect'),
    ),
  ];

  List<Widget> _signInForm(SyncState sync) => [
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.dns_outlined),
      title: const Text('Project'),
      subtitle: Text(Uri.parse(sync.projectUrl!).host),
      trailing: TextButton(
        onPressed: _busy ? null : _disconnect,
        child: const Text('Change'),
      ),
    ),
    if (sync.error != null)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          sync.error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.alternate_email),
      ),
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock_outline),
      ),
      onSubmitted: (_) => _signIn(createAccount: false),
    ),
    const SizedBox(height: 16),
    FilledButton.icon(
      onPressed: _busy ? null : () => _signIn(createAccount: false),
      icon: const Icon(Icons.login),
      label: const Text('Sign in'),
    ),
    const SizedBox(height: 8),
    OutlinedButton(
      onPressed: _busy ? null : () => _signIn(createAccount: true),
      child: const Text('Create account'),
    ),
  ];

  List<Widget> _signedIn(SyncState sync) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    ref.watch(transactionListProvider);
    final pending = ref
        .read(transactionListProvider.notifier)
        .pendingChanges
        .length;

    return [
      Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(sync.email!),
              subtitle: Text(Uri.parse(sync.projectUrl!).host),
            ),
            ListTile(
              leading: Icon(
                sync.error != null
                    ? Icons.sync_problem
                    : Icons.cloud_done_outlined,
                color: sync.error != null ? Colors.orange : null,
              ),
              title: Text(describeSyncState(sync)),
              subtitle: Text(
                pending == 0
                    ? 'Everything is uploaded'
                    : '$pending change${pending == 1 ? '' : 's'} waiting to upload',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: sync.syncing
            ? null
            : () => ref.read(syncProvider.notifier).sync(),
        icon: const Icon(Icons.sync),
        label: const Text('Sync now'),
      ),
      const SizedBox(height: 8),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: const Icon(Icons.auto_awesome_outlined),
        title: const Text('AI categorization'),
        subtitle: const Text(
          'Fills in missing categories with the optional "categorize" '
          'function in your Supabase project (guide, step 6).',
        ),
        value: settings.aiCategorize,
        onChanged: (value) async {
          await ref
              .read(settingsProvider.notifier)
              .update((s) => s.copyWith(aiCategorize: value));
          if (value) ref.read(syncProvider.notifier).sync();
        },
      ),
      const Divider(height: 32),
      OutlinedButton.icon(
        onPressed: _busy
            ? null
            : () => _run(() async {
                await ref.read(syncProvider.notifier).signOut();
                return 'Signed out. Your data stays on this device.';
              }),
        icon: const Icon(Icons.logout),
        label: const Text('Sign out'),
      ),
      TextButton(
        onPressed: _busy ? null : _disconnect,
        style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
        child: const Text('Disconnect project'),
      ),
    ];
  }
}
