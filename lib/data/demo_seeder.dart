// lib/data/demo_seeder.dart
//
// Inserts one realistic demo day/trip/records so the Sessions screen
// can be previewed without a physical tractor connection.

import 'dart:math';
import 'package:drift/drift.dart';
import 'database.dart';

class DemoSeeder {
  static Future<void> seed(AppDatabase db) async {
    // Guard — do nothing if any data already exists
    final existing = await db.getAllDays();
    if (existing.isNotEmpty) return;

    // Anchor to 08:30 yesterday
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final date      = '${yesterday.year}-'
                      '${yesterday.month.toString().padLeft(2, '0')}-'
                      '${yesterday.day.toString().padLeft(2, '0')}';

    final tripStart = DateTime(yesterday.year, yesterday.month, yesterday.day, 8, 30);
    final startUnix = tripStart.millisecondsSinceEpoch ~/ 1000;
    const durationSecs = 60 * 60; // 1 hour

    await db.transaction(() async {
      // ── 1. Generate log records (1 Hz for 1 hour = 3600 records) ─────────
      const totalRecords = 3600;
      final records      = <LogRecordsCompanion>[];

      for (int i = 0; i < totalRecords; i++) {
        final t        = i / totalRecords;           // 0.0 → 1.0
        final sinArc   = sin(t * pi);                // 0 → 1 → 0 arc
        final unix     = startUnix + i;
        final tickMs   = i * 1000;

        final rpm           = (sinArc * 2800).round();
        final motorTempC    = 35.0 + t * 23.0;       // 35 → 58 °C
        final inverterTempC = 30.0 + t * 22.0;       // 30 → 52 °C
        final bmsTempMaxC   = 25.0 + t * 13.0;       // 25 → 38 °C
        final packCurrentA  = sinArc * 120.0;         // 0 → 120 → 0 A
        final packVoltageV  = 395.0 - t * 5.0;       // 395 → 390 V
        final ahUsed        = t * 8.0;                // 0 → 8 Ah (cumulative)
        final socPct        = (85 - (t * 7).round()); // 85 → 78 %
        final cellVMax      = (4150 - (t * 50).round()); // mV
        final cellVMin      = (4100 - (t * 60).round()); // mV
        final packVBms      = (packVoltageV * 1000).round();

        records.add(LogRecordsCompanion(
          dayDate:           Value(date),
          unixTime:          Value(unix),
          tickMs:            Value(tickMs),
          motorRpm:          Value(rpm),
          motorTempC:        Value(motorTempC),
          inverterTempC:     Value(inverterTempC),
          packCurrentA:      Value(packCurrentA),
          packVoltageV:      Value(packVoltageV),
          ahUsed:            Value(ahUsed),
          socPct:            Value(socPct),
          bmsTempMaxC:       Value(bmsTempMaxC),
          bmsTempMinC:       Value(bmsTempMaxC - 3.0),
          cellVoltageMaxMv:  Value(cellVMax),
          cellVoltageMinMv:  Value(cellVMin),
          packVoltageBmsMv:  Value(packVBms),
          tripId:            const Value(null), // back-filled below
        ));
      }

      // ── 2. Insert Day (FK parent must exist before Trip) ──────────────────
      await db.upsertDay(DaysCompanion(
        date:              Value(date),
        totalDurationSecs: const Value(durationSecs),
        totalAh:           const Value(8.0),
        peakMotorTempC:    const Value(58.0),
        peakInverterTempC: const Value(52.0),
        peakBmsTempC:      const Value(38.0),
        peakCurrentA:      const Value(120.0),
        peakRpm:           const Value(2800),
        peakSocPct:        const Value(85),
      ));

      // ── 3. Insert Trip ────────────────────────────────────────────────────
      final tripId = await db.insertTrip(TripsCompanion(
        dayDate:           Value(date),
        tripNumber:        const Value(1),
        startUnix:         Value(startUnix),
        endUnix:           Value(startUnix + durationSecs),
        durationSecs:      const Value(durationSecs),
        ahConsumed:        const Value(8.0),
        peakRpm:           const Value(2800),
        peakMotorTempC:    const Value(58.0),
        peakInverterTempC: const Value(52.0),
        peakBmsTempC:      const Value(38.0),
        peakCurrentA:      const Value(120.0),
        name:              const Value('Morning cut'),
        socStart:          const Value(85),
        socEnd:            const Value(78),
      ));

      // ── 4. Back-fill tripId and insert records ────────────────────────────
      final withTrip = records
          .map((r) => r.copyWith(tripId: Value(tripId)))
          .toList();

      await db.insertLogRecords(withTrip);
    });
  }
}
