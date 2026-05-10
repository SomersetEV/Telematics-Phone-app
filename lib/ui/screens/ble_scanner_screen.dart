// lib/ui/screens/ble_scanner_screen.dart
//
// General-purpose BLE device browser. Scans for all nearby BLE devices (no
// service-UUID filter) and lists them sorted by RSSI. Tap any row for details.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../../services/ble_service.dart';
import '../../services/permissions.dart';

class BleScannerScreen extends StatefulWidget {
  const BleScannerScreen({super.key});

  @override
  State<BleScannerScreen> createState() => _BleScannerScreenState();
}

class _BleScannerScreenState extends State<BleScannerScreen> {
  // Keyed by device ID so repeated advertisements update in place.
  final Map<String, ScanResult> _results = {};
  StreamSubscription<List<ScanResult>>? _resultsSub;
  StreamSubscription<bool>?            _isScanningSub;
  bool _scanning = false;

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (!mounted) return;
    final ok = await BlePermissions.request(context);
    if (!ok || !mounted) return;

    final ble = context.read<BleService>();
    if (ble.connectionState != BleConnectionState.disconnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot scan while tractor connection is active.'),
        ),
      );
      return;
    }

    await FlutterBluePlus.stopScan();
    _resultsSub?.cancel();
    _isScanningSub?.cancel();

    setState(() {
      _results.clear();
      _scanning = true;
    });

    _resultsSub = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        for (final r in results) {
          _results[r.device.remoteId.toString()] = r;
        }
      });
    });

    _isScanningSub = FlutterBluePlus.isScanning.listen((active) {
      if (!mounted) return;
      if (!active) setState(() => _scanning = false);
    });

    // No withServices filter — we want everything.
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  Future<void> _stopScan() async {
    await FlutterBluePlus.stopScan();
    _resultsSub?.cancel();
    _isScanningSub?.cancel();
    _resultsSub   = null;
    _isScanningSub = null;
    if (mounted) setState(() => _scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _results.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

    return Scaffold(
      appBar: AppBar(
        title: Text(_scanning
            ? 'Scanning... (${sorted.length})'
            : 'BLE Scanner${sorted.isNotEmpty ? ' (${sorted.length})' : ''}'),
        actions: [
          if (_scanning)
            IconButton(
              icon:    const Icon(Icons.stop),
              tooltip: 'Stop',
              onPressed: _stopScan,
            )
          else
            IconButton(
              icon:    const Icon(Icons.refresh),
              tooltip: 'Scan',
              onPressed: _startScan,
            ),
        ],
      ),
      body: sorted.isEmpty
          ? _EmptyState(scanning: _scanning, onScan: _startScan)
          : ListView.separated(
              itemCount: sorted.length + (_scanning ? 1 : 0),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == sorted.length) {
                  return const _ScanningFooter();
                }
                return _DeviceTile(result: sorted[index]);
              },
            ),
      floatingActionButton: !_scanning && sorted.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _startScan,
              icon:  const Icon(Icons.refresh),
              label: const Text('Rescan'),
            )
          : null,
    );
  }
}

// ── Empty / initial state ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool     scanning;
  final VoidCallback onScan;
  const _EmptyState({required this.scanning, required this.onScan});

  @override
  Widget build(BuildContext context) {
    if (scanning) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_searching,
              size: 72, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('No devices found yet',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon:    const Icon(Icons.search),
            label:   const Text('Start Scan'),
            onPressed: onScan,
          ),
        ],
      ),
    );
  }
}

// ── Scanning footer row ───────────────────────────────────────────────────────

class _ScanningFooter extends StatelessWidget {
  const _ScanningFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Scanning...'),
        ],
      ),
    );
  }
}

// ── Device list tile ──────────────────────────────────────────────────────────

class _DeviceTile extends StatelessWidget {
  final ScanResult result;
  const _DeviceTile({required this.result});

  String get _name {
    final pn = result.device.platformName;
    return pn.isNotEmpty ? pn : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final services = result.advertisementData.serviceUuids;

    return ListTile(
      leading: _RssiIcon(rssi: result.rssi),
      title: Text(
        _name,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.device.remoteId.toString(),
            style: theme.textTheme.bodySmall,
          ),
          if (services.isNotEmpty)
            Text(
              '${services.length} service${services.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
        ],
      ),
      trailing: Text(
        '${result.rssi} dBm',
        style: theme.textTheme.bodySmall?.copyWith(
          color: _rssiColor(result.rssi, theme),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      isThreeLine: services.isNotEmpty,
      onTap:       () => _showDetails(context),
    );
  }

  void _showDetails(BuildContext context) {
    final theme    = Theme.of(context);
    final services = result.advertisementData.serviceUuids;
    final mfr      = result.advertisementData.manufacturerData;

    showModalBottomSheet(
      context:     context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize:      MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              result.device.remoteId.toString(),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 12),
            Text('RSSI: ${result.rssi} dBm',
                style: theme.textTheme.bodyMedium),
            if (services.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Advertised services',
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              ...services.map(
                (uuid) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• $uuid',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
            if (mfr.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Manufacturer data: ${mfr.length} '
                'entr${mfr.length == 1 ? 'y' : 'ies'}',
                style: theme.textTheme.labelLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _rssiColor(int rssi, ThemeData theme) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -75) return Colors.orange;
    return theme.colorScheme.error;
  }
}

// ── RSSI signal-strength icon ─────────────────────────────────────────────────

class _RssiIcon extends StatelessWidget {
  final int rssi;
  const _RssiIcon({required this.rssi});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color    color;

    if (rssi >= -60) {
      icon  = Icons.signal_cellular_alt;
      color = Colors.green;
    } else if (rssi >= -75) {
      icon  = Icons.signal_cellular_alt_2_bar;
      color = Colors.orange;
    } else {
      icon  = Icons.signal_cellular_alt_1_bar;
      color = Theme.of(context).colorScheme.error;
    }

    return Icon(icon, color: color);
  }
}
