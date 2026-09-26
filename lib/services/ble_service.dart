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

/// AP credentials the firmware reports back after WIFI_MODE — see
/// ble_nus.c handle_wifi_mode_command(), reply format "WIFI_MODE ssid=... pass=...".
class WebInterfaceInfo {
  final String ssid;
  final String pass;

  const WebInterfaceInfo({required this.ssid, required this.pass});
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
  WebInterfaceInfo?  webInterfaceInfo;

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

  // When the device last sent anything; a GET fails only once this goes stale.
  DateTime _lastRxAt = DateTime.now();

  // A fixed 2-minute limit on the whole GET failed every session too big to
  // move in that time (a long day, or any session over an iOS-sized MTU), and
  // it failed again on every later sync. The device streams steadily until
  // END, so only a stall is a failure.
  static const Duration _transferIdleTimeout = Duration(seconds: 20);

  // ── Scan and connect ───────────────────────────────────────────────────────

  Future<void> startScan() async {
    if (connectionState != BleConnectionState.disconnected) return;

    _setState(BleConnectionState.scanning);
    lastError = null;

    try {
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
    } catch (e) {
      // Bluetooth off or permission revoked. Uncaught, this left the state on
      // scanning with the button disabled until the app was restarted.
      _scanSub?.cancel();
      _scanSub = null;
      lastError = 'Could not scan: $e';
      _setState(BleConnectionState.disconnected);
      return;
    }

    // If scan times out without finding device. _scanSub is cleared once the
    // device is found, so a later reconnect (which also shows "scanning") is
    // not mistaken for this scan failing.
    await Future.delayed(const Duration(seconds: 16));
    if (connectionState == BleConnectionState.scanning && _scanSub != null) {
      _scanSub?.cancel();
      _scanSub = null;
      _setState(BleConnectionState.disconnected);
      lastError = 'Tractor not found — is it powered on?';
      notifyListeners();
    }
  }

  // Set while _connect is setting up a link. A scan result and a scheduled
  // _reconnect can both call _connect; two overlapping setups each attached a
  // notification listener, and every line (CSV rows included) was then
  // processed twice.
  bool _connecting = false;

  Future<void> _connect(BluetoothDevice device) async {
    if (_connecting) return;
    _connecting = true;
    try {
      await _connectAndSetUp(device);
    } finally {
      _connecting = false;
    }
  }

