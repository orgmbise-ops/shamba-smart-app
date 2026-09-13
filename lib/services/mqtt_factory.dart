/// Conditional export: native socket client on mobile/desktop, WebSocket
/// client on web. Mirrors the ble_bridge.dart pattern so ConnectionManager
/// can call one function name (`createPlatformMqttClient`) everywhere.
export 'mqtt_factory_stub.dart'
    if (dart.library.io) 'mqtt_factory_io.dart'
    if (dart.library.html) 'mqtt_factory_web.dart';
