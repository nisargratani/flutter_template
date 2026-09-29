import 'package:database/src/app_database.dart';
import 'package:database/src/tables/cached_posts.dart';
import 'package:drift/drift.dart';

part 'posts_dao.g.dart';

/// Queries for the cached posts table.
@DriftAccessor(tables: [CachedPosts])
class PostsDao extends DatabaseAccessor<AppDatabase> with _$PostsDaoMixin {
  new(super.attachedDatabase);

  /// Replaces the whole cache atomically with [rows].
  Future<void> replaceAll(List<CachedPostsCompanion> rows) =>
      transaction(() async {
        await delete(cachedPosts).go();
        await batch((b) => b.insertAll(cachedPosts, rows));
      });

  /// All cached posts, ordered by id.
  Future<List<CachedPostRow>> getAll() =>
      (select(cachedPosts)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  /// Emits the cached posts whenever the table changes.
  Stream<List<CachedPostRow>> watchAll() =>
      (select(cachedPosts)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  Future<CachedPostRow?> getById(int id) =>
      (select(cachedPosts)..where((t) => t.id.equals(id))).getSingleOrNull();
}
