import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Real BLE transport for mobile/desktop: scans for the ESP32's "FFE0"
/// service, subscribes to its telemetry characteristic, and exposes a
/// broadcast stream of raw frames plus a pump-command writer.
class BleBridge {
  static const _serviceUuid = 'FFE0';
  static const _telemetryCharUuid = 'FFE1';
  static const _pumpCharUuid = 'FFE2';

  final _telemetryController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get telemetryStream => _telemetryController.stream;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _telemetryChar;
  BluetoothCharacteristic? _pumpChar;
  StreamSubscription<List<int>>? _sub;

  String get deviceLabel => _device?.remoteId.str ?? 'esp32-ble';

  Future<bool> scanAndConnect({Duration timeout = const Duration(seconds: 8)}) async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) return false;

      final completer = Completer<BluetoothDevice?>();
      final scanSub = FlutterBluePlus.onScanResults.listen((results) {
        for (final r in results) {
          final uuids = r.advertisementData.serviceUuids
              .map((g) => g.str.toUpperCase())
              .toList();
          if (uuids.any((u) => u.contains(_serviceUuid)) && !completer.isCompleted) {
            completer.complete(r.device);
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: timeout);
      final device = await completer.future.timeout(timeout, onTimeout: () => null);
      await FlutterBluePlus.stopScan();
      await scanSub.cancel();
      if (device == null) return false;

      // flutter_blue_plus 2.x requires the license argument on connect.
      await device.connect(
        timeout: const Duration(seconds: 10),
        license: License.free,
      );
      final services = await device.discoverServices();
      final svc = services.firstWhere(
        (s) => s.uuid.str.toUpperCase().contains(_serviceUuid),
      );
      _telemetryChar = svc.characteristics.firstWhere(
        (c) => c.uuid.str.toUpperCase().contains(_telemetryCharUuid),
      );
      _pumpChar = svc.characteristics.firstWhere(
        (c) => c.uuid.str.toUpperCase().contains(_pumpCharUuid),
      );

      await _telemetryChar!.setNotifyValue(true);
      _sub = _telemetryChar!.onValueReceived.listen(_telemetryController.add);
      _device = device;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> writePumpCommand(bool enabled) async {
    await _pumpChar?.write([enabled ? 0x01 : 0x00], withoutResponse: true);
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    await _device?.disconnect();
    _device = null;
    _telemetryChar = null;
    _pumpChar = null;
  }

  void dispose() => _telemetryController.close();
}
