// lib/services/ble_service.dart
//
// Handles everything BLE-related:
//   - Scanning for SomersetEV-Tractor
//   - Connecting and MTU negotiation
//   - Sync protocol (TIME → LIST → GET → DONE)
//   - TRIP_START / TRIP_END commands
//
// Extends ChangeNotifier so UI can watch connection state and sync progress.
//
// Incoming data handling:
//   All ESP32 responses arrive as BLE notifications on the TX characteristic.
//   They are buffered into a StringBuffer and processed line by line.
//   File content (between DATA header and END marker) is accumulated separately.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../data/session_repository.dart';

// ── NUS UUIDs ────────────────────────────────────────────────────────────────
const String _nusSvcUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
const String _nusRxUuid  = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';  // we write here
const String _nusTxUuid  = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';  // we subscribe here

const String _deviceName = 'SomersetEV-Tractor';
const int    _targetMtu  = 512;

// ── Public state types ───────────────────────────────────────────────────────

enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  syncing,
}

class SyncProgress {
  final int currentSession;
  final int totalSessions;
  final int bytesReceived;
  final int totalBytes;

  const SyncProgress({
    required this.currentSession,
    required this.totalSessions,
    required this.bytesReceived,
    required this.totalBytes,
  });

  double get sessionFraction =>
      totalSessions == 0 ? 0 : currentSession / totalSessions;
  double get fileFraction =>
      totalBytes == 0 ? 0 : bytesReceived / totalBytes;

  String get label => 'Session $currentSession of $totalSessions';
}

// ── Internal protocol state ──────────────────────────────────────────────────

enum _SyncState { idle, waitingList, waitingData, receivingFile, waitingEnd }

class BleService extends ChangeNotifier {
  final SessionRepository _repository;

  BleService(this._repository);

  // ── Public state ───────────────────────────────────────────────────────────
  BleConnectionState connectionState = BleConnectionState.disconnected;
  SyncProgress?      syncProgress;
  bool               tripActive      = false;
  String?            lastError;
  String?            lastSyncResult;
  bool               canBusActive    = false;

  // ── Private ────────────────────────────────────────────────────────────────
  int      _lastCanFrameCount  = 0;
  DateTime? _lastCanActivity;

  BluetoothDevice?         _device;
  BluetoothDevice?         _lastDevice;       // remembered for auto-reconnect
  BluetoothCharacteristic? _rxChar;   // we write to this
  BluetoothCharacteristic? _txChar;   // we subscribe to this
  StreamSubscription?      _notifySub;
  StreamSubscription?      _stateSub;
  StreamSubscription?      _scanSub;

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;

  // Incoming data buffer
  final StringBuffer _incomingBuffer = StringBuffer();

  // Sync protocol state machine
  _SyncState         _syncState     = _SyncState.idle;
  Completer<String>? _responseWaiter;  // resolves when a control line arrives

  // File transfer state
  int            _expectedFileSize = 0;
  final StringBuffer _fileBuffer   = StringBuffer();

  // Sessions to sync — populated from LIST response
  final List<int> _pendingSessions = [];

  // ── Scan and connect ───────────────────────────────────────────────────────

