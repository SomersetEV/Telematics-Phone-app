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
}
