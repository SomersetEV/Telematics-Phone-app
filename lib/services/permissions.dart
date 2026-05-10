// lib/services/permissions.dart
//
// Handles Android runtime BLE permission requests.
// Must be called before scanning — flutter_blue_plus will throw if permissions
// are not granted.
//
// Android 12+ requires BLUETOOTH_SCAN and BLUETOOTH_CONNECT at runtime.
// Android 11 and below requires ACCESS_FINE_LOCATION at runtime.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BlePermissions {
  /// Request all necessary BLE permissions.
  /// Returns true if all granted, false otherwise.
  static Future<bool> request(BuildContext context) async {
    // flutter_blue_plus handles the platform-specific permission requests
    if (Platform.isAndroid) {
      final status = await FlutterBluePlus.adapterState.first;
      if (status == BluetoothAdapterState.unauthorized) {
        // Prompt the user
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Bluetooth permission needed'),
              content: const Text(
                'Somerset EV needs Bluetooth access to connect to your tractor.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return false;
      }

      if (status == BluetoothAdapterState.off) {
        // Ask user to enable Bluetooth
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Bluetooth is off'),
              content: const Text('Please enable Bluetooth to connect to your tractor.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return false;
      }
    }
    return true;
  }
}