  Future<void> startScan() async {
    if (connectionState != BleConnectionState.disconnected) return;

    _setState(BleConnectionState.scanning);
    lastError = null;

    // Stop any existing scan
    await FlutterBluePlus.stopScan();

    // Listen for scan results — store subscription so it can be cancelled
    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (final result in results) {
        if (result.device.platformName == _deviceName) {
          _scanSub?.cancel();
          _scanSub = null;
          await FlutterBluePlus.stopScan();
          await _connect(result.device);
          return;
        }
      }
    });

    // Scan filtering by NUS service UUID so we only see our device
    await FlutterBluePlus.startScan(
      withServices: [Guid(_nusSvcUuid)],
      timeout:      const Duration(seconds: 15),
    );

    // If scan times out without finding device
    await Future.delayed(const Duration(seconds: 16));
    if (connectionState == BleConnectionState.scanning) {
      _setState(BleConnectionState.disconnected);
      lastError = 'Tractor not found — is it powered on?';
      notifyListeners();
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    _setState(BleConnectionState.connecting);
    _device     = device;
    _lastDevice = device;

    // Watch for unexpected disconnection
    _stateSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _handleDisconnect();
      }
    });

    try {
      await device.connect(timeout: const Duration(seconds: 10));
    } catch (e) {
      lastError = 'Connection failed: $e';
      _setState(BleConnectionState.disconnected);
      notifyListeners();
      return;
    }

    // Negotiate MTU — Android will typically accept 512
    try {
      await device.requestMtu(_targetMtu);
    } catch (_) {
      // MTU negotiation failure is non-fatal — we'll use smaller chunks
    }

    // Discover services
    final services = await device.discoverServices();
    final nusSvc   = services.firstWhere(
      (s) => s.serviceUuid == Guid(_nusSvcUuid),
      orElse: () => throw Exception('NUS service not found'),
    );

    _rxChar = nusSvc.characteristics.firstWhere(
      (c) => c.characteristicUuid == Guid(_nusRxUuid),
    );
    _txChar = nusSvc.characteristics.firstWhere(
      (c) => c.characteristicUuid == Guid(_nusTxUuid),
    );

    // Subscribe to TX notifications
    await _txChar!.setNotifyValue(true);
    _notifySub = _txChar!.onValueReceived.listen(_onNotification);

    _reconnectAttempts = 0;
    lastError = null;
    _setState(BleConnectionState.connected);

    // Kick off sync protocol
    await _runSyncProtocol();
  }

  void disconnect() {
    // Cancel state listener before disconnecting so it doesn't also call
    // _handleDisconnect and run cleanup twice.
    _stateSub?.cancel();
    _stateSub = null;
    _device?.disconnect();
    _handleDisconnect(reconnect: false);
  }

  void _handleDisconnect({bool reconnect = true}) {
    _notifySub?.cancel();
    _stateSub?.cancel();
    _scanSub?.cancel();
    _notifySub = null;
    _stateSub  = null;
    _scanSub   = null;
    _rxChar = null;
    _txChar = null;
    _device = null;
    _incomingBuffer.clear();
    _fileBuffer.clear();
    _pendingSessions.clear();
    _syncState = _SyncState.idle;
    _responseWaiter?.completeError('Disconnected');
    _responseWaiter = null;
    tripActive          = false;
    canBusActive        = false;
    _lastCanFrameCount  = 0;
    _lastCanActivity    = null;
    syncProgress        = null;

    if (reconnect &&
        _lastDevice != null &&
        _reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      lastError = 'Connection lost — reconnecting '
                  '($_reconnectAttempts/$_maxReconnectAttempts)...';
      _setState(BleConnectionState.scanning);
      Future.delayed(const Duration(seconds: 3), _reconnect);
    } else {
      _reconnectAttempts = 0;
      _setState(BleConnectionState.disconnected);
    }
  }

  Future<void> _reconnect() async {
    if (connectionState != BleConnectionState.scanning) return;
    if (_lastDevice == null) return;
    await _connect(_lastDevice!);
  }

  // ── Incoming notification handler ──────────────────────────────────────────

  void _onNotification(List<int> value) {
    final text = utf8.decode(value, allowMalformed: true);
    _incomingBuffer.write(text);

    // Process all complete lines in the buffer
    final raw   = _incomingBuffer.toString();
    final lines = raw.split('\n');

    // Last element may be an incomplete line — keep it in the buffer
    _incomingBuffer.clear();
    _incomingBuffer.write(lines.last);

    for (final line in lines.sublist(0, lines.length - 1)) {
      final trimmed = line.trimRight();
      if (trimmed.isEmpty) continue;
      _processLine(trimmed);
    }
  }

  void _processLine(String line) {
    switch (_syncState) {

      case _SyncState.waitingList:
        if (line.startsWith('LIST')) {
          _responseWaiter?.complete(line);
          _responseWaiter = null;
        } else if (line.startsWith('ERR')) {
          _responseWaiter?.completeError(line);
          _responseWaiter = null;
        }
        break;

      case _SyncState.waitingData:
        if (line.startsWith('DATA')) {
          // "DATA 0001 123456"
          final parts = line.split(' ');
          if (parts.length >= 3) {
            _expectedFileSize    = int.tryParse(parts[2]) ?? 0;
            _fileBuffer.clear();
            _syncState = _SyncState.receivingFile;
          }
        } else if (line.startsWith('ERR')) {
          _responseWaiter?.completeError(line);
          _responseWaiter = null;
          _syncState = _SyncState.idle;
        }
        break;

      case _SyncState.receivingFile:
        // Lines between DATA and END are file content
        if (line.startsWith('END')) {
          // File complete — resolve the waiter with accumulated content
          _syncState = _SyncState.waitingEnd;
          _responseWaiter?.complete(_fileBuffer.toString());
          _responseWaiter = null;
        } else {
          _fileBuffer.writeln(line);
          // Update progress
          final received = _fileBuffer.length;
          if (syncProgress != null) {
            syncProgress = SyncProgress(
              currentSession: syncProgress!.currentSession,
              totalSessions:  syncProgress!.totalSessions,
              bytesReceived:  received,
              totalBytes:     _expectedFileSize,
            );
            notifyListeners();
          }
        }
        break;

      case _SyncState.idle:
      case _SyncState.waitingEnd:
        if (line.startsWith('CAN ')) {
          final count = int.tryParse(line.substring(4));
          if (count != null) {
            if (count != _lastCanFrameCount) {
              _lastCanFrameCount = count;
              _lastCanActivity   = DateTime.now();
              canBusActive       = true;
            } else {
              canBusActive = false;
            }
            notifyListeners();
          }
        } else if (_responseWaiter != null) {
          _responseWaiter?.complete(line);
          _responseWaiter = null;
        }
        break;
    }
  }

  // ── Command helpers ────────────────────────────────────────────────────────

  Future<void> _sendCommand(String command) async {
    if (_rxChar == null) throw Exception('Not connected');
    final bytes = utf8.encode('$command\n');

    // flutter_blue_plus write — withoutResponse matches ESP32 WRITE_NO_RSP flag
    await _rxChar!.write(bytes, withoutResponse: true);
  }

  // Send a command and wait for a single-line response
  Future<String> _sendAndWait(String command, _SyncState waitState, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _syncState       = waitState;
    _responseWaiter  = Completer<String>();
    await _sendCommand(command);
    return _responseWaiter!.future.timeout(timeout);
  }

  // ── Sync protocol ──────────────────────────────────────────────────────────

  Future<void> _runSyncProtocol() async {
    _setState(BleConnectionState.syncing);

    try {
      // 1. Send current time for soft RTC
      final unixNow = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _syncState      = _SyncState.idle;
      _responseWaiter = Completer<String>();
      await _sendCommand('TIME $unixNow');
      await _responseWaiter!.future.timeout(const Duration(seconds: 5))
          .catchError((_) => 'timeout');  // TIME failure is non-fatal
      _responseWaiter = null;

      // 2. Request session list
      final listResponse = await _sendAndWait(
        'LIST',
        _SyncState.waitingList,
        timeout: const Duration(seconds: 10),
      );
      _pendingSessions.clear();
      _pendingSessions.addAll(_parseListResponse(listResponse));

      if (_pendingSessions.isEmpty) {
        await _queryTripState();
        _setState(BleConnectionState.connected);
        return;
      }

      // 3. Download each session
      final total = _pendingSessions.length;
      for (int i = 0; i < _pendingSessions.length; i++) {
        final sessionId = _pendingSessions[i];

        syncProgress = SyncProgress(
          currentSession: i + 1,
          totalSessions:  total,
          bytesReceived:  0,
          totalBytes:     0,
        );
        notifyListeners();

        await _downloadSession(sessionId);
      }

    } catch (e) {
      lastError = 'Sync failed: $e';
    }

    syncProgress = null;
    await _queryTripState();
    _setState(BleConnectionState.connected);
  }

  Future<void> _queryTripState() async {
    _syncState      = _SyncState.idle;
    _responseWaiter = Completer<String>();
    await _sendCommand('STATUS');
    final statusResp = await _responseWaiter!.future
        .timeout(const Duration(seconds: 5))
        .catchError((_) => '');
    _responseWaiter = null;
    tripActive = statusResp.contains('trip=1');
  }

  Future<void> _downloadSession(int sessionId) async {
    final idStr = sessionId.toString().padLeft(4, '0');

    // Send GET and wait for full file (resolves when END marker arrives)
    String csvContent;
    try {
      csvContent = await _sendAndWait(
        'GET $sessionId',
        _SyncState.waitingData,
        timeout: const Duration(minutes: 2),
      );
    } catch (e) {
      debugPrint('GET $idStr failed: $e');
      return;
    }

    // Save raw CSV to device storage
    final dir     = await getApplicationDocumentsDirectory();
    final csvPath = p.join(dir.path, 'sessions', 'snap_$idStr.csv');
    await Directory(p.dirname(csvPath)).create(recursive: true);
    await File(csvPath).writeAsString(csvContent);

    // Parse and ingest into database
    final syncedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int recordCount;
    try {
      recordCount = await _repository.ingestSession(
        esp32SessionId: sessionId,
        csvContent:     csvContent,
        rawCsvPath:     csvPath,
        syncedAtUnix:   syncedAt,
      );
    } catch (e) {
      lastSyncResult = 'Session $idStr: ingest error — $e';
      notifyListeners();
      return;   // don't send DONE — keep available for retry
    }

    if (recordCount == 0) {
      final allLines   = csvContent.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final dataLines  = allLines.length - 1; // minus header
      final firstData  = allLines.length > 1 ? allLines[1] : '—';
      final preview    = firstData.length > 60 ? firstData.substring(0, 60) : firstData;
      lastSyncResult   = 'Session $idStr: 0 records. '
                         '$dataLines data lines. First: "$preview"';
    } else if (recordCount > 0) {
      lastSyncResult = 'Session $idStr: $recordCount records synced';
    }
    notifyListeners();

    // Confirm receipt — ESP32 updates NVS last_synced
    _syncState      = _SyncState.idle;
    _responseWaiter = Completer<String>();
    await _sendCommand('DONE $sessionId');
    await _responseWaiter!.future
        .timeout(const Duration(seconds: 5))
        .catchError((_) => 'timeout');
    _responseWaiter = null;
  }

  List<int> _parseListResponse(String response) {
    // "LIST 0001,3600;0002,1800;\n"
    final ids    = <int>[];
    final body   = response.replaceFirst('LIST ', '').trim();
    final entries = body.split(';');
    for (final entry in entries) {
      if (entry.isEmpty) continue;
      final parts = entry.split(',');
      if (parts.isNotEmpty) {
        final id = int.tryParse(parts[0]);
        if (id != null) ids.add(id);
      }
    }
    return ids;
  }

  // ── Trip commands ──────────────────────────────────────────────────────────

  Future<void> startTrip() async {
    if (connectionState != BleConnectionState.connected) return;
    if (tripActive) return;

    try {
      _syncState      = _SyncState.idle;
      _responseWaiter = Completer<String>();
      await _sendCommand('TRIP_START');
      await _responseWaiter!.future.timeout(const Duration(seconds: 5));
      _responseWaiter = null;
      tripActive = true;
      notifyListeners();
    } catch (e) {
      lastError = 'Failed to start trip: $e';
      notifyListeners();
    }
  }

  Future<void> stopTrip() async {
    if (connectionState != BleConnectionState.connected) return;
    if (!tripActive) return;

    try {
      _syncState      = _SyncState.idle;
      _responseWaiter = Completer<String>();
      await _sendCommand('TRIP_END');
      // ESP32 waits for file close + session rotate before replying OK (up to 2s)
      await _responseWaiter!.future.timeout(const Duration(seconds: 10));
      _responseWaiter = null;
      tripActive = false;
      notifyListeners();
      // Sync the just-ended session immediately
      await _runSyncProtocol();
    } catch (e) {
      lastError = 'Failed to stop trip: $e';
      notifyListeners();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setState(BleConnectionState state) {
    connectionState = state;
    notifyListeners();
  }
}
