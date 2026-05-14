// lib/data/csv_parser.dart
//
// Parses ESP32 raw CAN CSV session files into database-ready records.
//
// CSV format (from sd_logger.c):
//   tick_ms,can_id,dlc,b0,b1,b2,b3,b4,b5,b6,b7
//
// Every known CAN frame is logged at full bus rate. This parser accumulates
// vehicle state from each frame and emits one LogRecord snapshot per second.
//
// Special marker rows (written by ESP32 on TRIP_START / TRIP_END commands):
//   TRIP_START,,,,,,,,,,,
//   TRIP_END,<duration_s>,<ah_used>,<kwh_used>,<soc_start%>,<soc_end%>,<peak_current_a>,,,,
//
// Timestamp reconstruction:
//   After the phone sends a TIME command, the ESP32 stores a unix offset.
//   Reconstructed unix = bestEffortOffset + (tick_ms / 1000)
//     bestEffortOffset = syncedAtUnix - maxTickMs/1000
//     i.e. we assume the session ended approximately when the phone synced it.

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

  RawTrip({
    required this.startUnix,
    required this.endUnix,
    required this.recordIndices,
    this.socStart,
    this.socEnd,
  });
}

// Running vehicle state — updated per CAN frame, snapshotted once per second
class _VehicleState {
  int motorRpm         = 0;
  double motorTempC    = 0;
  double inverterTempC = 0;
  double packCurrentA  = 0;
  double packVoltageV  = 0;
  double packKw        = 0;
  double ahUsed        = 0;
  int socPct           = 0;
  double bmsTempMaxC   = 0;
  double bmsTempMinC   = 0;
  int cellVoltageMaxMv = 0;
  int cellVoltageMinMv = 0;
  int packVoltageBmsMv = 0;
}

class CsvParser {
  /// Parse a complete session CSV string.
  ///
  /// [csvContent]     Raw CSV text from ESP32
  /// [esp32SessionId] Session number (for logging/debugging)
  /// [syncedAtUnix]   Unix timestamp when phone downloaded this session
  static ParsedSession parse({
    required String csvContent,
    required int esp32SessionId,
    required int syncedAtUnix,
  }) {
    final lines = csvContent.split('\n');
    if (lines.isEmpty) return ParsedSession(records: [], rawTrips: []);

    // Detect format from first line:
    //   SNAP1:  "SNAP1,tick_ms,..."           — 1Hz pre-decoded snapshot (new, fast)
    //   GVRET:  "Time Stamp,ID,Extended,..."  — raw CAN frames, hex bytes
    //   Legacy: "tick_ms,can_id,dlc,..."      — raw CAN frames, decimal bytes
    final header = lines.first.trim();

    // Skip header row; work on data lines only
    final dataLines = lines.skip(1).where((l) => l.trim().isNotEmpty).toList();
    if (dataLines.isEmpty) return ParsedSession(records: [], rawTrips: []);

    if (header.startsWith('SNAP1')) {
      return _parseSnap(dataLines, syncedAtUnix);
    }

    // ── GVRET / Legacy raw-frame path ─────────────────────────────────────
    final bool isGvret    = header.startsWith('Time Stamp');
    final int  minCols    = isGvret ? 13 : 11;
    final int  byteOffset = isGvret ? 5  : 3;
    final int  byteRadix  = isGvret ? 16 : 10;

    // Find the last data row's tick_ms to anchor timestamps
    int maxTickMs = 0;
    for (final line in dataLines.reversed) {
      if (line.startsWith('TRIP_')) continue;
      final parts = line.split(',');
      if (parts.isNotEmpty) {
        maxTickMs = int.tryParse(parts[0]) ?? 0;
        if (maxTickMs > 0) break;
      }
    }
    final int bestEffortOffset = syncedAtUnix - (maxTickMs ~/ 1000);

    final List<LogRecordsCompanion> records = [];
    final List<RawTrip> rawTrips            = [];

    final state = _VehicleState();
    int lastEmittedSecond = -1;

    int? tripStartUnix;
    int? tripSocStart;
    List<int> currentTripIndices = [];

    for (final line in dataLines) {
      if (line.startsWith('TRIP_START')) {
        tripStartUnix      = -1;
        tripSocStart       = state.socPct;
        currentTripIndices = [];
        continue;
      }

      if (line.startsWith('TRIP_END')) {
        if (tripStartUnix != null && tripStartUnix > 0 && currentTripIndices.isNotEmpty) {
          final lastRecord = records[currentTripIndices.last];
          final endParts   = line.split(',');
          final int? socEnd = endParts.length > 5 ? int.tryParse(endParts[5]) : null;
          rawTrips.add(RawTrip(
            startUnix:     tripStartUnix,
            endUnix:       lastRecord.unixTime.value,
            recordIndices: List.from(currentTripIndices),
            socStart:      tripSocStart,
            socEnd:        socEnd ?? state.socPct,
          ));
        }
        tripStartUnix      = null;
        tripSocStart       = null;
        currentTripIndices = [];
        continue;
      }

      final parts = line.split(',');
      if (parts.length < minCols) continue;

      final int tickMs = int.tryParse(parts[0]) ?? 0;
      final int canId  = _parseHex(parts[1]);
      if (canId == 0) continue;

      final bytes = List<int>.filled(8, 0);
      for (int i = 0; i < 8; i++) {
        bytes[i] = int.tryParse(parts[byteOffset + i], radix: byteRadix) ?? 0;
      }
      _decodeFrame(canId, bytes, state);

      final int currentSecond = bestEffortOffset + (tickMs ~/ 1000);
      if (currentSecond > lastEmittedSecond) {
        lastEmittedSecond = currentSecond;
        final companion   = _makeRecord(currentSecond, tickMs, state);
        final recordIndex = records.length;
        records.add(companion);

        if (tripStartUnix != null) {
          if (tripStartUnix == -1) tripStartUnix = currentSecond;
          currentTripIndices.add(recordIndex);
        }
      }
    }

    if (tripStartUnix != null && tripStartUnix > 0 && currentTripIndices.isNotEmpty) {
      final lastRecord = records[currentTripIndices.last];
      rawTrips.add(RawTrip(
        startUnix:     tripStartUnix,
        endUnix:       lastRecord.unixTime.value,
        recordIndices: List.from(currentTripIndices),
        socStart:      tripSocStart,
        socEnd:        state.socPct,
      ));
    }

    return ParsedSession(records: records, rawTrips: rawTrips);
  }

