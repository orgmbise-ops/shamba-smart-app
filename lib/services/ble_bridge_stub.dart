import 'dart:async';

/// Web builds have no BLE transport (browsers can't reliably do GATT
/// scanning/notify across platforms), so this stub keeps ConnectionManager's
/// API identical while doing nothing. Selected automatically for web by
/// ble_bridge.dart's conditional export — see that file for how.
class BleBridge {
  final _telemetryController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get telemetryStream => _telemetryController.stream;
  String get deviceLabel => 'web (no BLE)';

  Future<bool> scanAndConnect({Duration timeout = const Duration(seconds: 8)}) async => false;
  Future<void> writePumpCommand(bool enabled) async {}
  Future<void> disconnect() async {}
  void dispose() => _telemetryController.close();
}
