// lib/data/session_repository.dart
//
// Orchestrates the full pipeline from raw CSV → database.
// Called by the BLE sync service after a session file is fully received.

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'database.dart';
import 'csv_parser.dart';

class SessionRepository {
  final AppDatabase db;

  SessionRepository(this.db);

  /// Returns true if this ESP32 session has already been synced.
  Future<bool> isAlreadySynced(int esp32SessionId) =>
      db.isSessionSynced(esp32SessionId);

  /// Full pipeline: parse CSV, insert all records, build day and trip summaries.
  ///
  /// Called once per session after BLE transfer completes.
  /// Idempotent — if session already exists, returns without re-inserting.
  Future<void> ingestSession({
    required int esp32SessionId,
    required String csvContent,
    required String rawCsvPath,
    required int syncedAtUnix,
  }) async {
    // Guard against double-ingestion
    if (await isAlreadySynced(esp32SessionId)) return;

    // Parse CSV into records and raw trip markers
    final parsed = CsvParser.parse(
      csvContent:       csvContent,
      esp32SessionId:   esp32SessionId,
      syncedAtUnix:     syncedAtUnix,
    );

    if (parsed.records.isEmpty) return;

    // Group records by date for day-level processing
    final recordsByDate = groupBy(parsed.records, (r) => r.dayDate.value);

    await db.transaction(() async {
      // ── 1. Insert raw log records (without trip IDs yet) ─────────────────
      await db.insertLogRecords(parsed.records);

      // ── 2. Upsert day summary rows ────────────────────────────────────────
      for (final entry in recordsByDate.entries) {
        final date        = entry.key;
        final dayRecords  = entry.value;
        final dayCompanion = StatsAggregator.buildDay(
          date:    date,
          records: dayRecords,
        );

        final existing = await db.getDayByDate(date);
        if (existing != null) {
          // Day already has records from a previous session — merge stats
          // Keep the highest peak values, sum duration and Ah
          await db.upsertDay(DaysCompanion(
            date:              Value(date),
            totalDurationSecs: Value(existing.totalDurationSecs + dayCompanion.totalDurationSecs.value),
            totalAh:           Value(existing.totalAh + dayCompanion.totalAh.value),
            peakMotorTempC:    Value(_max(existing.peakMotorTempC,    dayCompanion.peakMotorTempC.value)),
            peakInverterTempC: Value(_max(existing.peakInverterTempC, dayCompanion.peakInverterTempC.value)),
            peakBmsTempC:      Value(_max(existing.peakBmsTempC,      dayCompanion.peakBmsTempC.value)),
            peakCurrentA:      Value(_max(existing.peakCurrentA,      dayCompanion.peakCurrentA.value)),
            peakRpm:           Value(_imax(existing.peakRpm,           dayCompanion.peakRpm.value)),
          ));
        } else {
          await db.upsertDay(dayCompanion);
        }
      }

      // ── 3. Insert trips and update record trip IDs ────────────────────────
      // Group raw trips by date
      for (final rawTrip in parsed.rawTrips) {
        if (parsed.records.isEmpty) continue;

        final tripDate = parsed.records[rawTrip.recordIndices.first].dayDate.value;

        // Determine trip number within this day
        final existingTrips = await db.getTripsForDay(tripDate);
        final tripNumber    = existingTrips.length + 1;

        final tripRecords   = rawTrip.recordIndices.map((i) => parsed.records[i]).toList();

        final tripCompanion = StatsAggregator.buildTrip(
          dayDate:     tripDate,
          tripNumber:  tripNumber,
          rawTrip:     rawTrip,
          tripRecords: tripRecords,
        );

        final tripId = await db.insertTrip(tripCompanion);

        // Back-fill tripId on the log records within this trip
        // We need the actual DB row IDs — query the just-inserted records by tick range
        // This is the one slightly expensive step but runs once per trip at sync time
        await (db.update(db.logRecords)
              ..where((r) =>
                  r.dayDate.equals(tripDate) &
                  r.unixTime.isBetweenValues(rawTrip.startUnix, rawTrip.endUnix)))
            .write(LogRecordsCompanion(tripId: Value(tripId)));
      }

      // ── 4. Record sync metadata ───────────────────────────────────────────
      await db.insertSyncSession(SyncSessionsCompanion(
        esp32SessionId:           Value(esp32SessionId),
        syncedAt:                 Value(DateTime.fromMillisecondsSinceEpoch(syncedAtUnix * 1000)),
        rawCsvPath:               Value(rawCsvPath),
        bestEffortOffsetSeconds:  Value(0),  // populated by parser, stored here for reference
      ));
    });
  }

  double _max(double a, double b) => a > b ? a : b;
  int    _imax(int a, int b)      => a > b ? a : b;
}
