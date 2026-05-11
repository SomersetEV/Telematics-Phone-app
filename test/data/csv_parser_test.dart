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

// Prepends the standard SavvyCAN GVRET header so test bodies stay readable.
String _makeCsv(List<String> dataRows) =>
    ['Time Stamp,ID,Extended,Bus,LEN,D1,D2,D3,D4,D5,D6,D7,D8', ...dataRows].join('\n');

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
    // RPM encoding: (D5<<7)|(D6>>1), 15-bit signed
    // For RPM=2800: D5=21 (2800>>7), D6=(2800%128)<<1 = 112<<1 = 224 = 0xE0
    test('decodes positive RPM correctly', () {
      final r = _parse(['0,0x1DA,false,0,8,00,00,00,00,15,E0,00,00']);
      expect(r.field((c) => c.motorRpm.value), equals(2800));
    });

    test('invalid sentinel (D5=0xFF, D6=0xFF) → RPM 0', () {
      final r = _parse(['0,0x1DA,false,0,8,00,00,00,00,FF,FF,00,00']);
      expect(r.field((c) => c.motorRpm.value), equals(0));
    });

    test('decodes negative RPM (reverse direction)', () {
      // RPM=-100: raw=32668=0x7F9C, D5=0xFF, D6=0x38 (not the FF/FF invalid)
      final r = _parse(['0,0x1DA,false,0,8,00,00,00,00,FF,38,00,00']);
      expect(r.field((c) => c.motorRpm.value), equals(-100));
    });
  });

  group('0x55A – motor and inverter temps (Fahrenheit)', () {
    // D2=motor temp °F, D3=inverter temp °F
    test('converts 212°F to 100.0°C', () {
      final r = _parse(['0,0x55A,false,0,8,00,D4,D4,00,00,00,00,00']);
      expect(r.field((c) => c.motorTempC.value), closeTo(100.0, 0.01));
      expect(r.field((c) => c.inverterTempC.value), closeTo(100.0, 0.01));
    });

    test('converts 32°F to 0.0°C', () {
      final r = _parse(['0,0x55A,false,0,8,00,20,20,00,00,00,00,00']);
      expect(r.field((c) => c.motorTempC.value), closeTo(0.0, 0.01));
    });
  });

  group('0x521 – ISA pack current (big-endian int32 bytes 2-5)', () {
    // 50000 mA = 50.0 A: D3-D6 = [0x00,0x00,0xC3,0x50]
    test('decodes 50.0 A correctly', () {
      final r = _parse(['0,0x521,false,0,8,00,00,00,00,C3,50,00,00']);
      expect(r.field((c) => c.packCurrentA.value), closeTo(50.0, 0.001));
    });

    test('decodes negative current (regen) correctly', () {
      // -10000 mA = -10.0 A: D3-D6 = [0xFF,0xFF,0xD8,0xF0]
      final r = _parse(['0,0x521,false,0,8,00,00,FF,FF,D8,F0,00,00']);
      expect(r.field((c) => c.packCurrentA.value), closeTo(-10.0, 0.001));
    });
  });

  group('0x522 – ISA pack voltage (big-endian int32 bytes 2-5)', () {
    // 390000 mV = 390.0 V: D3-D6 = [0x00,0x05,0xF3,0x70]
    test('decodes 390.0 V correctly', () {
      final r = _parse(['0,0x522,false,0,8,00,00,00,05,F3,70,00,00']);
      expect(r.field((c) => c.packVoltageV.value), closeTo(390.0, 0.001));
    });
  });

  group('0x526 – ISA power (big-endian int32 bytes 2-5)', () {
    // 10000 W = 10.0 kW: D3-D6 = [0x00,0x00,0x27,0x10]
    test('decodes 10.0 kW correctly', () {
      final r = _parse(['0,0x526,false,0,8,00,00,00,00,27,10,00,00']);
      expect(r.field((c) => c.packKw.value), closeTo(10.0, 0.001));
    });

    test('decodes negative power (regen) correctly', () {
      // -5000 W = -5.0 kW: D3-D6 = [0xFF,0xFF,0xEC,0x78]
      final r = _parse(['0,0x526,false,0,8,00,00,FF,FF,EC,78,00,00']);
      expect(r.field((c) => c.packKw.value), closeTo(-5.0, 0.001));
    });
  });

  group('0x527 – ISA amp-seconds (big-endian int32 bytes 2-5)', () {
    // 3600 As = 1.0 Ah: D3-D6 = [0x00,0x00,0x0E,0x10]
    test('converts amp-seconds to Ah correctly', () {
      final r = _parse(['0,0x527,false,0,8,00,00,00,00,0E,10,00,00']);
      expect(r.field((c) => c.ahUsed.value), closeTo(1.0, 0.0001));
    });
  });

  group('0x355 – BMS state of charge', () {
    test('reads SoC from D1', () {
      final r = _parse(['0,0x355,false,0,8,4B,00,00,00,00,00,00,00']);
      expect(r.field((c) => c.socPct.value), equals(75));
    });
  });

  group('0x356 – BMS pack voltage (little-endian uint16, 0.01V units)', () {
    // 3900 × 0.01V = 39.0V → stored as mV: 39000
    // 3900 = 0x0F3C → LE: D1=0x3C, D2=0x0F
    test('converts 0.01V units to mV correctly', () {
      final r = _parse(['0,0x356,false,0,8,3C,0F,00,00,00,00,00,00']);
      expect(r.field((c) => c.packVoltageBmsMv.value), equals(39000));
    });
  });

  group('0x373 – BMS cell voltages and temperatures', () {
    // cellVMin = leUint16(b0,b1), cellVMax = leUint16(b2,b3)
    // bmsTempMin = leUint16(b4,b5) - 273, bmsTempMax = leUint16(b6,b7) - 273
    //
    // cellVMin=4000: 0x0FA0 → D1=0xA0, D2=0x0F
    // cellVMax=4100: 0x1004 → D3=0x04, D4=0x10
    // bmsTempMin=25°C: K=298=0x012A → D5=0x2A, D6=0x01
    // bmsTempMax=35°C: K=308=0x0134 → D7=0x34, D8=0x01
    test('decodes all fields correctly', () {
      final r = _parse(['0,0x373,false,0,8,A0,0F,04,10,2A,01,34,01']);
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
          '0,0x355,false,0,8,50,00,00,00,00,00,00,00',
          '250,0x355,false,0,8,51,00,00,00,00,00,00,00',
          '500,0x355,false,0,8,52,00,00,00,00,00,00,00',
          '999,0x355,false,0,8,53,00,00,00,00,00,00,00',
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
          '0,0x355,false,0,8,55,00,00,00,00,00,00,00',
          '1000,0x355,false,0,8,52,00,00,00,00,00,00,00',
          '2000,0x355,false,0,8,4F,00,00,00,00,00,00,00',
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
          '0,0x355,false,0,8,48,00,00,00,00,00,00,00',
          '500,0x521,false,0,8,00,00,00,00,C3,50,00,00',  // 50000 mA = 50.0 A (same second, no snap)
          '1000,0x355,false,0,8,46,00,00,00,00,00,00,00', // new second → fires second snapshot
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
          '0,0x355,false,0,8,46,00,00,00,00,00,00,00',
          '10000,0x355,false,0,8,3C,00,00,00,00,00,00,00',
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
        csvContent: _makeCsv(['0,0x355,false,0,8,46,00,00,00,00,00,00,00']),
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
          '0,0x355,false,0,8,55,00,00,00,00,00,00,00',
          'TRIP_START,,,,,,,,,,',
          '1000,0x355,false,0,8,52,00,00,00,00,00,00,00',
          '2000,0x355,false,0,8,4F,00,00,00,00,00,00,00',
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
          '0,0x355,false,0,8,55,00,00,00,00,00,00,00',
          'TRIP_START,,,,,,,,,,',
          '1000,0x355,false,0,8,4F,00,00,00,00,00,00,00',
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
          '0,0x355,false,0,8,55,00,00,00,00,00,00,00',
          'TRIP_START,,,,,,,,,,',
          '1000,0x355,false,0,8,4F,00,00,00,00,00,00,00',
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
          '0,0x355,false,0,8,55,00,00,00,00,00,00,00',
          'TRIP_START,,,,,,,,,,',
          '1000,0x355,false,0,8,52,00,00,00,00,00,00,00',
          '2000,0x355,false,0,8,4F,00,00,00,00,00,00,00',
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
        csvContent: 'Time Stamp,ID,Extended,Bus,LEN,D1,D2,D3,D4,D5,D6,D7,D8',
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
          '0,0xABCD,false,0,8,01,02,03,04,05,06,07,08',
          '1000,0x355,false,0,8,48,00,00,00,00,00,00,00',
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
          '0,0x355,false,0,8,48,00,00,00,00,00,00,00',
        ]),
        esp32SessionId: 1,
        syncedAtUnix: 1000,
      );
      expect(result.records.length, equals(1));
    });
  });
}