  // ── CAN frame decoder ─────────────────────────────────────────────────────

  static void _decodeFrame(int canId, List<int> b, _VehicleState s) {
    switch (canId) {
      case 0x1DA: // Nissan Leaf inverter — motor RPM (15-bit signed)
        final raw = (b[4] << 7) | (b[5] >> 1);
        if (b[4] == 0xFF && b[5] == 0xFF) {
          s.motorRpm = 0; // invalid marker
        } else {
          // Sign-extend from bit 14
          s.motorRpm = (raw & 0x4000) != 0 ? (raw | ~0x7FFF) : raw;
        }

      case 0x55A: // Nissan Leaf inverter — temps (Fahrenheit)
        s.motorTempC    = _fahrenheitToCelsius(b[1]);
        s.inverterTempC = _fahrenheitToCelsius(b[2]);

      case 0x521: // ISA shunt — pack current (mA, little-endian int32 bytes 2-5)
        s.packCurrentA = _leInt32(b, 2) / 1000.0;

      case 0x522: // ISA shunt — pack voltage (mV, little-endian int32 bytes 2-5)
        s.packVoltageV = _leInt32(b, 2) / 1000.0;

      case 0x526: // ISA shunt — power (W, little-endian int32 bytes 2-5)
        s.packKw = _leInt32(b, 2) / 1000.0;

      case 0x527: // ISA shunt — amp-seconds (little-endian int32 bytes 2-5)
        s.ahUsed = _leInt32(b, 2) / 3600.0;

      case 0x355: // M3 BMS — state of charge
        s.socPct = b[0];

      case 0x356: // M3 BMS — pack voltage (0.01V units, little-endian bytes 0-1)
        s.packVoltageBmsMv = _leUint16(b, 0) * 10;

      case 0x373: // M3 BMS — cell voltages + temps
        s.cellVoltageMinMv = _leUint16(b, 0);
        s.cellVoltageMaxMv = _leUint16(b, 2);
        // Temperatures are in raw Kelvin (little-endian); subtract 273 for °C
        s.bmsTempMinC = (_leUint16(b, 4) - 273).toDouble();
        s.bmsTempMaxC = (_leUint16(b, 6) - 273).toDouble();
    }
  }

