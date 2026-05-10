// lib/ui/screens/trip_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../data/database.dart';

class TripDetailScreen extends StatelessWidget {
  final Trip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final db    = context.read<AppDatabase>();
    final title = trip.name ?? 'Job ${trip.tripNumber}  ·  ${_formatTime(trip.startUnix)}';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<LogRecord>>(
        future: db.getRecordsForTrip(trip.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return const Center(child: Text('No data for this trip'));
          }
          return _TripDetailBody(trip: trip, records: records);
        },
      ),
    );
  }

  String _formatTime(int unixSeconds) =>
      DateFormat('HH:mm').format(
        DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000),
      );
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _TripDetailBody extends StatelessWidget {
  final Trip           trip;
  final List<LogRecord> records;
  const _TripDetailBody({required this.trip, required this.records});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatsBar(trip: trip),
        const SizedBox(height: 20),
        _ChartCard(
          title:   'Motor RPM',
          colour:  Colors.greenAccent,
          spots:   _toSpots((r) => r.motorRpm.toDouble()),
          unit:    'RPM',
          records: records,
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title:   'Pack Current',
          colour:  Colors.amberAccent,
          spots:   _toSpots((r) => r.packCurrentA),
          unit:    'A',
          records: records,
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title:   'Temperatures',
          records: records,
          multiLine: [
            _ChartLine(
              label:  'Motor',
              colour: Colors.redAccent,
              spots:  _toSpots((r) => r.motorTempC),
            ),
            _ChartLine(
              label:  'Inverter',
              colour: Colors.orangeAccent,
              spots:  _toSpots((r) => r.inverterTempC),
            ),
            _ChartLine(
              label:  'BMS',
              colour: Colors.pinkAccent,
              spots:  _toSpots((r) => r.bmsTempMaxC),
            ),
          ],
          unit: '°C',
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title:   'Pack Voltage',
          colour:  Colors.cyanAccent,
          spots:   _toSpots((r) => r.packVoltageV),
          unit:    'V',
          records: records,
        ),
      ],
    );
  }

  // Convert records to fl_chart FlSpot list.
  // X axis = minutes from trip start.
  List<FlSpot> _toSpots(double Function(LogRecord) value) {
    if (records.isEmpty) return [];
    final startUnix = records.first.unixTime;
    return records.map((r) {
      final x = (r.unixTime - startUnix) / 60.0;  // minutes
      return FlSpot(x, value(r));
    }).toList();
  }
}

// ── Stats bar ─────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final Trip trip;
  const _StatsBar({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: 'Duration',
              value: _formatDuration(trip.durationSecs),
              icon:  Icons.timer_outlined,
            ),
            _divider(),
            _StatItem(
              label: 'Energy',
              value: '${trip.ahConsumed.toStringAsFixed(1)} Ah',
              icon:  Icons.bolt,
            ),
            _divider(),
            _StatItem(
              label: 'Peak RPM',
              value: '${trip.peakRpm}',
              icon:  Icons.speed,
            ),
            _divider(),
            _StatItem(
              label: 'Peak Temp',
              value: '${trip.peakMotorTempC.toStringAsFixed(0)}°C',
              icon:  Icons.thermostat,
              valueColour: _tempColour(trip.peakMotorTempC),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const SizedBox(
    height: 36,
    child: VerticalDivider(width: 1),
  );

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Color _tempColour(double temp) {
    if (temp >= 50) return Colors.red;
    if (temp >= 40) return Colors.orange;
    return Colors.green;
  }
}

class _StatItem extends StatelessWidget {
  final String  label;
  final String  value;
  final IconData icon;
  final Color?  valueColour;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColour,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColour,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

// ── Chart types ───────────────────────────────────────────────────────────────

class _ChartLine {
  final String    label;
  final Color     colour;
  final List<FlSpot> spots;
  const _ChartLine({required this.label, required this.colour, required this.spots});
}

// ── Chart card ────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String          title;
  final String          unit;
  final List<LogRecord> records;
  // Single line
  final Color?          colour;
  final List<FlSpot>?   spots;
  // Multi line
  final List<_ChartLine>? multiLine;

  const _ChartCard({
    required this.title,
    required this.unit,
    required this.records,
    this.colour,
    this.spots,
    this.multiLine,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + legend row
            Row(
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const Spacer(),
                if (multiLine != null)
                  ...multiLine!.map((l) => _LegendDot(label: l.label, colour: l.colour)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: LineChart(_buildChartData(context)),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(BuildContext context) {
    final theme = Theme.of(context);

    final List<LineChartBarData> lineBars;

    if (multiLine != null) {
      lineBars = multiLine!.map((l) => _buildLine(l.spots, l.colour)).toList();
    } else {
      lineBars = [_buildLine(spots!, colour!)];
    }

    // X axis range — duration in minutes
    final durationMins = records.isNotEmpty
        ? (records.last.unixTime - records.first.unixTime) / 60.0
        : 1.0;

    return LineChartData(
      lineBarsData: lineBars,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color:       theme.colorScheme.outlineVariant.withOpacity(0.3),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text(
              value.toStringAsFixed(0),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 10,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: _xInterval(durationMins),
            getTitlesWidget: (value, meta) => Text(
              '${value.toStringAsFixed(0)}m',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 10,
              ),
            ),
          ),
        ),
        rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
            '${s.y.toStringAsFixed(1)} $unit',
            const TextStyle(fontSize: 12),
          )).toList(),
        ),
      ),
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color colour) {
    return LineChartBarData(
      spots:          spots,
      isCurved:       true,
      curveSmoothness: 0.2,
      color:          colour,
      barWidth:       2,
      dotData:        const FlDotData(show: false),
      belowBarData:   BarAreaData(
        show:  true,
        color: colour.withOpacity(0.08),
      ),
    );
  }

  double _xInterval(double durationMins) {
    if (durationMins <= 10)  return 2;
    if (durationMins <= 30)  return 5;
    if (durationMins <= 60)  return 10;
    if (durationMins <= 120) return 20;
    return 30;
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color  colour;
  const _LegendDot({required this.label, required this.colour});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              )),
        ],
      ),
    );
  }
}
