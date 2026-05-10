// lib/ui/screens/connection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/ble_service.dart';
import '../../services/permissions.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Somerset EV Telematics')),
      body: Consumer<BleService>(
        builder: (context, ble, _) {
          return Column(
            children: [
              Expanded(
                child: _StatusPanel(ble: ble),
              ),
              if (ble.connectionState == BleConnectionState.syncing)
                _SyncProgressPanel(ble: ble),
              _TripButton(ble: ble),
            ],
          );
        },
      ),
    );
  }
}

// ── Status panel ─────────────────────────────────────────────────────────────

class _StatusPanel extends StatelessWidget {
  final BleService ble;
  const _StatusPanel({required this.ble});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape:  BoxShape.circle,
              color:  _statusColour(ble.connectionState).withValues(alpha: 0.15),
              border: Border.all(
                color: _statusColour(ble.connectionState),
                width: 2,
              ),
            ),
            child: Icon(
              _statusIcon(ble.connectionState),
              size:  56,
              color: _statusColour(ble.connectionState),
            ),
          ),

          const SizedBox(height: 24),

          // Status text
          Text(
            _statusLabel(ble.connectionState),
            style: theme.textTheme.headlineSmall,
          ),

          const SizedBox(height: 8),

          if (ble.lastError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                ble.lastError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 32),

          // Connect / Disconnect button
          _ConnectButton(ble: ble),
        ],
      ),
    );
  }

  Color _statusColour(BleConnectionState state) {
    switch (state) {
      case BleConnectionState.disconnected: return Colors.grey;
      case BleConnectionState.scanning:     return Colors.blue;
      case BleConnectionState.connecting:   return Colors.orange;
      case BleConnectionState.connected:    return Colors.green;
      case BleConnectionState.syncing:      return Colors.teal;
    }
  }

  IconData _statusIcon(BleConnectionState state) {
    switch (state) {
      case BleConnectionState.disconnected: return Icons.bluetooth_disabled;
      case BleConnectionState.scanning:     return Icons.bluetooth_searching;
      case BleConnectionState.connecting:   return Icons.bluetooth;
      case BleConnectionState.connected:    return Icons.bluetooth_connected;
      case BleConnectionState.syncing:      return Icons.sync;
    }
  }

  String _statusLabel(BleConnectionState state) {
    switch (state) {
      case BleConnectionState.disconnected: return 'Not connected';
      case BleConnectionState.scanning:     return 'Scanning...';
      case BleConnectionState.connecting:   return 'Connecting...';
      case BleConnectionState.connected:    return 'Connected';
      case BleConnectionState.syncing:      return 'Syncing sessions...';
    }
  }
}

// ── Connect / Disconnect button ───────────────────────────────────────────────

class _ConnectButton extends StatelessWidget {
  final BleService ble;
  const _ConnectButton({required this.ble});

  @override
  Widget build(BuildContext context) {
    final scanning   = ble.connectionState == BleConnectionState.scanning;
    final connecting = ble.connectionState == BleConnectionState.connecting;
    final syncing    = ble.connectionState == BleConnectionState.syncing;
    final connected  = ble.connectionState == BleConnectionState.connected;
    final busy       = scanning || connecting || syncing;

    if (connected || syncing) {
      return OutlinedButton.icon(
        onPressed: busy ? null : ble.disconnect,
        icon:  const Icon(Icons.bluetooth_disabled),
        label: const Text('Disconnect'),
      );
    }

    return FilledButton.icon(
      onPressed: busy
          ? null
          : () async {
              final ok = await BlePermissions.request(context);
              if (ok && context.mounted) {
                ble.startScan();
              }
            },
      icon:  busy
          ? const SizedBox(
              width:  18,
              height: 18,
              child:  CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.bluetooth_searching),
      label: Text(scanning ? 'Scanning...' : 'Connect to tractor'),
    );
  }
}

// ── Sync progress panel ───────────────────────────────────────────────────────

class _SyncProgressPanel extends StatelessWidget {
  final BleService ble;
  const _SyncProgressPanel({required this.ble});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final progress = ble.syncProgress;
    if (progress == null) return const SizedBox.shrink();

    return Container(
      margin:  const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(progress.label, style: theme.textTheme.labelMedium),
              Text(
                '${(progress.fileFraction * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Session-level progress
          LinearProgressIndicator(
            value: progress.sessionFraction,
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
          ),
          const SizedBox(height: 4),
          // File-level progress
          LinearProgressIndicator(
            value: progress.fileFraction,
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            color: theme.colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}

// ── Trip button ───────────────────────────────────────────────────────────────
// Large and high-contrast — needs to be usable in a cab, possibly with gloves.

class _TripButton extends StatelessWidget {
  final BleService ble;
  const _TripButton({required this.ble});

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final connected = ble.connectionState == BleConnectionState.connected;
    final active    = ble.tripActive;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width:  double.infinity,
          height: 72,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: active
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              foregroundColor: active
                  ? theme.colorScheme.onError
                  : theme.colorScheme.onPrimary,
              textStyle: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: connected
                ? () => active ? ble.stopTrip() : ble.startTrip()
                : null,
            icon:  Icon(active ? Icons.stop_circle : Icons.play_circle, size: 28),
            label: Text(active ? 'End Job' : 'Start Job'),
          ),
        ),
      ),
    );
  }
}