  Future<void> _connectAndSetUp(BluetoothDevice device) async {
    _setState(BleConnectionState.connecting);
    _device     = device;
    _lastDevice = device;

    try {
      await device.connect(timeout: const Duration(seconds: 10));
    } catch (e) {
      if (_reconnectAttempts > 0) {
        // An automatic reconnect, likely while the tractor is still booting.
        // Try again, up to the limit, rather than giving up after one go.
        _handleDisconnect();
        return;
      }
      lastError = 'Connection failed: $e';
      _setState(BleConnectionState.disconnected);
      notifyListeners();
      return;
    }

    // Watch for unexpected disconnection — only from here, once connected.
    // connectionState replays the device's last known state to each new
    // listener, and before connect() that is `disconnected`. Subscribing
    // earlier ran _handleDisconnect at the start of every connection: it
    // cancelled this subscription (so a real drop later went unnoticed and the
    // app kept showing "Connected"), nulled _device (so Disconnect did
    // nothing), and scheduled a reconnect that could race this setup.
    await _stateSub?.cancel();
    _stateSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _handleDisconnect();
      }
    });

    try {
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
      await _notifySub?.cancel();
      _notifySub = _txChar!.onValueReceived.listen(_onNotification);
    } catch (e) {
      // Uncaught, any of these left the app on "Connecting..." for good.
      if (_device == null) {
        // The link dropped mid-setup and _handleDisconnect has already taken
        // over (reconnecting, or showing disconnected).
        return;
      }
      disconnect();
      lastError = 'Connection setup failed: $e';
      notifyListeners();
      return;
    }

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
    _lastRxAt = DateTime.now();
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
        } else if (line.startsWith('CAN ')) {
          // Heartbeat interleaved into the transfer — not CSV data. Drop it;
          // buffering it corrupts the session and the parser silently discards
          // the affected rows.
        } else if (line.startsWith('ERR')) {
          // The device aborted mid-transfer. Fail the waiter rather than
          // appending the error text to the CSV and waiting out the 2min timeout.
          debugPrint('GET aborted mid-transfer: $line');
          _syncState = _SyncState.idle;
          _responseWaiter?.completeError(line);
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
        } else if (line.startsWith('ERR')) {
          // Never let an error satisfy a pending waiter. Doing so made DONE
          // "succeed" on ERR unknown_cmd, and made _queryTripState() read trip
          // state out of an error string.
          debugPrint('Device error: $line');
          _responseWaiter?.completeError(line);
          _responseWaiter = null;
        } else if (_responseWaiter != null && _isControlReply(line)) {
          _responseWaiter?.complete(line);
          _responseWaiter = null;
        } else {
          debugPrint('Unsolicited line ignored: $line');
        }
        // Anything else here is residue from an aborted transfer (a partial CSV
        // row, or a late END). Dropping it keeps the waiter open for the real
        // reply instead of resolving the command with garbage.
        break;
    }
  }

  // ── Command helpers ────────────────────────────────────────────────────────

  /// True for the firmware's single-line control replies (ble_nus.c
  /// dispatch_command): OK, ERR <reason>, STATUS trip=N, LIST ..., SUMMARY ...
  /// CSV data rows never match, so this distinguishes a real reply from
  /// leftover file content still arriving after an aborted transfer.
  static bool _isControlReply(String line) =>
      line.startsWith('OK')     ||
      line.startsWith('ERR')    ||
      line.startsWith('STATUS') ||
      line.startsWith('LIST')   ||
      line.startsWith('SUMMARY') ||
      line.startsWith('WIFI_MODE');

  /// Return the protocol to a clean idle state.
  ///
  /// The ESP32 emits a "CAN <count>" heartbeat once per second whenever its
  /// command queue is idle, and keeps streaming file chunks until it sends END.
  /// If we abandon a transfer part-way (GET timeout, ingest failure) without
  /// clearing state, those in-flight lines are still arriving when the next
  /// command goes out — and in idle/waitingEnd any non-CAN line completes the
  /// waiting Completer. The next reply then has no waiter and the command sits
  /// until its full timeout. Always land back here before the next command.
  void _resetProtocolState() {
    _syncState = _SyncState.idle;
    _fileBuffer.clear();
    _expectedFileSize = 0;
    _responseWaiter = null;
  }

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

  Future<void> retrySync() async {
    if (connectionState != BleConnectionState.connected) return;
    lastError = null;
    lastSyncResult = null;
    notifyListeners();
    await _runSyncProtocol();
  }

  // Guards against overlapping sync runs. _runSyncProtocol is reachable from
  // _connect, retrySync and stopTrip, so a reconnect part-way through a sync
  // used to start a second run alongside the first. Both would then pass the
  // isAlreadySynced check for the same session and collide on insert.
  bool _syncRunning = false;

  Future<void> _runSyncProtocol() async {
    if (_syncRunning) {
      debugPrint('Sync already running — ignoring re-entrant request');
      return;
    }
    _syncRunning = true;
    _setState(BleConnectionState.syncing);

    try {
      // 1. Send current time for soft RTC
      final unixNow = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _resetProtocolState();
      _responseWaiter = Completer<String>();
      await _sendCommand('TIME $unixNow');
      await _responseWaiter!.future.timeout(const Duration(seconds: 5))
          .catchError((_) => 'timeout');  // TIME failure is non-fatal
      _responseWaiter = null;

      // Ask about a running job before the downloads, which can take minutes.
      // The dash keeps a job going across a power cut, so after a reconnect
      // the End Job button has to reflect it straight away.
      await _queryTripState();
      notifyListeners();

      // 2. Request session list — retry up to 2 times if the ESP32 is slow
      String? listResponse;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          listResponse = await _sendAndWait(
            'LIST',
            _SyncState.waitingList,
            timeout: const Duration(seconds: 30),
          );
          break;
        } on TimeoutException {
          if (attempt == 3) rethrow;
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      _pendingSessions.clear();
      // Ascending, because DONE moves a high-water mark on the device: ACKing
      // a later session before an earlier one has landed hides the earlier one
      // from every future LIST.
      _pendingSessions.addAll(_parseListResponse(listResponse!)..sort());

      if (_pendingSessions.isEmpty) {
        await _finishSync();
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

        // Stop at a transfer that did not complete, for the same reason:
        // a DONE for any later session would hide this one for good. It is
        // fetched again, first, on the next sync.
        if (!await _downloadSession(sessionId)) break;
      }

    } catch (e) {
      lastError = 'Sync failed: $e';
      // LIST/GET gave up — clear state so the STATUS below (and any later
      // retry) starts from a clean slate rather than inheriting this one.
      _resetProtocolState();
    } finally {
      // In finally, not after the block: leaving this set on an unexpected
      // throw would disable syncing for the rest of the session.
      _syncRunning = false;
    }

    await _finishSync();
  }

  bool get _linkUp => _rxChar != null;

  Future<void> _finishSync() async {
    syncProgress = null;
    // A disconnect part-way through the sync has already moved the state on
    // (scanning for the reconnect, or disconnected). Setting `connected` over
    // it showed a dead link as live, the Start/End Job button then failed with
    // "Not connected", and _reconnect saw a non-scanning state and gave up.
    if (!_linkUp) {
      notifyListeners();
      return;
    }
    await _queryTripState();
    if (_linkUp) _setState(BleConnectionState.connected);
  }

  /// Read whether the dash has a job running. Tried twice; if neither reply
  /// arrives tripActive keeps its last known value rather than reading a lost
  /// reply as "no job" — Start Job on a running job is harmless (the dash
  /// keeps the job), but hiding a running job is not.
  Future<void> _queryTripState() async {
    for (int attempt = 0; attempt < 2 && _linkUp; attempt++) {
      _resetProtocolState();
      final waiter = _responseWaiter = Completer<String>();
      try {
        await _sendCommand('STATUS');
        final statusResp = await waiter.future.timeout(const Duration(seconds: 5));
        if (statusResp.startsWith('STATUS')) {
          tripActive = statusResp.contains('trip=1');
          return;
        }
      } catch (_) {
        // Timed out, ERR, or the link dropped — try again while it is up.
      } finally {
        _responseWaiter = null;
      }
    }
  }

  /// Returns false when the transfer did not complete and the sync should stop
  /// (see _runSyncProtocol); true once the session is dealt with, including a
  /// session the device refused to serve or the phone could not ingest.
  Future<bool> _downloadSession(int sessionId) async {
    final idStr = sessionId.toString().padLeft(4, '0');

    // Send GET and wait for full file (resolves when END marker arrives)
    String csvContent;
    try {
      _syncState = _SyncState.waitingData;
      final waiter = _responseWaiter = Completer<String>();
      _lastRxAt = DateTime.now();
      await _sendCommand('GET $sessionId');
      csvContent = await _awaitTransfer(waiter);
    } catch (e) {
      debugPrint('GET $idStr failed: $e');
      // Transfer aborted mid-state — drop back to idle and discard any partial
      // file content, otherwise the next command's waiter is completed by a
      // leftover CSV row instead of its real reply.
      _resetProtocolState();
      // Surface it. This path was previously silent, which is what made a
      // stuck sync look like "connected, synced, no jobs" with nothing to go on.
      lastSyncResult = 'Session $idStr: download failed — $e';
      notifyListeners();
      // An ERR reply is the device refusing this session (e.g. not_found);
      // later sessions can still go. Anything else is a stalled or dropped
      // transfer that should be retried before anything after it is ACKed.
      return e is String && e.startsWith('ERR');
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
      // Don't send DONE — keep the session available for retry. State still has
      // to go back to idle, or the next command inherits this waitingEnd.
      _resetProtocolState();
      return true;
    }

    if (recordCount < 0) {
      // ingestSession returns -1 when esp32SessionId is already in the database.
      // Previously this matched neither branch below and produced no message at
      // all — the signature of the silent re-download loop.
      lastSyncResult = 'Session $idStr: already in database, skipped';
    } else if (recordCount == 0) {
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

    // Confirm receipt — ESP32 updates NVS last_synced.
    // Clear any residue from the transfer before opening a new waiter.
    _resetProtocolState();
    _responseWaiter = Completer<String>();
    await _sendCommand('DONE $sessionId');
    final doneResp = await _responseWaiter!.future
        .timeout(const Duration(seconds: 5))
        .catchError((_) => 'timeout');
    _responseWaiter = null;

    // An unacknowledged DONE leaves last_synced unadvanced on the device, so the
    // session is re-listed and re-downloaded on every future sync. Say so rather
    // than looping in silence.
    if (!doneResp.startsWith('OK')) {
      debugPrint('DONE $idStr not acknowledged: $doneResp');
      lastSyncResult = 'Session $idStr: not acknowledged ($doneResp) '
                       '— will re-sync next time';
      notifyListeners();
    }
    return true;
  }

  /// Wait for a GET to finish, failing only if the device goes quiet for
  /// [_transferIdleTimeout]. Errors on [waiter] (ERR, Disconnected) propagate.
  Future<String> _awaitTransfer(Completer<String> waiter) async {
    while (true) {
      try {
        return await waiter.future.timeout(const Duration(seconds: 1));
      } on TimeoutException {
        if (DateTime.now().difference(_lastRxAt) > _transferIdleTimeout) {
          throw TimeoutException(
            'no data from the tractor for ${_transferIdleTimeout.inSeconds}s',
            _transferIdleTimeout,
          );
        }
      }
    }
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
      _resetProtocolState();
      _responseWaiter = Completer<String>();
      await _sendCommand('TRIP_START');
      await _responseWaiter!.future.timeout(const Duration(seconds: 5));
      _responseWaiter = null;
      tripActive = true;
      notifyListeners();
    } catch (e) {
      lastError = 'Failed to start trip: $e';
      _resetProtocolState();   // drop the timed-out waiter
      notifyListeners();
    }
  }

  Future<void> stopTrip() async {
    if (connectionState != BleConnectionState.connected) return;
    if (!tripActive) return;

    try {
      _resetProtocolState();
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
      _resetProtocolState();   // drop the timed-out waiter
      notifyListeners();
    }
  }

  // ── Web-interface (bench/service) mode ───────────────────────────────────────

  /// Switches the tractor unit from BLE logging mode into WiFi web-interface
  /// mode for configuring the inverter. Firmware reboots into the new mode
  /// after replying, so the BLE link drops right after this call resolves —
  /// that's expected, not a failure (see ble_nus.c handle_wifi_mode_command).
  Future<void> enterWifiMode() async {
    if (connectionState != BleConnectionState.connected) return;

    try {
      _resetProtocolState();
      _responseWaiter = Completer<String>();
      await _sendCommand('WIFI_MODE');
      final reply = await _responseWaiter!.future.timeout(const Duration(seconds: 5));
      _responseWaiter = null;

      final ssidMatch = RegExp(r'ssid=(\S+)').firstMatch(reply);
      final passMatch = RegExp(r'pass=(\S+)').firstMatch(reply);
      if (ssidMatch != null && passMatch != null) {
        webInterfaceInfo = WebInterfaceInfo(
          ssid: ssidMatch.group(1)!,
          pass: passMatch.group(1)!,
        );
      }
      notifyListeners();
    } catch (e) {
      lastError = 'Failed to enter web-interface mode: $e';
      _resetProtocolState();
      notifyListeners();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setState(BleConnectionState state) {
    connectionState = state;
    notifyListeners();
  }
}
