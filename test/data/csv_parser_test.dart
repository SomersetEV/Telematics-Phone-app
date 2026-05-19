// test/data/csv_parser_test.dart
//
// Unit tests for CsvParser — SNAP1 format.
//
// SNAP1 row: SNAP1,tick_ms,soc_pct,pack_v_bms_mv,pack_i_ma,isa_kw_w,isa_as,
//            motor_rpm,motor_temp_c10,inv_temp_c10,bms_tmax_c10,bms_tmin_c10,
//            cell_v_max_mv,cell_v_min_mv
//
// Run with: flutter test test/data/csv_parser_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:somerset_ev_telematics/data/csv_parser.dart';

const _header =
    'SNAP1,tick_ms,soc_pct,pack_v_bms_mv,pack_i_ma,isa_kw_w,isa_as,'
    'motor_rpm,motor_temp_c10,inv_temp_c10,bms_tmax_c10,bms_tmin_c10,'
    'cell_v_max_mv,cell_v_min_mv';

// Build a complete SNAP1 CSV string from data rows.
String _makeSnap(List<String> dataRows) =>
    [_header, ...dataRows].join('\n');

// Row builder: SNAP1,<tick_ms>,<soc>,<pack_v_bms_mv>,<pack_i_ma>,<isa_kw_w>,
//                    <isa_as>,<rpm>,<motor_c10>,<inv_c10>,<bmax_c10>,<bmin_c10>,
//                    <cell_max_mv>,<cell_min_mv>
String _row({
  int tick    = 0,
  int soc     = 0,
  int pvBms   = 0,
  int piMa    = 0,
  int kwW     = 0,
  int asAs    = 0,
  int rpm     = 0,
  int mTc10   = 0,
  int iTc10   = 0,
  int btMax10 = 0,
  int btMin10 = 0,
  int cvMax   = 0,
  int cvMin   = 0,
}) =>
    'SNAP1,$tick,$soc,$pvBms,$piMa,$kwW,$asAs,$rpm,$mTc10,$iTc10,$btMax10,$btMin10,$cvMax,$cvMin';

_ParseResult _parse(List<String> rows, {int syncedAtUnix = 1000}) {
  final result = CsvParser.parse(
    csvContent:     _makeSnap(rows),
    esp32SessionId: 1,
    syncedAtUnix:   syncedAtUnix,
  );
  return _ParseResult(result);
}

class _ParseResult {
  final ParsedSession session;
  _ParseResult(this.session);

  T field<T>(T Function(dynamic c) fn, {int index = 0}) {
    expect(session.records, isNotEmpty, reason: 'expected at least one record');
    return fn(session.records[index]);
  }
}

