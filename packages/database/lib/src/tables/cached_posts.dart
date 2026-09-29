import 'package:drift/drift.dart';

/// Offline copy of the posts list from the example API.
@DataClassName('CachedPostRow')
class CachedPosts extends Table {
  IntColumn get id => integer()();
  IntColumn get userId => integer()();
  TextColumn get title => text()();
  TextColumn get body => text()();

  /// When the row was last refreshed from the network.
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
