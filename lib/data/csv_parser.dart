// lib/data/csv_parser.dart
//
// Parses ESP32 session CSV files into database-ready records.
//
// CSV format (from sd_logger.c):
//   tick_ms,unix_time,motor_rpm,motor_temp_c,inverter_temp_c,
//   pack_current_a,pack_voltage_v,ah_used,
//   bms_temp_max_c,bms_temp_min_c,
//   cell_v_max_mv,cell_v_min_mv,pack_v_bms_mv
//
// Special marker rows (written by ESP32 on TRIP_START / TRIP_END commands):
//   TRIP_START,,,,,,,,,,,,,
//   TRIP_END,,,,,,,,,,,,,,,
//
// Timestamp reconstruction:
//   If unix_time column is non-zero → use directly
//   If zero → use bestEffortOffsetSeconds + (tick_ms / 1000)
//     bestEffortOffsetSeconds = synced_at_unix - session_last_tick_ms / 1000
//     i.e. we assume the session ended approximately when the phone synced it,
//     then work backwards using each record's tick position.

import 'package:drift/drift.dart';
import 'database.dart';

class ParsedSession {
  final List<LogRecordsCompanion> records;
  final List<_RawTrip> rawTrips;

  ParsedSession({required this.records, required this.rawTrips});
}

// Intermediate trip representation before database IDs are assigned
class _RawTrip {
  final int startUnix;
  final int endUnix;
  final List<int> recordIndices;  // indices into ParsedSession.records

  _RawTrip({
    required this.startUnix,
    required this.endUnix,
    required this.recordIndices,
  });
}

class CsvParser {
  /// Parse a complete session CSV string.
  ///
  /// [csvContent]              Raw CSV text from ESP32
  /// [esp32SessionId]          Session number (for logging/debugging)
  /// [syncedAtUnix]            Unix timestamp when phone downloaded this session
  ///                           Used for best-effort timestamp reconstruction
  static ParsedSession parse({
    required String csvContent,
    required int esp32SessionId,
    required int syncedAtUnix,
  }) {
    final lines = csvContent.split('\n');
    if (lines.isEmpty) return ParsedSession(records: [], rawTrips: []);

    // Skip header row
    final dataLines = lines.skip(1).where((l) => l.trim().isNotEmpty).toList();
    if (dataLines.isEmpty) return ParsedSession(records: [], rawTrips: []);

    // ── Best-effort offset calculation ────────────────────────────────────
    // Find the last data row (not a marker) to get max tick_ms for this session
    int maxTickMs = 0;
    for (final line in dataLines.reversed) {
      if (line.startsWith('TRIP_')) continue;
      final parts = line.split(',');
      if (parts.isNotEmpty) {
        maxTickMs = int.tryParse(parts[0]) ?? 0;
        if (maxTickMs > 0) break;
      }
    }
    // bestEffortOffset: unix time of tick_ms = 0 for this session
    // = syncedAtUnix - maxTickMs/1000  (assumes session ended ~at sync time)
    final int bestEffortOffset = syncedAtUnix - (maxTickMs ~/ 1000);

    // ── Parse records and trip markers ────────────────────────────────────
    final List<LogRecordsCompanion> records = [];
    final List<_RawTrip> rawTrips           = [];

    int? tripStartUnix;
    List<int> currentTripIndices = [];

    for (final line in dataLines) {
      // ── Trip markers ─────────────────────────────────────────────────────
      if (line.startsWith('TRIP_START')) {
        // Use the unix time of the next data record as trip start
        // We set a flag here and assign startUnix on the next data row
        tripStartUnix        = null;  // will be set on next data row
        currentTripIndices   = [];
        // Sentinel value — parser sees this as "trip is open, waiting for first record"
        tripStartUnix        = -1;
        continue;
      }

      if (line.startsWith('TRIP_END')) {
        if (tripStartUnix != null && tripStartUnix > 0 && currentTripIndices.isNotEmpty) {
          // Use unix time of last record in trip as end time
          final lastRecord = records[currentTripIndices.last];
          final endUnix    = lastRecord.unixTime.value;
          rawTrips.add(_RawTrip(
            startUnix:      tripStartUnix,
            endUnix:        endUnix,
            recordIndices:  List.from(currentTripIndices),
          ));
        }
        tripStartUnix      = null;
        currentTripIndices = [];
        continue;
      }

      // ── Data row ──────────────────────────────────────────────────────────
      final record = _parseDataRow(
        line:               line,
        bestEffortOffset:   bestEffortOffset,
      );
      if (record == null) continue;

      final recordIndex = records.length;
      records.add(record);

      // If a trip is open, track this record
      if (tripStartUnix != null) {
        if (tripStartUnix == -1) {
          // First record after TRIP_START — assign start time
          tripStartUnix = record.unixTime.value;
        }
        currentTripIndices.add(recordIndex);
      }
    }

    // If session ended with an open trip (no TRIP_END written — e.g. power cut)
    // close it at the last record
    if (tripStartUnix != null && tripStartUnix > 0 && currentTripIndices.isNotEmpty) {
      final lastRecord = records[currentTripIndices.last];
      rawTrips.add(_RawTrip(
        startUnix:     tripStartUnix,
        endUnix:       lastRecord.unixTime.value,
        recordIndices: List.from(currentTripIndices),
      ));
    }

    return ParsedSession(records: records, rawTrips: rawTrips);
  }

