// lib/ui/screens/sessions_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database.dart';
import '../../data/demo_seeder.dart';
import 'trip_detail_screen.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
      body: StreamBuilder<List<Day>>(
        stream: db.watchAllDays(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final days = snapshot.data ?? [];
          if (days.isEmpty) {
            return const _EmptyState();
          }
          return ListView.builder(
            padding:     const EdgeInsets.symmetric(vertical: 8),
            itemCount:   days.length,
            itemBuilder: (context, i) => _DayCard(day: days[i]),
          );
        },
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatefulWidget {
  const _EmptyState();

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> {
  bool _seeding = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db    = context.read<AppDatabase>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_download_outlined,
              size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('No sessions yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Connect to your tractor to sync data',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          _seeding
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(
                  onPressed: () async {
                    setState(() => _seeding = true);
                    await DemoSeeder.seed(db);
                    if (mounted) setState(() => _seeding = false);
                  },
                  child: const Text('Load example data'),
                ),
        ],
      ),
    );
  }
}

// ── Day card ──────────────────────────────────────────────────────────────────

class _DayCard extends StatefulWidget {
  final Day day;
  const _DayCard({required this.day});

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db    = context.read<AppDatabase>();
    final day   = widget.day;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          // ── Day header ──────────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(day.date),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDayDate(day.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats chips
                  _StatChip(
                    icon:  Icons.timer_outlined,
                    label: _formatDuration(day.totalDurationSecs),
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon:  Icons.bolt,
                    label: '${day.totalAh.toStringAsFixed(1)} Ah',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon:  Icons.thermostat,
                    label: '${day.peakBmsTempC.toStringAsFixed(0)}°',
                    colour: _tempColour(day.peakBmsTempC),
                  ),

                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.share, size: 18),
                    tooltip: 'Export session CSV',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _shareDay,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),

          // ── Job list (expanded) ──────────────────────────────────────────
          if (_expanded)
            StreamBuilder<List<Trip>>(
              stream: db.watchTripsForDay(day.date),
              builder: (context, snapshot) {
                final trips = snapshot.data ?? [];
                if (trips.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'No jobs recorded for this day',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ...trips.map((t) => _TripTile(trip: t)),
                    const SizedBox(height: 4),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // "Monday" / "Yesterday" / "Today"
  String _formatDate(String dateStr) {
    final date  = DateTime.parse(dateStr);
    final today = DateTime.now();
    final diff  = today.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEEE').format(date);  // "Monday"
  }

  // "12 May 2025"
  String _formatDayDate(String dateStr) {
    return DateFormat('d MMMM y').format(DateTime.parse(dateStr));
  }

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

  Future<void> _shareDay() async {
    final db = context.read<AppDatabase>();
    final sessions = await db.getSessionsForDay(widget.day.date);
    final files = sessions
        .map((s) => XFile(s.rawCsvPath))
        .where((f) => File(f.path).existsSync())
        .toList();

    if (!mounted) return;

    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No session files found for this date')),
      );
      return;
    }

    await Share.shareXFiles(
      files,
      subject: 'SomersetEV session ${widget.day.date}',
    );
  }
}

// ── Job tile ──────────────────────────────────────────────────────────────────

class _TripTile extends StatelessWidget {
  final Trip trip;
  const _TripTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db    = context.read<AppDatabase>();
    final label = trip.name ?? 'Job ${trip.tripNumber}  ·  ${_formatTime(trip.startUnix)}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          '${trip.tripNumber}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(label, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        '${_formatDuration(trip.durationSecs)}  ·  '
        '${trip.ahConsumed.toStringAsFixed(1)} Ah  ·  '
        'Peak ${trip.peakRpm} RPM',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Rename job',
            onPressed: () => _showRenameDialog(context, db),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                size: 18, color: Theme.of(context).colorScheme.error),
            tooltip: 'Delete job',
            onPressed: () => _showDeleteDialog(context, db),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context, AppDatabase db) async {
    final controller = TextEditingController(text: trip.name ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Name this job'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Job ${trip.tripNumber}  ·  ${_formatTime(trip.startUnix)}',
          ),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (trip.name != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              child: const Text('Clear'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == null) return;
    await db.updateTripName(trip.id, saved.isEmpty ? null : saved);
  }

  Future<void> _showDeleteDialog(BuildContext context, AppDatabase db) async {
    final label = trip.name ?? 'Job ${trip.tripNumber}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete job?'),
        content: Text(
          '"$label" will be permanently removed and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await db.deleteTrip(trip.id);
  }

  String _formatTime(int unixSeconds) {
    return DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000),
    );
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color?   colour;
  const _StatChip({required this.icon, required this.label, this.colour});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final colour = this.colour ?? theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colour),
        const SizedBox(width: 3),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(color: colour)),
      ],
    );
  }
}
