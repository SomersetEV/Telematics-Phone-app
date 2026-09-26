// test/data/session_repository_test.dart
//
// Ingest tests against an in-memory database.
//
// Run with: flutter test test/data/session_repository_test.dart

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somerset_ev_telematics/data/database.dart';
import 'package:somerset_ev_telematics/data/session_repository.dart';

const _header =
    'SNAP1,tick_ms,soc_pct,pack_v_bms_mv,pack_i_ma,isa_kw_w,isa_as,'
    'motor_rpm,motor_temp_c10,inv_temp_c10,bms_tmax_c10,bms_tmin_c10,'
    'cell_v_max_mv,cell_v_min_mv';

String _row(int tick, int rpm) =>
    'SNAP1,$tick,80,39500,0,0,0,$rpm,0,0,0,0,4100,4050';

// [count] 1 Hz rows, with a trip over the middle rows [tripFrom, tripTo).
String _session(int count, int rpm, int tripFrom, int tripTo) {
  final lines = <String>[_header];
  for (int i = 0; i < count; i++) {
    if (i == tripFrom) lines.add('TRIP_START,,,,,,,,,,,,,,,');
    lines.add(_row(1000 * (i + 1), rpm));
    if (i == tripTo - 1) lines.add('TRIP_END,0,0,0,80,80,0,0,0,0,0,0,,,,');
  }
  return lines.join('\n');
}

void main() {
  late AppDatabase db;
  late SessionRepository repo;

  setUp(() {
    db   = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SessionRepository(db);
  });

  tearDown(() => db.close());

  test('a job holds only its own session\'s records', () async {
    // Timestamps are reconstructed relative to sync time, so two sessions
    // synced in the same second land on the same window of the same day.
    const syncedAt = 1790000000;
    await repo.ingestSession(
      esp32SessionId: 1, csvContent: _session(20, 1111, 5, 15),
      rawCsvPath: 'a', syncedAtUnix: syncedAt);
    await repo.ingestSession(
      esp32SessionId: 2, csvContent: _session(20, 2222, 5, 15),
      rawCsvPath: 'b', syncedAtUnix: syncedAt);

    final trips = await db.select(db.trips).get();
    expect(trips, hasLength(2));

    for (final trip in trips) {
      final rows = await db.getRecordsForTrip(trip.id);
      expect(rows, hasLength(10));
      // Every row in a job came from the same session.
      expect(rows.map((r) => r.motorRpm).toSet(), hasLength(1));
    }
  });

  test('records outside the trip markers stay unassigned', () async {
    await repo.ingestSession(
      esp32SessionId: 1, csvContent: _session(20, 1500, 5, 15),
      rawCsvPath: 'a', syncedAtUnix: 1790000000);

    final all = await db.select(db.logRecords).get();
    expect(all, hasLength(20));
    expect(all.where((r) => r.tripId != null), hasLength(10));
  });

  group('job across a power cut', () {
    // Session 1: the job starts, then the power is cut (no TRIP_END).
    final beforeCut = [
      _header,
      _row(1000, 1000),
      'TRIP_START,,,,,,,,,,,,,,,',
      _row(2000, 1000),
      _row(3000, 1000),
    ].join('\n');
    // Session 2: the dash resumes the job at the top of the file.
    final afterCut = [
      _header,
      'TRIP_START,,,,,,,,,,,,,,,',
      _row(1000, 3000),
      _row(2000, 3000),
      _row(3000, 3000),
      'TRIP_END,0,0,0,80,80,0,0,0,0,0,0,,,,',
      _row(4000, 0),
    ].join('\n');

    test('is one job holding both sessions\' rows', () async {
      await repo.ingestSession(esp32SessionId: 1, csvContent: beforeCut,
          rawCsvPath: 'a', syncedAtUnix: 1790000000);
      await repo.ingestSession(esp32SessionId: 2, csvContent: afterCut,
          rawCsvPath: 'b', syncedAtUnix: 1790003600);

      final trip = (await db.select(db.trips).get()).single;
      expect(trip.openEnded, isFalse);
      expect(trip.peakRpm, equals(3000));
      expect(trip.durationSecs, equals(trip.endUnix - trip.startUnix));
      expect(trip.endUnix - trip.startUnix, greaterThan(3000));  // spans the cut

      final rows = await db.getRecordsForTrip(trip.id);
      expect(rows, hasLength(5));
    });

    test('stays open until the next session is in', () async {
      await repo.ingestSession(esp32SessionId: 1, csvContent: beforeCut,
          rawCsvPath: 'a', syncedAtUnix: 1790000000);
      expect((await db.select(db.trips).get()).single.openEnded, isTrue);
    });

    test('a next session that does not resume it ends it', () async {
      await repo.ingestSession(esp32SessionId: 1, csvContent: beforeCut,
          rawCsvPath: 'a', syncedAtUnix: 1790000000);
      await repo.ingestSession(esp32SessionId: 2,
          csvContent: _session(20, 1500, 5, 15),
          rawCsvPath: 'b', syncedAtUnix: 1790003600);

      final trips = await db.select(db.trips).get();
      expect(trips, hasLength(2));
      expect(trips.where((t) => t.openEnded), isEmpty);
    });
  });
}
