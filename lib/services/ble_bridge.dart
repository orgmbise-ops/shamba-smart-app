/// Conditional export: picks the real BLE implementation on mobile/desktop
/// (anywhere `dart:io` exists) and the no-op stub on web. This is what lets
/// ConnectionManager import a single `BleBridge` class name and work on
/// every platform without any runtime branching in the calling code.
export 'ble_bridge_stub.dart' if (dart.library.io) 'ble_bridge_mobile.dart';
