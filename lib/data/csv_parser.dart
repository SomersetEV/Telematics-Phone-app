// lib/data/csv_parser.dart
//
// Parses ESP32 snap_XXXX.csv session files (SNAP1 format) into database-ready records.
//
// SNAP1 row format (sd_logger.c write_snapshot):
//   Header: SNAP1,tick_ms,soc_pct,pack_v_bms_mv,pack_i_ma,isa_kw_w,isa_as,
//           motor_rpm,motor_temp_c10,inv_temp_c10,bms_tmax_c10,bms_tmin_c10,
//           cell_v_max_mv,cell_v_min_mv,charger_temp_c10
//   Data:   SNAP1,<tick_ms>,<values...>   (15 columns, p[0]="SNAP1", p[1]=tick_ms;
//           charger_temp_c10 at p[14] is optional — absent in pre-charger-temp CSVs;
//           the P4 dash appends unix_time at p[15], 0 while its clock is unset)
//   Markers: TRIP_START,,,,... / TRIP_END,<duration_s>,<ah>,<kwh>,<soc_start>,<soc_end>,<peak_a>,...
//
// Timestamps:
//   unix = offset + tickMs/1000, one offset per session (tick_ms never jumps
//   within a session, so rows stay evenly spaced).
//   - offset = unix_time − tick_ms/1000 from the last row carrying a real
//     unix_time. The phone's TIME command sets the dash clock on every
//     connect, so this dates sessions correctly however late they are synced.
//   - Otherwise (LilyGo files, or a clock never set): offset =
//     syncedAtUnix − maxTickMs/1000, which assumes the session ended when the
//     phone synced it.

import 'package:drift/drift.dart';
import 'database.dart';

class ParsedSession {
  final List<LogRecordsCompanion> records;
  final List<RawTrip> rawTrips;

  ParsedSession({required this.records, required this.rawTrips});
}

// Intermediate trip representation before database IDs are assigned
class RawTrip {
  final int startUnix;
  final int endUnix;
  final List<int> recordIndices; // indices into ParsedSession.records
  final int? socStart;           // from TRIP_END summary row
  final int? socEnd;

  // TRIP_START came before any data row. The dash writes that only when it
  // carries a running trip into a new session (after a power cut, or a
  // file reopened after a write error), so this continues an open job.
  final bool continuesPrevious;

  // Ended by a TRIP_END row. False when the file just stopped (a power cut),
  // and the job may carry on in the next session.
  final bool closed;

  RawTrip({
    required this.startUnix,
    required this.endUnix,
    required this.recordIndices,
    this.socStart,
    this.socEnd,
    this.continuesPrevious = false,
    this.closed = true,
  });
}

class _VehicleState {
  int    motorRpm         = 0;
  double motorTempC       = 0;
  double inverterTempC    = 0;
  double packCurrentA     = 0;
  double packVoltageV     = 0;  // not in SNAP1 (ISA shunt voltage); always 0
  double packKw           = 0;
  double ahUsed           = 0;
  int    socPct           = 0;
  double bmsTempMaxC      = 0;
  double bmsTempMinC      = 0;
  int    cellVoltageMaxMv = 0;
  int    cellVoltageMinMv = 0;
  int    packVoltageBmsMv = 0;
  double chargerTempC     = 0;
}

class CsvParser {
  /// Parse a SNAP1 session CSV string.
  ///
  /// [csvContent]     Raw CSV text from ESP32 (snap_XXXX.csv)
  /// [esp32SessionId] Session number (for logging/debugging)
  /// [syncedAtUnix]   Unix timestamp when phone downloaded this session
  static ParsedSession parse({
    required String csvContent,
    required int esp32SessionId,
    required int syncedAtUnix,
  }) {
    final lines = csvContent.split('\n');
    if (lines.isEmpty) return ParsedSession(records: [], rawTrips: []);

    // Skip header row; work on data lines only
    final dataLines = lines.skip(1).where((l) => l.trim().isNotEmpty).toList();
    if (dataLines.isEmpty) return ParsedSession(records: [], rawTrips: []);

    return _parseSnap(dataLines, syncedAtUnix);
  }

  // ── SNAP1 parser ──────────────────────────────────────────────────────────
  // Each data row is already decoded by the ESP32 at 1 Hz.
  // Columns: p[0]="SNAP1", p[1]=tick_ms, p[2]=soc_pct, p[3]=pack_v_bms_mv,
  //          p[4]=pack_i_ma, p[5]=isa_kw_w, p[6]=isa_as,
  //          p[7]=motor_rpm, p[8]=motor_temp_c10, p[9]=inv_temp_c10,
  //          p[10]=bms_tmax_c10, p[11]=bms_tmin_c10,
  //          p[12]=cell_v_max_mv, p[13]=cell_v_min_mv,
  //          p[14]=charger_temp_c10 (optional)

