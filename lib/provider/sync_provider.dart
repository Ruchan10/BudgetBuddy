import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:budgget_buddy/core/listen_internet.dart';
import 'package:budgget_buddy/core/user_shared_prefs.dart';
import 'package:budgget_buddy/models/transaction.dart';
import 'package:budgget_buddy/provider/settings_provider.dart';
import 'package:budgget_buddy/provider/transaction_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// Default for nullable copyWith parameters, so passing null can clear a value.
const Object _keep = Object();

class SyncState {
  const SyncState({
    this.projectUrl,
    this.email,
    this.syncing = false,
    this.lastSyncedAt,
    this.error,
  });

  /// Null while cloud sync isn't set up.
  final String? projectUrl;

  /// Null while signed out.
  final String? email;
  final bool syncing;
  final DateTime? lastSyncedAt;
  final String? error;

  bool get configured => projectUrl != null;
  bool get signedIn => email != null;

  SyncState copyWith({
    Object? projectUrl = _keep,
    Object? email = _keep,
    bool? syncing,
    DateTime? lastSyncedAt,
    Object? error = _keep,
  }) {
    return SyncState(
      projectUrl: identical(projectUrl, _keep)
          ? this.projectUrl
          : projectUrl as String?,
      email: identical(email, _keep) ? this.email : email as String?,
      syncing: syncing ?? this.syncing,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      error: identical(error, _keep) ? this.error : error as String?,
    );
  }
}

final syncProvider = StateNotifierProvider<SyncController, SyncState>((ref) {
  return SyncController(ref);
});

