// test/data/csv_parser_test.dart
//
// Unit tests for CsvParser.
//
// Input:  raw CAN bus frame CSV (tick_ms,can_id,dlc,b0..b7)
// Output: 1Hz decoded LogRecord snapshots + RawTrip boundaries
//
// Run with: flutter test test/data/csv_parser_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:somerset_ev_telematics/data/csv_parser.dart';

// Prepends the standard header so test bodies stay readable.
String _makeCsv(List<String> dataRows) =>
    ['tick_ms,can_id,dlc,b0,b1,b2,b3,b4,b5,b6,b7', ...dataRows].join('\n');

// Parse a CSV and return the first snapshot record (asserts exactly one exists
// unless [count] is supplied).
_ParseResult _parse(List<String> rows, {int syncedAtUnix = 1000}) {
  final result = CsvParser.parse(
    csvContent:     _makeCsv(rows),
    esp32SessionId: 1,
    syncedAtUnix:   syncedAtUnix,
  );
  return _ParseResult(result);
}

class _ParseResult {
  final ParsedSession session;
  _ParseResult(this.session);

  // Convenience: decoded value of the first snapshot
  T field<T>(T Function(dynamic c) fn) {
    expect(session.records, isNotEmpty, reason: 'expected at least one record');
    return fn(session.records.first);
  }
}

