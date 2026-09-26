// lib/data/session_repository.dart
//
// Orchestrates the full pipeline from raw CSV → database.
// Called by the BLE sync service after a session file is fully received.

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'database.dart';
import 'csv_parser.dart';

/// The saved copy of a session CSV, from the path stored at sync time.
///
/// Paths are stored absolute, and iOS moves the app's Documents directory on
/// every app update or reinstall, so a stored path goes stale even though the
/// file is still there. Fall back to the same name under today's directory.
Future<File> resolveSavedCsv(String storedPath) async {
  final stored = File(storedPath);
  if (await stored.exists()) return stored;
  try {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'sessions', p.basename(storedPath)));
  } catch (_) {
    return stored;   // no path_provider (unit tests)
  }
}

class SessionRepository {
  final AppDatabase db;

  SessionRepository(this.db);

  /// Content fingerprint of a downloaded session file.
  static String fingerprint(String csvContent) =>
      sha256.convert(utf8.encode(csvContent)).toString();

  /// True if the phone already holds this session: the same number *and* the
  /// same file. The number alone is not enough — a new board or a new SD card
  /// counts from 1 again, and matching on it silently discarded every new
  /// session under a number the phone had seen before. A closed session never
  /// changes, so an identical file is a re-download (e.g. a lost DONE).
  Future<bool> isAlreadySynced(int esp32SessionId, String csvHash) async {
    for (final s in await db.getSyncSessionsByNumber(esp32SessionId)) {
      if (s.csvHash != null) {
        if (s.csvHash == csvHash) return true;
        continue;
      }
      // Synced before fingerprints were kept: compare with the saved copy.
      // Without one there is no telling, so keep the old rule and skip.
      final saved = await resolveSavedCsv(s.rawCsvPath);
      if (!await saved.exists()) return true;
      if (fingerprint(await saved.readAsString()) == csvHash) return true;
    }
    return false;
  }

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
    final csvHash = fingerprint(csvContent);
    if (await isAlreadySynced(esp32SessionId, csvHash)) return -1;

    // Parse CSV into records and raw trip markers
    final parsed = CsvParser.parse(
      csvContent:       csvContent,
      esp32SessionId:   esp32SessionId,
      syncedAtUnix:     syncedAtUnix,
    );

    if (parsed.records.isEmpty) return 0;

    // Group records by date for day-level processing
    final recordsByDate = groupBy(parsed.records, (r) => r.dayDate.value);

    // The guard above is check-then-act: two overlapping sync runs can both pass
    // it and would both ingest the session, so it is repeated inside the
    // transaction.
    bool duplicate = false;

