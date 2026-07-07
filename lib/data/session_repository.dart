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
  /// Returns the number of log records inserted, or 0 if nothing was parsed.
  /// Idempotent — if session already exists, returns -1 without re-inserting.
  Future<int> ingestSession({
    required int esp32SessionId,
    required String csvContent,
    required String rawCsvPath,
    required int syncedAtUnix,
  }) async {
    // Guard against double-ingestion
    if (await isAlreadySynced(esp32SessionId)) return -1;

    // Parse CSV into records and raw trip markers
    final parsed = CsvParser.parse(
      csvContent:       csvContent,
      esp32SessionId:   esp32SessionId,
      syncedAtUnix:     syncedAtUnix,
    );

    if (parsed.records.isEmpty) return 0;

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
            totalKwh:          Value(existing.totalKwh + dayCompanion.totalKwh.value),
            peakMotorTempC:    Value(_max(existing.peakMotorTempC,    dayCompanion.peakMotorTempC.value)),
            peakInverterTempC: Value(_max(existing.peakInverterTempC, dayCompanion.peakInverterTempC.value)),
            peakBmsTempC:      Value(_max(existing.peakBmsTempC,      dayCompanion.peakBmsTempC.value)),
            peakCurrentA:      Value(_max(existing.peakCurrentA,      dayCompanion.peakCurrentA.value)),
            peakRpm:           Value(_imax(existing.peakRpm,          dayCompanion.peakRpm.value)),
            peakSocPct:        Value(_imax(existing.peakSocPct,       dayCompanion.peakSocPct.value)),
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
        bestEffortOffsetSeconds:  const Value(0),
        recordDate:               Value(parsed.records.first.dayDate.value),
      ));
    });

    return parsed.records.length;
  }

  /// Lightweight path: receive a single-line JOB summary from the ESP32
  /// SUMMARY command and insert Day + Trip + SyncSession directly —
  /// no CSV download, no LogRecords.
  ///
  /// jobLine format:
  ///   "JOB <id>,<start_unix>,<duration_s>,<ah>,<kwh>,<soc_start>,<soc_end>,
  ///         <peak_a>,<peak_rpm>,<peak_motor_c>,<peak_inv_c>,<peak_bms_c>"
  Future<void> ingestJobSummary({
    required int    esp32SessionId,
    required String jobLine,
    required int    syncedAtUnix,
  }) async {
    if (await isAlreadySynced(esp32SessionId)) return;

    final body = jobLine.replaceFirst('JOB ', '').trim();
    final p    = body.split(',');
    if (p.length < 12) throw FormatException('JOB line too short: $jobLine');

    final startUnix    = int.parse(p[1]);
    final durationSecs = int.parse(p[2]);
    final ahConsumed   = double.parse(p[3]);
    final kwhConsumed  = double.parse(p[4]);
    final socStart     = int.tryParse(p[5]);
    final socEnd       = int.tryParse(p[6]);
    final peakCurrentA = double.parse(p[7]);
    final peakRpm      = int.parse(p[8]);
    final peakMotorC   = double.parse(p[9]);
    final peakInvC     = double.parse(p[10]);
    final peakBmsC     = double.parse(p[11]);

    // If firmware had no RTC, start_unix is 0 — approximate from sync time
    final resolvedStart = startUnix > 0 ? startUnix : syncedAtUnix - durationSecs;
    final endUnix       = resolvedStart + durationSecs;
    final dayDate       = _unixToDateString(resolvedStart);

    await db.transaction(() async {
      // ── 1. Upsert Day ──────────────────────────────────────────────────────
      final existing = await db.getDayByDate(dayDate);
      if (existing != null) {
        await db.upsertDay(DaysCompanion(
          date:              Value(dayDate),
          totalDurationSecs: Value(existing.totalDurationSecs + durationSecs),
          totalAh:           Value(existing.totalAh + ahConsumed),
          totalKwh:          Value(existing.totalKwh + kwhConsumed),
          peakMotorTempC:    Value(_max(existing.peakMotorTempC,    peakMotorC)),
          peakInverterTempC: Value(_max(existing.peakInverterTempC, peakInvC)),
          peakBmsTempC:      Value(_max(existing.peakBmsTempC,      peakBmsC)),
          peakCurrentA:      Value(_max(existing.peakCurrentA,      peakCurrentA)),
          peakRpm:           Value(_imax(existing.peakRpm,          peakRpm)),
          peakSocPct:        Value(_imax(existing.peakSocPct,       socStart ?? 0)),
        ));
      } else {
        await db.upsertDay(DaysCompanion(
          date:              Value(dayDate),
          totalDurationSecs: Value(durationSecs),
          totalAh:           Value(ahConsumed),
          totalKwh:          Value(kwhConsumed),
          peakMotorTempC:    Value(peakMotorC),
          peakInverterTempC: Value(peakInvC),
          peakBmsTempC:      Value(peakBmsC),
          peakCurrentA:      Value(peakCurrentA),
          peakRpm:           Value(peakRpm),
          peakSocPct:        Value(socStart ?? 0),
        ));
      }

      // ── 2. Insert Trip ─────────────────────────────────────────────────────
      final existingTrips = await db.getTripsForDay(dayDate);
      await db.insertTrip(TripsCompanion(
        dayDate:           Value(dayDate),
        tripNumber:        Value(existingTrips.length + 1),
        startUnix:         Value(resolvedStart),
        endUnix:           Value(endUnix),
        durationSecs:      Value(durationSecs),
        ahConsumed:        Value(ahConsumed),
        kwhConsumed:       Value(kwhConsumed),
        peakRpm:           Value(peakRpm),
        peakMotorTempC:    Value(peakMotorC),
        peakInverterTempC: Value(peakInvC),
        peakBmsTempC:      Value(peakBmsC),
        peakCurrentA:      Value(peakCurrentA),
        socStart:          Value(socStart),
        socEnd:            Value(socEnd),
      ));

      // ── 3. Record sync metadata ────────────────────────────────────────────
      await db.insertSyncSession(SyncSessionsCompanion(
        esp32SessionId:          Value(esp32SessionId),
        syncedAt:                Value(DateTime.fromMillisecondsSinceEpoch(syncedAtUnix * 1000)),
        rawCsvPath:              const Value(''),
        bestEffortOffsetSeconds: const Value(0),
        recordDate:              Value(dayDate),
      ));
    });
  }

  static String _unixToDateString(int unixSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000, isUtc: false);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  double _max(double a, double b) => a > b ? a : b;
  int    _imax(int a, int b)      => a > b ? a : b;
}