/// Keeps local transactions in step with the user's own Supabase project.
///
/// The app always reads and writes local data. While signed in and online it
/// uploads local changes and then downloads changes from other devices: shortly
/// after each edit, on start, when the app resumes and when the connection
/// returns. Conflicts are settled per transaction by the newest edit.
class SyncController extends StateNotifier<SyncState>
    with WidgetsBindingObserver {
  SyncController(this._ref)
    : super(SyncState(lastSyncedAt: UserSharedPrefs().lastSyncedAt));

  final Ref _ref;
  final _prefs = UserSharedPrefs();
  SupabaseClient? _client;
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<bool>? _networkSub;
  Timer? _debounce;
  bool _started = false;
  bool _running = false;
  bool _runAgain = false;

  static const _pushBatchSize = 200;
  static const _pullPageSize = 500;

  /// Connects to the saved project, if any, and starts background syncing.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _networkSub = NetworkService.onStatusChange.listen((online) {
      if (online) sync();
    }, onError: (Object e) => debugPrint('Connectivity: $e'));
    _ref.listen(transactionListProvider, (_, _) => _scheduleSync());
    _ref.listen(
      settingsProvider.select((s) => s.openingBalanceUpdatedAt),
      (_, _) => _scheduleSync(force: true),
    );

    final config = _prefs.supabaseConfig;
    if (config == null) return;
    try {
      await _connect(config.url, config.key);
    } catch (e) {
      state = state.copyWith(
        projectUrl: config.url,
        error: describeSyncError(e),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _networkSub?.cancel();
    _authSub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final last = this.state.lastSyncedAt;
    final stale =
        last == null ||
        DateTime.now().difference(last) > const Duration(minutes: 1);
    if (state == AppLifecycleState.resumed && stale) sync();
  }

  /// Saves the project credentials and connects to it.
  Future<void> connect(String url, String key) async {
    await _connect(url, key);
    await _prefs.saveSupabaseConfig(url, key);
  }

  Future<void> _connect(String url, String key) async {
    await _closeClient();
    await Supabase.initialize(
      url: url,
      anonKey: key,
      // Email + password only; no deep links to listen for.
      authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
      debug: false,
    );
    final client = Supabase.instance.client;
    _client = client;
    _authSub = client.auth.onAuthStateChange.listen(
      (data) => state = state.copyWith(email: _label(data.session?.user)),
      // Token refresh failing while offline lands here; the session is kept.
      onError: (Object e) => debugPrint('Supabase auth: $e'),
    );
    final user = client.auth.currentUser;
    state = state.copyWith(projectUrl: url, email: _label(user), error: null);
    if (user != null) unawaited(sync());
  }

  Future<void> _closeClient() async {
    await _authSub?.cancel();
    _authSub = null;
    if (_client == null) return;
    _client = null;
    await Supabase.instance.dispose();
  }

  Future<void> signIn(String email, String password) async {
    final response = await _requireClient().auth.signInWithPassword(
      email: email,
      password: password,
    );
    await _onSignedIn(response.user!);
  }

  /// Returns false when the project wants the email confirmed first.
  Future<bool> signUp(String email, String password) async {
    final response = await _requireClient().auth.signUp(
      email: email,
      password: password,
    );
    if (response.session == null) return false;
    await _onSignedIn(response.user!);
    return true;
  }

  Future<void> _onSignedIn(User user) async {
    state = state.copyWith(email: _label(user), error: null);
    if (_prefs.syncUserId != user.id) {
      // First sign-in here, or another account: upload everything on this
      // device and download everything from the server.
      await _prefs.setSyncUserId(user.id);
      await _prefs.setSyncCursor(null);
      await _ref.read(transactionListProvider.notifier).markAllPending();
    }
    await sync();
  }

  Future<void> signOut() async {
    try {
      await _client?.auth.signOut();
    } catch (e) {
      // Offline: the local session is already gone, which is what matters.
      debugPrint('Sign out: $e');
    }
    state = state.copyWith(email: null);
  }

  /// Stops syncing and forgets the project. Data on this device stays.
  Future<void> disconnect() async {
    await signOut();
    await _closeClient();
    await _prefs.clearSupabaseConfig();
    await _ref.read(transactionListProvider.notifier).dropTombstones();
    state = const SyncState();
  }

  void _scheduleSync({bool force = false}) {
    if (!state.signedIn) return;
    final store = _ref.read(transactionListProvider.notifier);
    if (!force && !store.hasPendingChanges) return;
    if (_running) {
      _runAgain = true;
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), sync);
  }

  /// Uploads local changes, then downloads changes made elsewhere.
  Future<void> sync() async {
    final client = _client;
    if (client == null || client.auth.currentSession == null) return;
    if (_running) {
      _runAgain = true;
      return;
    }
    _running = true;
    _debounce?.cancel();
    try {
      if (!await NetworkService.checkNetwork()) return;
      state = state.copyWith(syncing: true, error: null);
      final warning = await _syncOnce(
        client,
      ).timeout(const Duration(minutes: 2));
      final now = DateTime.now();
      await _prefs.setLastSyncedAt(now);
      state = state.copyWith(syncing: false, lastSyncedAt: now, error: warning);
    } catch (e) {
      debugPrint('Sync failed: $e');
      state = state.copyWith(syncing: false, error: describeSyncError(e));
    } finally {
      _running = false;
    }
    if (_runAgain) {
      _runAgain = false;
      unawaited(sync());
    }
  }

  /// Returns a message if an optional step failed.
  Future<String?> _syncOnce(SupabaseClient client) async {
    final store = _ref.read(transactionListProvider.notifier);
    await _push(client, store);
    await _pull(client, store);
    await _syncOpeningBalance(client);

    if (!_ref.read(settingsProvider).aiCategorize || !store.hasUncategorized) {
      return null;
    }
    try {
      if (await _categorizeOnServer(client)) await _pull(client, store);
      return null;
    } on FunctionException catch (e) {
      return e.status == 404
          ? 'AI categorization is on, but the "categorize" function is not '
                'deployed yet (setup guide, step 6).'
          : 'AI categorization failed: ${e.details ?? e.reasonPhrase}';
    }
  }

  Future<void> _push(SupabaseClient client, TransactionNotifier store) async {
    final pending = store.pendingChanges;
    for (var i = 0; i < pending.length; i += _pushBatchSize) {
      final batch = pending.sublist(i, min(i + _pushBatchSize, pending.length));
      await client.rpc(
        'push_transactions',
        params: {
          'changes': [for (final t in batch) t.toRemote()],
        },
      );
      await store.markPushed(batch);
    }
  }

  Future<void> _pull(SupabaseClient client, TransactionNotifier store) async {
    final cursor = _prefs.syncCursor;
    // Re-read a short overlap so rows committed slightly out of order aren't missed.
    final since = cursor?.subtract(const Duration(minutes: 2));
    var newest = cursor;
    for (var from = 0; ; from += _pullPageSize) {
      var query = client.from('transactions').select();
      if (since != null) {
        query = query.gt('server_updated_at', since.toUtc().toIso8601String());
      }
      final rows = await query
          .order('server_updated_at', ascending: true)
          .order('id', ascending: true)
          .range(from, from + _pullPageSize - 1);
      if (rows.isEmpty) break;
      await store.applyRemote([
        for (final row in rows) Transaction.fromRemote(row),
      ]);
      for (final row in rows) {
        final at = DateTime.parse(row['server_updated_at'] as String);
        if (newest == null || at.isAfter(newest)) newest = at;
      }
      if (rows.length < _pullPageSize) break;
    }
    if (newest != null) await _prefs.setSyncCursor(newest);
  }

  /// The starting balance lives in `user_settings`; the newest edit wins.
  Future<void> _syncOpeningBalance(SupabaseClient client) async {
    final settings = _ref.read(settingsProvider);
    final remote = await client.from('user_settings').select().maybeSingle();
    final remoteAt = remote == null
        ? null
        : DateTime.parse(remote['updated_at'] as String);
    final localAt = settings.openingBalanceUpdatedAt;

    if (localAt != null && (remoteAt == null || localAt.isAfter(remoteAt))) {
      await client.from('user_settings').upsert({
        'user_id': client.auth.currentUser!.id,
        'opening_balance': settings.openingBalance,
        'updated_at': localAt.toUtc().toIso8601String(),
      });
    } else if (remote != null &&
        remoteAt != null &&
        (localAt == null || remoteAt.isAfter(localAt))) {
      await _ref
          .read(settingsProvider.notifier)
          .setOpeningBalance(
            (remote['opening_balance'] as num).toDouble(),
            updatedAt: remoteAt,
          );
    }
  }

  /// Asks the optional `categorize` Edge Function to fill in missing
  /// categories. Returns true if it changed anything.
  Future<bool> _categorizeOnServer(SupabaseClient client) async {
    var changed = false;
    // The function works in short batches; keep asking while rows remain.
    for (var round = 0; round < 10; round++) {
      final data = (await client.functions.invoke('categorize')).data;
      if (data is! Map) break;
      changed |= ((data['updated'] as num?) ?? 0) > 0;
      if (((data['remaining'] as num?) ?? 0) == 0) break;
    }
    return changed;
  }

  SupabaseClient _requireClient() =>
      _client ?? (throw StateError('Connect a Supabase project first'));

  static String? _label(User? user) =>
      user == null ? null : (user.email ?? user.id);
}

/// Turns sync failures into something a person can act on.
String describeSyncError(Object error) {
  if (error is PostgrestException) {
    const notSetUp = {'PGRST202', 'PGRST205', '42P01', '42883'};
    if (notSetUp.contains(error.code)) {
      return 'Your Supabase project is not set up yet. Run the SQL from the '
          'setup guide (step 2).';
    }
    return 'Supabase error: ${error.message}';
  }
  if (error is AuthRetryableFetchException ||
      error is SocketException ||
      error is http.ClientException ||
      error is TimeoutException) {
    return "Couldn't reach Supabase. Check your connection and project URL.";
  }
  if (error is AuthException) return error.message;
  return 'Sync failed: $error';
}