  // Earliest plausible unix_time; the dash writes 0 while its clock is unset.
  static const int _minValidUnix = 1577836800;  // 2020-01-01

  static ParsedSession _parseSnap(List<String> dataLines, int syncedAtUnix) {
    int  maxTickMs    = 0;
    int? clockOffset;   // unix − tick_s, from the last row with a real unix_time
    for (final line in dataLines.reversed) {
      if (line.startsWith('TRIP_')) continue;
      final p = line.split(',');
      if (p.length < 2) continue;
      final tick = int.tryParse(p[1]) ?? 0;
      if (tick <= 0) continue;
      if (maxTickMs == 0) maxTickMs = tick;
      final unix = p.length > 15 ? int.tryParse(p[15].trim()) : null;
      if (unix != null && unix >= _minValidUnix) {
        clockOffset = unix - tick ~/ 1000;
        break;
      }
      // LilyGo files never carry unix_time; don't scan them end to end.
      if (p.length <= 15) break;
    }
    final int offset = clockOffset ?? syncedAtUnix - (maxTickMs ~/ 1000);

    final List<LogRecordsCompanion> records = [];
    final List<RawTrip>             rawTrips = [];

    int? tripStartUnix;
    int? tripSocStart;
    bool tripContinues = false;
    List<int> tripIndices = [];

    for (final line in dataLines) {
      if (line.startsWith('TRIP_START')) {
        tripStartUnix = -1;
        // Null when the trip opens the file; taken from its first row below.
        tripSocStart  = records.isNotEmpty ? records.last.socPct.value : null;
        tripContinues = records.isEmpty;
        tripIndices   = [];
        continue;
      }

      if (line.startsWith('TRIP_END')) {
        if (tripStartUnix != null && tripStartUnix > 0 && tripIndices.isNotEmpty) {
          final endParts = line.split(',');
          final int? socEnd = endParts.length > 5 ? int.tryParse(endParts[5]) : null;
          rawTrips.add(RawTrip(
            startUnix:     tripStartUnix,
            endUnix:       records[tripIndices.last].unixTime.value,
            recordIndices: List.from(tripIndices),
            socStart:      tripSocStart,
            socEnd:        socEnd ?? (records.isNotEmpty ? records.last.socPct.value : 0),
            continuesPrevious: tripContinues,
          ));
        }
        tripStartUnix = null;
        tripSocStart  = null;
        tripIndices   = [];
        continue;
      }

      final p = line.split(',');
      if (p.length < 14) continue;

      final int tickMs   = int.tryParse(p[1]) ?? 0;
      final int unixTime = offset + (tickMs ~/ 1000);

      final state = _VehicleState()
        ..socPct           = int.tryParse(p[2])  ?? 0
        ..packVoltageBmsMv = int.tryParse(p[3])  ?? 0
        ..packCurrentA     = (int.tryParse(p[4])  ?? 0) / 1000.0
        ..packKw           = (int.tryParse(p[5])  ?? 0) / 1000.0
        ..ahUsed           = (int.tryParse(p[6])  ?? 0) / 3600.0
        ..motorRpm         = int.tryParse(p[7])  ?? 0
        ..motorTempC       = (int.tryParse(p[8])  ?? 0) / 10.0
        ..inverterTempC    = (int.tryParse(p[9])  ?? 0) / 10.0
        ..bmsTempMaxC      = (int.tryParse(p[10]) ?? 0) / 10.0
        ..bmsTempMinC      = (int.tryParse(p[11]) ?? 0) / 10.0
        ..cellVoltageMaxMv = int.tryParse(p[12]) ?? 0
        ..cellVoltageMinMv = int.tryParse(p[13]) ?? 0
        // charger_temp_c10 (p[14]) added later — older 14-column CSVs lack it
        ..chargerTempC     = (p.length > 14 ? (int.tryParse(p[14]) ?? 0) : 0) / 10.0;

      final companion   = _makeRecord(unixTime, tickMs, state);
      final recordIndex = records.length;
      records.add(companion);

      if (tripStartUnix != null) {
        if (tripStartUnix == -1) tripStartUnix = unixTime;
        tripSocStart ??= state.socPct;
        tripIndices.add(recordIndex);
      }
    }

    if (tripStartUnix != null && tripStartUnix > 0 && tripIndices.isNotEmpty) {
      rawTrips.add(RawTrip(
        startUnix:     tripStartUnix,
        endUnix:       records[tripIndices.last].unixTime.value,
        recordIndices: List.from(tripIndices),
        socStart:      tripSocStart,
        socEnd:        records.isNotEmpty ? records.last.socPct.value : 0,
        continuesPrevious: tripContinues,
        closed:        false,
      ));
    }

    return ParsedSession(records: records, rawTrips: rawTrips);
  }