  // ── SNAP1 parser ──────────────────────────────────────────────────────────
  // Columns: tick_ms,soc_pct,pack_v_bms_mv,pack_i_ma,isa_kw_w,isa_as,
  //          motor_rpm,motor_temp_c10,inv_temp_c10,bms_tmax_c10,bms_tmin_c10,
  //          cell_v_max_mv,cell_v_min_mv  (13 columns)

  static ParsedSession _parseSnap(List<String> dataLines, int syncedAtUnix) {
    int maxTickMs = 0;
    for (final line in dataLines.reversed) {
      if (line.startsWith('TRIP_')) continue;
      final p = line.split(',');
      maxTickMs = int.tryParse(p[0]) ?? 0;
      if (maxTickMs > 0) break;
    }
    final int offset = syncedAtUnix - (maxTickMs ~/ 1000);

    final List<LogRecordsCompanion> records = [];
    final List<RawTrip>             rawTrips = [];

    int? tripStartUnix;
    int? tripSocStart;
    List<int> tripIndices = [];

    for (final line in dataLines) {
      if (line.startsWith('TRIP_START')) {
        tripStartUnix = -1;
        tripSocStart  = records.isNotEmpty ? records.last.socPct.value : 0;
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
          ));
        }
        tripStartUnix = null;
        tripSocStart  = null;
        tripIndices   = [];
        continue;
      }

      final p = line.split(',');
      if (p.length < 13) continue;

      final int tickMs   = int.tryParse(p[0]) ?? 0;
      final int unixTime = offset + (tickMs ~/ 1000);

      final state = _VehicleState()
        ..socPct           = int.tryParse(p[1])  ?? 0
        ..packVoltageBmsMv = int.tryParse(p[2])  ?? 0
        ..packCurrentA     = (int.tryParse(p[3])  ?? 0) / 1000.0
        ..packKw           = (int.tryParse(p[4])  ?? 0) / 1000.0
        ..ahUsed           = (int.tryParse(p[5])  ?? 0) / 3600.0
        ..motorRpm         = int.tryParse(p[6])  ?? 0
        ..motorTempC       = (int.tryParse(p[7])  ?? 0) / 10.0
        ..inverterTempC    = (int.tryParse(p[8])  ?? 0) / 10.0
        ..bmsTempMaxC      = (int.tryParse(p[9])  ?? 0) / 10.0
        ..bmsTempMinC      = (int.tryParse(p[10]) ?? 0) / 10.0
        ..cellVoltageMaxMv = int.tryParse(p[11]) ?? 0
        ..cellVoltageMinMv = int.tryParse(p[12]) ?? 0;

      final companion   = _makeRecord(unixTime, tickMs, state);
      final recordIndex = records.length;
      records.add(companion);

      if (tripStartUnix != null) {
        if (tripStartUnix == -1) tripStartUnix = unixTime;
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
        tripId:           const Value(null),
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  // Little-endian signed int32 from bytes[offset..offset+3] (ISA IVT-S format)
  static int _leInt32(List<int> b, int offset) {
    final unsigned =  b[offset] |
                     (b[offset + 1] << 8) |
                     (b[offset + 2] << 16) |
                     (b[offset + 3] << 24);
    final masked = unsigned & 0xFFFFFFFF;
    return masked >= 0x80000000 ? masked - 0x100000000 : masked;
  }

  // Little-endian unsigned int16 from bytes[offset..offset+1]
  static int _leUint16(List<int> b, int offset) =>
      (b[offset + 1] << 8) | b[offset];

  static double _fahrenheitToCelsius(int f) => (f - 32) * 5.0 / 9.0;

  // Parse "0x1DA" or "443" style CAN ID strings
  static int _parseHex(String s) {
    final trimmed = s.trim();
    if (trimmed.startsWith('0x') || trimmed.startsWith('0X')) {
      return int.tryParse(trimmed.substring(2), radix: 16) ?? 0;
    }
    return int.tryParse(trimmed) ?? 0;
  }

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