  static LogRecordsCompanion? _parseDataRow({
    required String line,
    required int bestEffortOffset,
  }) {
    final parts = line.split(',');
    if (parts.length < 13) return null;

    try {
      final tickMs   = int.parse(parts[0]);
      int unixTime   = int.tryParse(parts[1]) ?? 0;

      // Best-effort reconstruction if no unix time recorded
      if (unixTime == 0) {
        unixTime = bestEffortOffset + (tickMs ~/ 1000);
      }

      // Derive calendar date string for day grouping
      final date     = _unixToDateString(unixTime);

      return LogRecordsCompanion(
        dayDate:           Value(date),
        unixTime:          Value(unixTime),
        tickMs:            Value(tickMs),
        motorRpm:          Value(int.tryParse(parts[2])    ?? 0),
        motorTempC:        Value(double.tryParse(parts[3]) ?? 0.0),
        inverterTempC:     Value(double.tryParse(parts[4]) ?? 0.0),
        packCurrentA:      Value(double.tryParse(parts[5]) ?? 0.0),
        packVoltageV:      Value(double.tryParse(parts[6]) ?? 0.0),
        ahUsed:            Value(double.tryParse(parts[7]) ?? 0.0),
        bmsTempMaxC:       Value(double.tryParse(parts[8]) ?? 0.0),
        bmsTempMinC:       Value(double.tryParse(parts[9]) ?? 0.0),
        cellVoltageMaxMv:  Value(int.tryParse(parts[10])   ?? 0),
        cellVoltageMinMv:  Value(int.tryParse(parts[11])   ?? 0),
        packVoltageBmsMv:  Value(int.tryParse(parts[12])   ?? 0),
        tripId:            const Value(null),  // assigned after trip insertion
      );
    } catch (e) {
      // Malformed row — skip silently
      return null;
    }
  }

  static String _unixToDateString(int unixSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000, isUtc: false);
    return '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
  }
}

// ── Day and trip stats aggregation ───────────────────────────────────────────
//
// After inserting records, call these to build the summary rows.

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
        peakMotorTempC:    const Value(0),
        peakInverterTempC: const Value(0),
        peakBmsTempC:      const Value(0),
        peakCurrentA:      const Value(0),
        peakRpm:           const Value(0),
      );
    }

    final ticks      = records.map((r) => r.tickMs.value).toList()..sort();
    final durationMs = ticks.last - ticks.first;

    // Ah consumed: difference between first and last ah_used reading
    final ahFirst = records.first.ahUsed.value;
    final ahLast  = records.last.ahUsed.value;
    final totalAh = (ahLast - ahFirst).abs();

    return DaysCompanion(
      date:              Value(date),
      totalDurationSecs: Value(durationMs ~/ 1000),
      totalAh:           Value(totalAh),
      peakMotorTempC:    Value(records.map((r) => r.motorTempC.value).reduce((a,b) => a>b?a:b)),
      peakInverterTempC: Value(records.map((r) => r.inverterTempC.value).reduce((a,b) => a>b?a:b)),
      peakBmsTempC:      Value(records.map((r) => r.bmsTempMaxC.value).reduce((a,b) => a>b?a:b)),
      peakCurrentA:      Value(records.map((r) => r.packCurrentA.value.abs()).reduce((a,b) => a>b?a:b)),
      peakRpm:           Value(records.map((r) => r.motorRpm.value).reduce((a,b) => a>b?a:b)),
    );
  }

  /// Build a TripsCompanion from the records within a trip.
  static TripsCompanion buildTrip({
    required String dayDate,
    required int tripNumber,
    required _RawTrip rawTrip,
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
      peakRpm:           Value(tripRecords.map((r) => r.motorRpm.value).reduce((a,b) => a>b?a:b)),
      peakMotorTempC:    Value(tripRecords.map((r) => r.motorTempC.value).reduce((a,b) => a>b?a:b)),
      peakInverterTempC: Value(tripRecords.map((r) => r.inverterTempC.value).reduce((a,b) => a>b?a:b)),
      peakBmsTempC:      Value(tripRecords.map((r) => r.bmsTempMaxC.value).reduce((a,b) => a>b?a:b)),
      peakCurrentA:      Value(tripRecords.map((r) => r.packCurrentA.value.abs()).reduce((a,b) => a>b?a:b)),
    );
  }
}