  static LogRecordsCompanion _makeRecord(int unixTime, int tickMs, _VehicleState s) =>
      LogRecordsCompanion(
        dayDate:          Value(_unixToDateString(unixTime)),
        unixTime:         Value(unixTime),
        tickMs:           Value(tickMs),
        motorRpm:         Value(s.motorRpm),
        motorTempC:       Value(s.motorTempC),
        inverterTempC:    Value(s.inverterTempC),
        packCurrentA:     Value(s.packCurrentA),
        packVoltageV:     Value(s.packVoltageV),
        packKw:           Value(s.packKw),
        ahUsed:           Value(s.ahUsed),
        socPct:           Value(s.socPct),
        bmsTempMaxC:      Value(s.bmsTempMaxC),
        bmsTempMinC:      Value(s.bmsTempMinC),
        cellVoltageMaxMv: Value(s.cellVoltageMaxMv),
        cellVoltageMinMv: Value(s.cellVoltageMinMv),
        packVoltageBmsMv: Value(s.packVoltageBmsMv),
        chargerTempC:     Value(s.chargerTempC),
        tripId:           const Value(null),
      );

  static String _unixToDateString(int unixSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000, isUtc: false);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

// ── Day and trip stats aggregation ───────────────────────────────────────────

class StatsAggregator {
  /// Build a DaysCompanion from a list of records for that date.
  static DaysCompanion buildDay({
    required String date,
    required List<LogRecordsCompanion> records,
  }) {
    if (records.isEmpty) {
      return DaysCompanion(
        date:              Value(date),
        totalDurationSecs: const Value(0),
        totalAh:           const Value(0),
        totalKwh:          const Value(0.0),
        peakMotorTempC:    const Value(0),
        peakInverterTempC: const Value(0),
        peakBmsTempC:      const Value(0),
        peakCurrentA:      const Value(0),
        peakRpm:           const Value(0),
        peakSocPct:        const Value(0),
      );
    }

    final ticks      = records.map((r) => r.tickMs.value).toList()..sort();
    final durationMs = ticks.last - ticks.first;

    final ahFirst = records.first.ahUsed.value;
    final ahLast  = records.last.ahUsed.value;
    final totalAh = (ahLast - ahFirst).abs();

    return DaysCompanion(
      date:              Value(date),
      totalDurationSecs: Value(durationMs ~/ 1000),
      totalAh:           Value(totalAh),
      totalKwh:          Value(
        records.map((r) => r.packKw.value).fold(0.0, (a, b) => a + b).abs() / 3600.0,
      ),
      peakMotorTempC:    Value(records.map((r) => r.motorTempC.value).reduce((a, b) => a > b ? a : b)),
      peakInverterTempC: Value(records.map((r) => r.inverterTempC.value).reduce((a, b) => a > b ? a : b)),
      peakBmsTempC:      Value(records.map((r) => r.bmsTempMaxC.value).reduce((a, b) => a > b ? a : b)),
      peakCurrentA:      Value(records.map((r) => r.packCurrentA.value.abs()).reduce((a, b) => a > b ? a : b)),
      peakRpm:           Value(records.map((r) => r.motorRpm.value).reduce((a, b) => a > b ? a : b)),
      peakSocPct:        Value(records.map((r) => r.socPct.value).reduce((a, b) => a > b ? a : b)),
    );
  }

  /// Build a TripsCompanion from the records within a trip.
  static TripsCompanion buildTrip({
    required String dayDate,
    required int tripNumber,
    required RawTrip rawTrip,
    required List<LogRecordsCompanion> tripRecords,
  }) {
    final ahFirst    = tripRecords.first.ahUsed.value;
    final ahLast     = tripRecords.last.ahUsed.value;
    final ahConsumed = (ahLast - ahFirst).abs();

    return TripsCompanion(
      dayDate:           Value(dayDate),
      tripNumber:        Value(tripNumber),
      startUnix:         Value(rawTrip.startUnix),
      endUnix:           Value(rawTrip.endUnix),
      durationSecs:      Value(rawTrip.endUnix - rawTrip.startUnix),
      ahConsumed:        Value(ahConsumed),
      kwhConsumed:       Value(
        tripRecords.map((r) => r.packKw.value).fold(0.0, (a, b) => a + b).abs() / 3600.0,
      ),
      peakRpm:           Value(tripRecords.map((r) => r.motorRpm.value).reduce((a, b) => a > b ? a : b)),
      peakMotorTempC:    Value(tripRecords.map((r) => r.motorTempC.value).reduce((a, b) => a > b ? a : b)),
      peakInverterTempC: Value(tripRecords.map((r) => r.inverterTempC.value).reduce((a, b) => a > b ? a : b)),
      peakBmsTempC:      Value(tripRecords.map((r) => r.bmsTempMaxC.value).reduce((a, b) => a > b ? a : b)),
      peakCurrentA:      Value(tripRecords.map((r) => r.packCurrentA.value.abs()).reduce((a, b) => a > b ? a : b)),
      socStart:          Value(rawTrip.socStart),
      socEnd:            Value(rawTrip.socEnd),
    );
  }
}
