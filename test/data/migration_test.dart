// test/data/migration_test.dart
//
// Upgrades an on-disk database written by an older schema.
//
// Run with: flutter test test/data/migration_test.dart

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somerset_ev_telematics/data/database.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('migration'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('v9 -> v10 keeps synced sessions and lets a number repeat', () async {
    final file = File('${dir.path}/db.sqlite');

    // Create the current schema, then put sync_sessions back as v9 had it:
    // keyed by the session number, no row id, no csv_hash.
    var db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customStatement('DROP TABLE sync_sessions');
    await db.customStatement(
        'CREATE TABLE sync_sessions ('
        'esp32_session_id INTEGER NOT NULL, synced_at INTEGER NOT NULL, '
        'raw_csv_path TEXT NOT NULL, best_effort_offset_seconds INTEGER NOT NULL, '
        'record_date TEXT NULL, PRIMARY KEY (esp32_session_id))');
    await db.customStatement(
        "INSERT INTO sync_sessions VALUES (1, 0, 'a.csv', 0, '2026-01-01'), "
        "(2, 0, 'b.csv', 0, '2026-01-02')");
    await db.customStatement('PRAGMA user_version = 9');
    await db.close();

    db = AppDatabase.forTesting(NativeDatabase(file));
    final rows = await db.getAllSyncSessions();
    expect(rows.map((r) => r.esp32SessionId), unorderedEquals([1, 2]));
    expect(rows.map((r) => r.rawCsvPath), unorderedEquals(['a.csv', 'b.csv']));
    expect(rows.every((r) => r.csvHash == null), isTrue);

    // Session 1 from a new board: allowed alongside the old one now.
    await db.insertSyncSession(SyncSessionsCompanion.insert(
      esp32SessionId: 1,
      syncedAt: DateTime(2026),
      rawCsvPath: 'c.csv',
      bestEffortOffsetSeconds: 0,
    ));
    expect(await db.getSyncSessionsByNumber(1), hasLength(2));
    await db.close();
  });
}