void main() {
  // ── Field decoding ──────────────────────────────────────────────────────────

  group('field decoding', () {
    test('soc_pct parsed directly', () {
      final r = _parse([_row(tick: 0, soc: 75)]);
      expect(r.field((c) => c.socPct.value), equals(75));
    });

    test('pack_v_bms_mv stored as-is (mV)', () {
      // 39000 mV = 390.0 V stored directly
      final r = _parse([_row(pvBms: 39000)]);
      expect(r.field((c) => c.packVoltageBmsMv.value), equals(39000));
    });

    test('pack_i_ma divided by 1000 → packCurrentA', () {
      // 2500 mA → 2.5 A
      final r = _parse([_row(piMa: 2500)]);
      expect(r.field((c) => c.packCurrentA.value), closeTo(2.5, 0.001));
    });

    test('negative pack_i_ma (regen) → negative packCurrentA', () {
      final r = _parse([_row(piMa: -1000)]);
      expect(r.field((c) => c.packCurrentA.value), closeTo(-1.0, 0.001));
    });

    test('isa_kw_w divided by 1000 → packKw', () {
      // 10000 W → 10.0 kW
      final r = _parse([_row(kwW: 10000)]);
      expect(r.field((c) => c.packKw.value), closeTo(10.0, 0.001));
    });

    test('isa_as divided by 3600 → ahUsed', () {
      // 3600 As → 1.0 Ah
      final r = _parse([_row(asAs: 3600)]);
      expect(r.field((c) => c.ahUsed.value), closeTo(1.0, 0.0001));
    });

    test('motor_rpm stored directly', () {
      final r = _parse([_row(rpm: 1450)]);
      expect(r.field((c) => c.motorRpm.value), equals(1450));
    });

    test('motor_temp_c10 divided by 10 → motorTempC', () {
      // 253 → 25.3°C
      final r = _parse([_row(mTc10: 253)]);
      expect(r.field((c) => c.motorTempC.value), closeTo(25.3, 0.01));
    });

    test('inv_temp_c10 divided by 10 → inverterTempC', () {
      final r = _parse([_row(iTc10: 220)]);
      expect(r.field((c) => c.inverterTempC.value), closeTo(22.0, 0.01));
    });

    test('bms_tmax_c10 and bms_tmin_c10 divided by 10', () {
      final r = _parse([_row(btMax10: 310, btMin10: 195)]);
      expect(r.field((c) => c.bmsTempMaxC.value), closeTo(31.0, 0.01));
      expect(r.field((c) => c.bmsTempMinC.value), closeTo(19.5, 0.01));
    });

    test('cell_v_max_mv and cell_v_min_mv stored as-is', () {
      final r = _parse([_row(cvMax: 4120, cvMin: 3880)]);
      expect(r.field((c) => c.cellVoltageMaxMv.value), equals(4120));
      expect(r.field((c) => c.cellVoltageMinMv.value), equals(3880));
    });
  });

  // ── Record emission ──────────────────────────────────────────────────────────

  group('record emission', () {
    test('one SNAP1 row → one record', () {
      final result = CsvParser.parse(
        csvContent:     _makeSnap([_row(tick: 0, soc: 75)]),
        esp32SessionId: 1,
        syncedAtUnix:   1000,
      );
      expect(result.records.length, equals(1));
    });

    test('three rows → three records', () {
      final result = CsvParser.parse(
        csvContent: _makeSnap([
          _row(tick: 0,    soc: 90),
          _row(tick: 1000, soc: 89),
          _row(tick: 2000, soc: 88),
        ]),
        esp32SessionId: 1,
        syncedAtUnix:   1002,
      );
      expect(result.records.length, equals(3));
      expect(result.records[0].socPct.value, equals(90));
      expect(result.records[1].socPct.value, equals(89));
      expect(result.records[2].socPct.value, equals(88));
    });
  });

  // ── Timestamp reconstruction ─────────────────────────────────────────────────

  group('timestamp reconstruction', () {
    test('bestEffortOffset = syncedAtUnix − maxTickMs/1000', () {
      // syncedAtUnix=1000000, maxTickMs=10000 → offset=999990
      // First record at tick 0 → unixTime=999990
      final result = CsvParser.parse(
        csvContent: _makeSnap([
          _row(tick: 0),
          _row(tick: 10000),
        ]),
        esp32SessionId: 1,
        syncedAtUnix:   1000000,
      );
      expect(result.records.first.unixTime.value, equals(999990));
    });

    test('date string derived from reconstructed unix time', () {
      // syncedAtUnix=1746864000 (2026-05-10 08:00 UTC), maxTickMs=0 → offset=1746864000
      final result = CsvParser.parse(
        csvContent:     _makeSnap([_row(tick: 0)]),
        esp32SessionId: 1,
        syncedAtUnix:   1746864000,
      );
      expect(result.records.first.dayDate.value, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });
  });

  // ── TRIP markers ─────────────────────────────────────────────────────────────

  group('TRIP_START / TRIP_END', () {
    // syncedAtUnix=1002, maxTickMs=2000 → offset=1000
    // tick 0 → unixTime 1000 (index 0, pre-trip)
    // tick 1000 → unixTime 1001 (index 1, in trip)
    // tick 2000 → unixTime 1002 (index 2, in trip)

    test('creates one RawTrip with correct boundaries', () {
      final result = CsvParser.parse(
        csvContent: _makeSnap([
          _row(tick: 0,    soc: 85),
          'TRIP_START,,,,,,,,,,,,,',
          _row(tick: 1000, soc: 84),
          _row(tick: 2000, soc: 83),
          'TRIP_END,2,0.01,0.000,85,83,1.0,,,,,,,',
        ]),
        esp32SessionId: 1,
        syncedAtUnix:   1002,
      );
      expect(result.rawTrips.length, equals(1));
      final trip = result.rawTrips.first;
      expect(trip.startUnix,     equals(1001));
      expect(trip.endUnix,       equals(1002));
      expect(trip.recordIndices, equals([1, 2]));
    });

    test('extracts socEnd from TRIP_END column 5', () {
      final result = CsvParser.parse(
        csvContent: _makeSnap([
          _row(tick: 0),
          'TRIP_START,,,,,,,,,,,,,',
          _row(tick: 1000, soc: 78),
          'TRIP_END,1,0.00,0.000,85,78,0.5,,,,,,,',
        ]),
        esp32SessionId: 1,
        syncedAtUnix:   1001,
      );
      expect(result.rawTrips.first.socEnd, equals(78));
    });

    test('socStart is SoC at the last record before TRIP_START', () {
      final result = CsvParser.parse(
        csvContent: _makeSnap([
          _row(tick: 0, soc: 85),
          'TRIP_START,,,,,,,,,,,,,',
          _row(tick: 1000, soc: 84),
          'TRIP_END,1,0.00,0.000,85,84,0.5,,,,,,,',
        ]),
        esp32SessionId: 1,
        syncedAtUnix:   1001,
      );
      expect(result.rawTrips.first.socStart, equals(85));
    });

    test('power cut with no TRIP_END auto-closes trip at last record', () {
      final result = CsvParser.parse(
        csvContent: _makeSnap([
          _row(tick: 0),
          'TRIP_START,,,,,,,,,,,,,',
          _row(tick: 1000, soc: 82),
          _row(tick: 2000, soc: 81),
        ]),
        esp32SessionId: 1,
        syncedAtUnix:   1002,
      );
      expect(result.rawTrips.length, equals(1));
      expect(result.rawTrips.first.endUnix, equals(1002));
    });
  });

  // ── Edge cases ───────────────────────────────────────────────────────────────

  group('edge cases', () {
    test('empty CSV returns empty result', () {
      final result = CsvParser.parse(
        csvContent:     '',
        esp32SessionId: 1,
        syncedAtUnix:   1000,
      );
      expect(result.records, isEmpty);
      expect(result.rawTrips, isEmpty);
    });

    test('header-only CSV returns empty result', () {
      final result = CsvParser.parse(
        csvContent:     _header,
        esp32SessionId: 1,
        syncedAtUnix:   1000,
      );
      expect(result.records, isEmpty);
    });

    test('rows with fewer than 14 columns are silently skipped', () {
      final result = CsvParser.parse(
        csvContent: _makeSnap([
          'SNAP1,0,75,39000',           // too few columns
          _row(tick: 0, soc: 90),       // valid
        ]),
        esp32SessionId: 1,
        syncedAtUnix:   1000,
      );
      expect(result.records.length, equals(1));
      expect(result.records.first.socPct.value, equals(90));
    });
  });
}