    await db.transaction(() async {
      // Re-check atomically. Drift serialises transactions, so if a concurrent
      // run beat us here, its sync-session row is already committed.
      if (await isAlreadySynced(esp32SessionId, csvHash)) {
        duplicate = true;
        return;
      }

      // Trip IDs are stamped onto this copy before the records are inserted.
      final records = List<LogRecordsCompanion>.of(parsed.records);

      // ── 1. Upsert day summary rows ────────────────────────────────────────
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

      // ── 2. Insert trips and assign their records ─────────────────────────
      // A job left open by a power cut carries on in this session if the dash
      // resumed it (the first trip opens the file). Either way no older job
      // stays open past this session: sessions are ingested in order, and the
      // dash always resumes a running job at the very top of the next one.
      final openTrips = await db.getOpenTrips();
      final Trip? carryInto = openTrips.isNotEmpty ? openTrips.first : null;
      await db.closeOpenTrips();

      for (final rawTrip in parsed.rawTrips) {
        if (parsed.records.isEmpty) continue;

        final tripRecords = rawTrip.recordIndices.map((i) => parsed.records[i]).toList();

        if (rawTrip.continuesPrevious && carryInto != null) {
          await _extendTrip(carryInto, rawTrip, tripRecords);
          for (final i in rawTrip.recordIndices) {
            records[i] = records[i].copyWith(tripId: Value(carryInto.id));
          }
          continue;
        }

        final tripDate = parsed.records[rawTrip.recordIndices.first].dayDate.value;

        // Determine trip number within this day
        final existingTrips = await db.getTripsForDay(tripDate);
        final tripNumber    = existingTrips.length + 1;

        final tripCompanion = StatsAggregator.buildTrip(
          dayDate:     tripDate,
          tripNumber:  tripNumber,
          rawTrip:     rawTrip,
          tripRecords: tripRecords,
        ).copyWith(openEnded: Value(!rawTrip.closed));

        final tripId = await db.insertTrip(tripCompanion);

        // Assign by the parser's own record indices. This used to back-fill
        // with an UPDATE over dayDate + unixTime range, which also claimed any
        // other session's records in that window — and without the dash's
        // clock, timestamps are reconstructed relative to sync time, so
        // sessions synced together overlap and one job's chart mixed in
        // another's rows — and it
        // dropped every row after midnight from a job that crossed it.
        for (final i in rawTrip.recordIndices) {
          records[i] = records[i].copyWith(tripId: Value(tripId));
        }
      }

      // ── 3. Insert log records, trip IDs included ─────────────────────────
      await db.insertLogRecords(records);

      // ── 4. Record sync metadata ───────────────────────────────────────────
      await db.insertSyncSession(SyncSessionsCompanion(
        esp32SessionId:           Value(esp32SessionId),
        syncedAt:                 Value(DateTime.fromMillisecondsSinceEpoch(syncedAtUnix * 1000)),
        rawCsvPath:               Value(rawCsvPath),
        bestEffortOffsetSeconds:  const Value(0),
        recordDate:               Value(parsed.records.first.dayDate.value),
        csvHash:                  Value(csvHash),
      ));
    });

    // -1 tells the caller to ACK the session anyway — re-downloading it will
    // never succeed, so retrying just blocks every session behind it.
    if (duplicate) return -1;

    return parsed.records.length;
  }

  /// Add this session's part of a job to the job it continues. The job keeps
  /// its day, number, name, start and starting SoC. Ah and kWh are summed per
  /// part: the shunt's counters may restart with the power, so the first and
  /// last readings across a cut do not subtract.
  Future<void> _extendTrip(
    Trip trip,
    RawTrip rawTrip,
    List<LogRecordsCompanion> tripRecords,
  ) async {
    final part = StatsAggregator.buildTrip(
      dayDate:     trip.dayDate,
      tripNumber:  trip.tripNumber,
      rawTrip:     rawTrip,
      tripRecords: tripRecords,
    );
    final endUnix = rawTrip.endUnix > trip.endUnix ? rawTrip.endUnix : trip.endUnix;

    await db.updateTrip(trip.id, TripsCompanion(
      endUnix:           Value(endUnix),
      durationSecs:      Value(endUnix - trip.startUnix),
      ahConsumed:        Value(trip.ahConsumed  + part.ahConsumed.value),
      kwhConsumed:       Value(trip.kwhConsumed + part.kwhConsumed.value),
      peakRpm:           Value(_imax(trip.peakRpm,          part.peakRpm.value)),
      peakMotorTempC:    Value(_max(trip.peakMotorTempC,    part.peakMotorTempC.value)),
      peakInverterTempC: Value(_max(trip.peakInverterTempC, part.peakInverterTempC.value)),
      peakBmsTempC:      Value(_max(trip.peakBmsTempC,      part.peakBmsTempC.value)),
      peakCurrentA:      Value(_max(trip.peakCurrentA,      part.peakCurrentA.value)),
      socEnd:            Value(rawTrip.socEnd ?? trip.socEnd),
      openEnded:         Value(!rawTrip.closed),
    ));
  }

  double _max(double a, double b) => a > b ? a : b;
  int    _imax(int a, int b)      => a > b ? a : b;
}
