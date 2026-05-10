// lib/data/database.dart
//
// Drift (SQLite) schema for SomersetEV Telematics
//
// Three user-facing concepts:
//   Day      — all records for a calendar date, auto-grouped from records
//   Trip     — manually marked period within a day (TRIP_START / TRIP_END)
//   Record   — individual 1Hz log entry
//
// One internal concept:
//   SyncSession — tracks which ESP32 sessions have been downloaded
//                 never shown in UI, bookkeeping only

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// ── Tables ───────────────────────────────────────────────────────────────────

// Internal sync bookkeeping — one row per ESP32 session file downloaded
class SyncSessions extends Table {
  IntColumn get esp32SessionId => integer()();           // ESP32 session_XXXX number
  DateTimeColumn get syncedAt  => dateTime()();          // when phone downloaded it
  TextColumn get rawCsvPath    => text()();              // path to original CSV on device
  IntColumn get bestEffortOffsetSeconds => integer()();  // unix - tick_s at sync time
  // bestEffortOffsetSeconds used to reconstruct timestamps for records
  // where unix_offset was not set during recording (phone never connected that session)

  @override
  Set<Column> get primaryKey => {esp32SessionId};
}

// One row per calendar date that has at least one record
class Days extends Table {
  TextColumn get date              => text()();   // YYYY-MM-DD
  IntColumn get totalDurationSecs  => integer()();
  RealColumn get totalAh           => real()();
  RealColumn get peakMotorTempC    => real()();
  RealColumn get peakInverterTempC => real()();
  RealColumn get peakBmsTempC      => real()();
  RealColumn get peakCurrentA      => real()();
  IntColumn get peakRpm            => integer()();

  @override
  Set<Column> get primaryKey => {date};
}

// Manually marked trips — sit within a day
class Trips extends Table {
  IntColumn get id            => integer().autoIncrement()();
  TextColumn get dayDate      => text().references(Days, #date)();
  IntColumn get tripNumber    => integer()();  // 1, 2, 3... within the day
  IntColumn get startUnix     => integer()();
  IntColumn get endUnix       => integer()();
  IntColumn get durationSecs  => integer()();
  RealColumn get ahConsumed   => real()();
  IntColumn get peakRpm       => integer()();
  RealColumn get peakMotorTempC    => real()();
  RealColumn get peakInverterTempC => real()();
  RealColumn get peakBmsTempC      => real()();
  RealColumn get peakCurrentA      => real()();
  TextColumn get name         => text().nullable()();  // user-assigned job name
}

// Individual 1Hz log records — the raw data
class LogRecords extends Table {
  IntColumn get id              => integer().autoIncrement()();
  TextColumn get dayDate        => text().references(Days, #date)();
  IntColumn get unixTime        => integer()();   // reconstructed unix timestamp
  IntColumn get tickMs          => integer()();   // raw tick from ESP32

  // ZombieVerter / Leaf inverter
  IntColumn get motorRpm        => integer()();
  RealColumn get motorTempC     => real()();
  RealColumn get inverterTempC  => real()();

  // ISA Shunt
  RealColumn get packCurrentA   => real()();      // negative = regen
  RealColumn get packVoltageV   => real()();
  RealColumn get ahUsed         => real()();

  // M3 BMS (0x35C)
  RealColumn get bmsTempMaxC    => real()();
  RealColumn get bmsTempMinC    => real()();
  IntColumn get cellVoltageMaxMv => integer()();
  IntColumn get cellVoltageMinMv => integer()();
  IntColumn get packVoltageBmsMv => integer()();

  // Which trip this record belongs to — null if outside any trip marker
  IntColumn get tripId => integer().nullable().references(Trips, #id)();
}

// ── Database class ───────────────────────────────────────────────────────────

@DriftDatabase(tables: [SyncSessions, Days, Trips, LogRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await customStatement('ALTER TABLE trips ADD COLUMN name TEXT');
      }
    },
  );

  // ── SyncSession queries ───────────────────────────────────────────────────

  Future<List<SyncSession>> getAllSyncSessions() =>
      select(syncSessions).get();

  Future<bool> isSessionSynced(int esp32SessionId) async {
    final row = await (select(syncSessions)
          ..where((s) => s.esp32SessionId.equals(esp32SessionId)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> insertSyncSession(SyncSessionsCompanion session) =>
      into(syncSessions).insert(session);

  // ── Day queries ───────────────────────────────────────────────────────────

  Future<List<Day>> getAllDays() =>
      (select(days)..orderBy([(d) => OrderingTerm.desc(d.date)])).get();

  // Stream version — Sessions screen rebuilds automatically when new data syncs in
  Stream<List<Day>> watchAllDays() =>
      (select(days)..orderBy([(d) => OrderingTerm.desc(d.date)])).watch();

  Future<Day?> getDayByDate(String date) =>
      (select(days)..where((d) => d.date.equals(date))).getSingleOrNull();

  Future<void> upsertDay(DaysCompanion day) =>
      into(days).insertOnConflictUpdate(day);

  // ── Trip queries ──────────────────────────────────────────────────────────

  Future<List<Trip>> getTripsForDay(String date) =>
      (select(trips)
            ..where((t) => t.dayDate.equals(date))
            ..orderBy([(t) => OrderingTerm.asc(t.tripNumber)]))
          .get();

  Future<int> insertTrip(TripsCompanion trip) =>
      into(trips).insert(trip);

  Future<void> updateTripName(int tripId, String? name) =>
      (update(trips)..where((t) => t.id.equals(tripId)))
          .write(TripsCompanion(name: Value(name)));

  Stream<List<Trip>> watchTripsForDay(String date) =>
      (select(trips)
            ..where((t) => t.dayDate.equals(date))
            ..orderBy([(t) => OrderingTerm.asc(t.tripNumber)]))
          .watch();

  // ── LogRecord queries ─────────────────────────────────────────────────────

  Future<void> insertLogRecords(List<LogRecordsCompanion> records) =>
      batch((b) => b.insertAll(logRecords, records));

  Future<List<LogRecord>> getRecordsForDay(String date) =>
      (select(logRecords)
            ..where((r) => r.dayDate.equals(date))
            ..orderBy([(r) => OrderingTerm.asc(r.unixTime)]))
          .get();

  Future<List<LogRecord>> getRecordsForTrip(int tripId) =>
      (select(logRecords)
            ..where((r) => r.tripId.equals(tripId))
            ..orderBy([(r) => OrderingTerm.asc(r.unixTime)]))
          .get();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'somerset_ev.db'));
    return NativeDatabase.createInBackground(file);
  });
}
