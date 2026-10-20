import 'package:budgget_buddy/models/transaction.dart';

/// Merges rows downloaded from Supabase into the local list.
///
/// The copy with the newer `updatedAt` wins (last write wins). One exception:
/// the optional AI function fills in a missing category without touching
/// `updatedAt`, so a local row without a category adopts the server's one.
List<Transaction> mergeRemote(
  List<Transaction> local,
  List<Transaction> remote,
) {
  final byId = {for (final t in local) t.id: t};
  for (final r in remote) {
    final l = byId[r.id];
    if (l == null) {
      if (!r.deleted) byId[r.id] = r;
    } else if (r.updatedAt.isAfter(l.updatedAt)) {
      if (r.deleted) {
        byId.remove(r.id);
      } else {
        byId[r.id] = r;
      }
    } else if (!l.deleted && l.category == null && r.category != null) {
      byId[r.id] = l.copyWith(category: r.category);
    }
  }
  return byId.values.toList();
}

/// Marks rows as uploaded after [pushed] reached the server.
///
/// Rows edited again while the upload was running keep `pendingSync`, and
/// delivered deletions are forgotten locally.
List<Transaction> markPushed(
  List<Transaction> local,
  List<Transaction> pushed,
) {
  final sentVersion = {for (final t in pushed) t.id: t.updatedAt};
  return [
    for (final t in local)
      if (sentVersion[t.id]?.isAtSameMomentAs(t.updatedAt) != true)
        t
      else if (!t.deleted)
        t.copyWith(pendingSync: false),
  ];
}
