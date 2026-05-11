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

    // Skip header row
    final dataLines = lines.skip(1).where((l) => l.trim().isNotEmpty).toList();
    if (dataLines.isEmpty) return ParsedSession(records: [], rawTrips: []);

    // ── Best-effort offset calculation ────────────────────────────────────
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

    // ── Parse frames and build 1Hz snapshots ──────────────────────────────
    final List<LogRecordsCompanion> records = [];
    final List<RawTrip> rawTrips            = [];

    final state = _VehicleState();
    int lastEmittedSecond = -1;

    int? tripStartUnix;
    int? tripSocStart;
    List<int> currentTripIndices = [];

    for (final line in dataLines) {
      // ── Trip markers ─────────────────────────────────────────────────────
      if (line.startsWith('TRIP_START')) {
        tripStartUnix      = -1; // sentinel: assign on first data row
        tripSocStart       = state.socPct;
        currentTripIndices = [];
        continue;
      }

      if (line.startsWith('TRIP_END')) {
        if (tripStartUnix != null && tripStartUnix > 0 && currentTripIndices.isNotEmpty) {
          final lastRecord = records[currentTripIndices.last];
          // Parse TRIP_END summary columns: duration_s, ah_used, kwh_used, soc_start%, soc_end%, peak_a
          final endParts = line.split(',');
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

      // ── CAN frame row ─────────────────────────────────────────────────────
      final parts = line.split(',');
      if (parts.length < 13) continue;

      final int tickMs   = int.tryParse(parts[0]) ?? 0;
      final int canId    = _parseHex(parts[1]);
      if (canId == 0) continue;

      // Byte array: parts[5..12] = D1..D8 (2-digit uppercase hex, no 0x prefix)
      final bytes = List<int>.filled(8, 0);
      for (int i = 0; i < 8; i++) {
        bytes[i] = int.tryParse(parts[5 + i], radix: 16) ?? 0;
      }

      _decodeFrame(canId, bytes, state);

      // ── 1Hz snapshot emission ─────────────────────────────────────────────
      final int currentSecond = bestEffortOffset + (tickMs ~/ 1000);
      if (currentSecond > lastEmittedSecond) {
        lastEmittedSecond = currentSecond;
        final date       = _unixToDateString(currentSecond);
        final companion  = LogRecordsCompanion(
          dayDate:           Value(date),
          unixTime:          Value(currentSecond),
          tickMs:            Value(tickMs),
          motorRpm:          Value(state.motorRpm),
          motorTempC:        Value(state.motorTempC),
          inverterTempC:     Value(state.inverterTempC),
          packCurrentA:      Value(state.packCurrentA),
          packVoltageV:      Value(state.packVoltageV),
          packKw:            Value(state.packKw),
          ahUsed:            Value(state.ahUsed),
          socPct:            Value(state.socPct),
          bmsTempMaxC:       Value(state.bmsTempMaxC),
          bmsTempMinC:       Value(state.bmsTempMinC),
          cellVoltageMaxMv:  Value(state.cellVoltageMaxMv),
          cellVoltageMinMv:  Value(state.cellVoltageMinMv),
          packVoltageBmsMv:  Value(state.packVoltageBmsMv),
          tripId:            const Value(null),
        );

        final recordIndex = records.length;
        records.add(companion);

        if (tripStartUnix != null) {
          if (tripStartUnix == -1) {
            tripStartUnix = currentSecond;
          }
          currentTripIndices.add(recordIndex);
        }
      }
    }

    // Close any trip left open (e.g. power cut before TRIP_END)
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

      case 0x521: // ISA shunt — pack current (mA, big-endian int32 bytes 2-5)
        s.packCurrentA = _beInt32(b, 2) / 1000.0;

      case 0x522: // ISA shunt — pack voltage (mV, big-endian int32 bytes 2-5)
        s.packVoltageV = _beInt32(b, 2) / 1000.0;

      case 0x526: // ISA shunt — power (W, big-endian int32 bytes 2-5)
        s.packKw = _beInt32(b, 2) / 1000.0;

      case 0x527: // ISA shunt — amp-seconds (big-endian int32 bytes 2-5)
        s.ahUsed = _beInt32(b, 2) / 3600.0;

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

  // ── Helpers ───────────────────────────────────────────────────────────────

  // Big-endian signed int32 from bytes[offset..offset+3]
  static int _beInt32(List<int> b, int offset) {
    final unsigned = (b[offset] << 24) |
                     (b[offset + 1] << 16) |
                     (b[offset + 2] << 8) |
                      b[offset + 3];
    // Sign-extend to Dart int (already 64-bit, but mask to 32-bit first)
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