void main() {
  // ── CAN frame decoding ──────────────────────────────────────────────────────

  group('0x1DA – motor RPM', () {
    // RPM encoding: (b4<<7)|(b5>>1), 15-bit signed
    // For RPM=2800: b4=21 (2800>>7), b5=(2800%128)<<1 = 112<<1 = 224
    test('decodes positive RPM correctly', () {
      final r = _parse(['0,0x1DA,8,0,0,0,0,21,224,0,0']);
      expect(r.field((c) => c.motorRpm.value), equals(2800));
    });

    test('invalid sentinel (b4=0xFF, b5=0xFF) → RPM 0', () {
      final r = _parse(['0,0x1DA,8,0,0,0,0,255,255,0,0']);
      expect(r.field((c) => c.motorRpm.value), equals(0));
    });

    test('decodes negative RPM (reverse direction)', () {
      // RPM=-100: raw=32668, b4=255, b5=56 (not the 0xFF/0xFF invalid)
      final r = _parse(['0,0x1DA,8,0,0,0,0,255,56,0,0']);
      expect(r.field((c) => c.motorRpm.value), equals(-100));
    });
  });

  group('0x55A – motor and inverter temps (Fahrenheit)', () {
    // b1=motor temp °F, b2=inverter temp °F
    test('converts 212°F to 100.0°C', () {
      final r = _parse(['0,0x55A,8,0,212,212,0,0,0,0,0']);
      expect(r.field((c) => c.motorTempC.value), closeTo(100.0, 0.01));
      expect(r.field((c) => c.inverterTempC.value), closeTo(100.0, 0.01));
    });

    test('converts 32°F to 0.0°C', () {
      final r = _parse(['0,0x55A,8,0,32,32,0,0,0,0,0']);
      expect(r.field((c) => c.motorTempC.value), closeTo(0.0, 0.01));
    });
  });

  group('0x521 – ISA pack current (big-endian int32 bytes 2-5)', () {
    // 50000 mA = 50.0 A: bytes 2-5 = [0x00, 0x00, 0xC3, 0x50] = [0,0,195,80]
    test('decodes 50.0 A correctly', () {
      final r = _parse(['0,0x521,8,0,0,0,0,195,80,0,0']);
      expect(r.field((c) => c.packCurrentA.value), closeTo(50.0, 0.001));
    });

    test('decodes negative current (regen) correctly', () {
      // -10000 mA = -10.0 A: bytes 2-5 = [0xFF, 0xFF, 0xD8, 0xF0] = [255,255,216,240]
      final r = _parse(['0,0x521,8,0,0,255,255,216,240,0,0']);
      expect(r.field((c) => c.packCurrentA.value), closeTo(-10.0, 0.001));
    });
  });

  group('0x522 – ISA pack voltage (big-endian int32 bytes 2-5)', () {
    // 390000 mV = 390.0 V: 390000 = 0x0005F3B0 → bytes [0,5,243,112]
    test('decodes 390.0 V correctly', () {
      final r = _parse(['0,0x522,8,0,0,0,5,243,112,0,0']);
      expect(r.field((c) => c.packVoltageV.value), closeTo(390.0, 0.001));
    });
  });

  group('0x526 – ISA power (big-endian int32 bytes 2-5)', () {
    // 10000 W = 10.0 kW: 10000 = 0x00002710 → bytes [0,0,39,16]
    test('decodes 10.0 kW correctly', () {
      final r = _parse(['0,0x526,8,0,0,0,0,39,16,0,0']);
      expect(r.field((c) => c.packKw.value), closeTo(10.0, 0.001));
    });

    test('decodes negative power (regen) correctly', () {
      // -5000 W = -5.0 kW: 0xFFFFEC78 → bytes [255,255,236,120]
      final r = _parse(['0,0x526,8,0,0,255,255,236,120,0,0']);
      expect(r.field((c) => c.packKw.value), closeTo(-5.0, 0.001));
    });
  });

  group('0x527 – ISA amp-seconds (big-endian int32 bytes 2-5)', () {
    // 3600 As = 1.0 Ah: 3600 = 0x00000E10 → bytes [0,0,14,16]
    test('converts amp-seconds to Ah correctly', () {
      final r = _parse(['0,0x527,8,0,0,0,0,14,16,0,0']);
      expect(r.field((c) => c.ahUsed.value), closeTo(1.0, 0.0001));
    });
  });

  group('0x355 – BMS state of charge', () {
    test('reads SoC from b0', () {
      final r = _parse(['0,0x355,8,75,0,0,0,0,0,0,0']);
      expect(r.field((c) => c.socPct.value), equals(75));
    });
  });

  group('0x356 – BMS pack voltage (little-endian uint16, 0.01V units)', () {
    // 3900 × 0.01V = 39.0V → stored as mV: 39000
    // 3900 = 0x0F3C → LE: b0=0x3C=60, b1=0x0F=15
    test('converts 0.01V units to mV correctly', () {
      final r = _parse(['0,0x356,8,60,15,0,0,0,0,0,0']);
      expect(r.field((c) => c.packVoltageBmsMv.value), equals(39000));
    });
  });

  group('0x373 – BMS cell voltages and temperatures', () {
    // cellVMin = leUint16(b0,b1), cellVMax = leUint16(b2,b3)
    // bmsTempMin = leUint16(b4,b5) - 273, bmsTempMax = leUint16(b6,b7) - 273
    //
    // cellVMin=4000: 0x0FA0 → b0=160, b1=15
    // cellVMax=4100: 0x1004 → b2=4,   b3=16
    // bmsTempMin=25°C: K=298=0x012A → b4=42, b5=1
    // bmsTempMax=35°C: K=308=0x0134 → b6=52, b7=1
    test('decodes all fields correctly', () {
      final r = _parse(['0,0x373,8,160,15,4,16,42,1,52,1']);
      expect(r.field((c) => c.cellVoltageMinMv.value), equals(4000));
      expect(r.field((c) => c.cellVoltageMaxMv.value), equals(4100));
      expect(r.field((c) => c.bmsTempMinC.value), closeTo(25.0, 0.1));
      expect(r.field((c) => c.bmsTempMaxC.value), closeTo(35.0, 0.1));
    });
  });

  // ── Snapshot emission ───────────────────────────────────────────────────────

  group('1Hz snapshot emission', () {
    test('multiple frames within the same second → one snapshot', () {
      // All frames at tick_ms 0..999 fall in the same unix second
      // syncedAtUnix=1000, maxTickMs=999 → bestEffortOffset=1000
      final result = CsvParser.parse(
        csvContent: _makeCsv([
          '0,0x355,8,80,0,0,0,0,0,0,0',
          '250,0x355,8,81,0,0,0,0,0,0,0',
          '500,0x355,8,82,0,0,0,0,0,0,0',
          '999,0x355,8,83,0,0,0,0,0,0,0',
        ]),
        esp32SessionId: 1,
        syncedAtUnix: 1000,
      );
      expect(result.records.length, equals(1));
      // The snapshot fires on the first frame of each second — state at that point
      expect(result.records.first.socPct.value, equals(80));
    });

    test('frames spanning 3 seconds → 3 snapshots', () {
      // syncedAtUnix=1002, maxTickMs=2000 → bestEffortOffset=1000
      // tick 0→second 1000, tick 1000→second 1001, tick 2000→second 1002
      final result = CsvParser.parse(
        csvContent: _makeCsv([
          '0,0x355,8,85,0,0,0,0,0,0,0',
          '1000,0x355,8,82,0,0,0,0,0,0,0',
          '2000,0x355,8,79,0,0,0,0,0,0,0',
        ]),
        esp32SessionId: 1,
        syncedAtUnix: 1002,
      );
      expect(result.records.length, equals(3));
      expect(result.records[0].socPct.value, equals(85));
      expect(result.records[1].socPct.value, equals(82));
      expect(result.records[2].socPct.value, equals(79));
    });

    test('snapshot carries accumulated state from multiple CAN IDs', () {
      // 0x521 at tick 500 arrives after the first snapshot fires (at tick 0),
      // so packCurrentA=50 is carried into the SECOND snapshot (triggered at tick 1000).
      // syncedAtUnix=1001, maxTickMs=1000 → bestEffortOffset=1000
      final result = CsvParser.parse(
        csvContent: _makeCsv([
          '0,0x355,8,72,0,0,0,0,0,0,0',
          '500,0x521,8,0,0,0,0,195,80,0,0',  // 50000 mA = 50.0 A (same second, no snap)
          '1000,0x355,8,70,0,0,0,0,0,0,0',   // new second → fires second snapshot
        ]),
        esp32SessionId: 1,
        syncedAtUnix: 1001,
      );
      expect(result.records.length, equals(2));
      // Second snapshot captures state accumulated from both CAN IDs in second 0
      expect(result.records[1].packCurrentA.value, closeTo(50.0, 0.001));
      expect(result.records[1].socPct.value, equals(70));
    });
  });

  // ── Timestamp reconstruction ─────────────────────────────────────────────────

  group('timestamp reconstruction', () {
    test('bestEffortOffset = syncedAtUnix − maxTickMs/1000', () {
      // syncedAtUnix=1000000, maxTickMs=10000 → bestEffortOffset=999990
      // First frame at tick_ms=0 → unixTime=999990
      final result = CsvParser.parse(
        csvContent: _makeCsv([
          '0,0x355,8,70,0,0,0,0,0,0,0',
          '10000,0x355,8,60,0,0,0,0,0,0,0',
        ]),
        esp32SessionId: 1,
        syncedAtUnix: 1000000,
      );
      expect(result.records.first.unixTime.value, equals(999990));
    });

    test('date string derived from reconstructed unix time', () {
      // syncedAtUnix set to 2026-05-10 08:00:00 UTC = 1746864000
      // maxTickMs=0 → bestEffortOffset=1746864000
      // First frame at tick_ms=0 → unixTime=1746864000
      final result = CsvParser.parse(
        csvContent: _makeCsv(['0,0x355,8,70,0,0,0,0,0,0,0']),
        esp32SessionId: 1,
        syncedAtUnix: 1746864000,
      );
      expect(result.records.first.dayDate.value, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });
  });

  // ── Trip markers ─────────────────────────────────────────────────────────────

  group('TRIP_START / TRIP_END', () {
    // syncedAtUnix=1002, maxTickMs=2000 → bestEffortOffset=1000
    // tick 0 → second 1000 (index 0, pre-trip)
    // tick 1000 → second 1001 (index 1, in trip)
    // tick 2000 → second 1002 (index 2, in trip)

    test('creates one RawTrip with correct boundaries', () {
      final result = CsvParser.parse(
        csvContent: _makeCsv([
          '0,0x355,8,85,0,0,0,0,0,0,0',
          'TRIP_START,,,,,,,,,,',
          '1000,0x355,8,82,0,0,0,0,0,0,0',
          '2000,0x355,8,79,0,0,0,0,0,0,0',
          'TRIP_END,3600,8.0,2.5,85,78,120.0,,,,',
        ]),
        esp32SessionId: 1,
        syncedAtUnix: 1002,
      );
      expect(result.rawTrips.length, equals(1));
      final trip = result.rawTrips.first;
      expect(trip.startUnix, equals(1001));  // first record inside trip
      expect(trip.endUnix, equals(1002));    // last record inside trip
      expect(trip.recordIndices, equals([1, 2]));
    });

    test('extracts socEnd from TRIP_END summary columns', () {
      final result = CsvParser.parse(
        csvContent: _makeCsv([
          '0,0x355,8,85,0,0,0,0,0,0,0',
          'TRIP_START,,,,,,,,,,',
          '1000,0x355,8,79,0,0,0,0,0,0,0',
          'TRIP_END,3600,8.0,2.5,85,78,120.0,,,,',
        ]),
        esp32SessionId: 1,
        syncedAtUnix: 1001,
      );
      expect(result.rawTrips.first.socEnd, equals(78));
    });

    test('socStart is SoC at the moment TRIP_START was seen', () {
      // SoC=85 emitted before TRIP_START → tripSocStart=85
      final result = CsvParser.parse(
        csvContent: _makeCsv([
          '0,0x355,8,85,0,0,0,0,0,0,0',
          'TRIP_START,,,,,,,,,,',
          '1000,0x355,8,79,0,0,0,0,0,0,0',
          'TRIP_END,,,,,78,,,,,',
        ]),
        esp32SessionId: 1,
        syncedAtUnix: 1001,
      );
      expect(result.rawTrips.first.socStart, equals(85));
    });

    test('power cut with no TRIP_END auto-closes trip at last record', () {
      final result = CsvParser.parse(
        csvContent: _makeCsv([
          '0,0x355,8,85,0,0,0,0,0,0,0',
          'TRIP_START,,,,,,,,,,',
          '1000,0x355,8,82,0,0,0,0,0,0,0',
          '2000,0x355,8,79,0,0,0,0,0,0,0',
        ]),
        esp32SessionId: 1,
        syncedAtUnix: 1002,
      );
      expect(result.rawTrips.length, equals(1));
      expect(result.rawTrips.first.endUnix, equals(1002));
    });
  });

  // ── Edge cases ───────────────────────────────────────────────────────────────

  group('edge cases', () {
    test('empty CSV returns empty result', () {
      final result = CsvParser.parse(
        csvContent: '',
        esp32SessionId: 1,
        syncedAtUnix: 1000,
      );
      expect(result.records, isEmpty);
      expect(result.rawTrips, isEmpty);
    });

    test('header-only CSV returns empty result', () {
      final result = CsvParser.parse(
        csvContent: 'tick_ms,can_id,dlc,b0,b1,b2,b3,b4,b5,b6,b7',
        esp32SessionId: 1,
        syncedAtUnix: 1000,
      );
      expect(result.records, isEmpty);
    });

    test('unknown CAN ID rows are silently skipped', () {
      // 0xABCD is not in the decoder — it fires a snapshot at tick 0 (default state),
      // then the 0x355 frame at tick 1000 fires a second snapshot with socPct=72.
      // syncedAtUnix=1001, maxTickMs=1000 → bestEffortOffset=1000
      final result = CsvParser.parse(
        csvContent: _makeCsv([
          '0,0xABCD,8,1,2,3,4,5,6,7,8',
          '1000,0x355,8,72,0,0,0,0,0,0,0',
        ]),
        esp32SessionId: 1,
        syncedAtUnix: 1001,
      );
      expect(result.records.length, equals(2));
      expect(result.records[1].socPct.value, equals(72));
    });

    test('malformed rows with too few columns are silently skipped', () {
      final result = CsvParser.parse(
        csvContent: _makeCsv([
          'bad,data',
          '0,0x355,8,72,0,0,0,0,0,0,0',
        ]),
        esp32SessionId: 1,
        syncedAtUnix: 1000,
      );
      expect(result.records.length, equals(1));
    });
  });
}
