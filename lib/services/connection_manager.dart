import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';

import '../models/soil_log.dart';
import '../models/actuator_state.dart';
import 'ble_bridge.dart';
import 'database_service.dart';
import 'mqtt_factory.dart';

enum HardwareLink { ble, cloudMqtt, offline }

/// ============================================================
/// HARDWARE TELEMETRY & REMOTE CONTROL
/// ------------------------------------------------------------
/// Two transports, one API surface, and — importantly — both are
/// platform-safe:
///
///  • BLE (mobile/desktop only, via [BleBridge]): scans for the ESP32's
///    "FFE0" service, subscribes to its telemetry characteristic, parses
///    each JSON frame into a SoilLog, and persists it to Isar immediately.
///    On web, `ble_bridge.dart` resolves to a no-op stub at compile time
///    (see that file) — there is no dart:io/BLE code in the web bundle.
///
///  • MQTT (works everywhere, incl. web): native TCP/TLS sockets on
///    mobile/desktop, secure WebSockets in the browser. `mqtt_factory.dart`
///    picks the right client class per platform at compile time, so this
///    file only ever talks to the transport-agnostic `MqttClient` API.
///
/// This is also how the web build satisfies "must be able to connect to
/// ESP32": the ESP32 firmware publishes telemetry over MQTT either way,
/// and any client (mobile via BLE+MQTT, or a browser via MQTT-over-WS)
/// can subscribe to the same topics and control the same pump.
///
/// UI code should depend on [ConnectionManager] only — it never needs to
/// know which transport, or which platform, is actually active.
/// ============================================================
class ConnectionManager {
  ConnectionManager({required this.db}) {
    _ble.telemetryStream.listen(_onBleTelemetry);
  }

  final DatabaseService db;
  final BleBridge _ble = BleBridge();

  final ValueNotifier<HardwareLink> activeLink =
      ValueNotifier<HardwareLink>(HardwareLink.offline);

  MqttClient? _mqttClient;

  // ---------------------------------------------------------------
  // BLE (no-op automatically on web — see ble_bridge.dart)
  // ---------------------------------------------------------------
  Future<bool> scanAndConnectBle({Duration timeout = const Duration(seconds: 8)}) async {
    final ok = await _ble.scanAndConnect(timeout: timeout);
    if (ok) activeLink.value = HardwareLink.ble;
    return ok;
  }

  void _onBleTelemetry(List<int> bytes) {
    try {
      final jsonStr = utf8.decode(bytes);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final log = SoilLog.fromTelemetry(
        soilMoisture: (map['moisture'] ?? 0).toDouble(),
        ph: (map['ph'] ?? 0).toDouble(),
        ec: (map['ec'] ?? 0).toDouble(),
        temperature: (map['temp'] ?? 0).toDouble(),
        humidity: (map['humidity'] ?? 0).toDouble(),
        deviceId: _ble.deviceLabel,
      );
      if (db.isReady) unawaited(db.saveSoilLog(log));
    } catch (e) {
      debugPrint('ConnectionManager: malformed BLE frame ($e)');
    }
  }

  Future<void> disconnectBle() async {
    await _ble.disconnect();
    if (activeLink.value == HardwareLink.ble) {
      activeLink.value =
          _mqttClient?.connectionStatus?.state == MqttConnectionState.connected
              ? HardwareLink.cloudMqtt
              : HardwareLink.offline;
    }
  }

  /// Writes a pump command via whichever transport is active. Falls back
  /// to MQTT (which also works from the browser) whenever BLE isn't the
  /// current link — so the web app can always control the pump.
  Future<void> setPumpState(String deviceId, bool enabled) async {
    final state = ActuatorState.create(deviceId: deviceId, waterPumpEnabled: enabled);
    if (db.isReady) await db.saveActuatorState(state); // offline queue write

    if (activeLink.value == HardwareLink.ble) {
      await _ble.writePumpCommand(enabled);
    } else {
      await _publishPumpCommandMqtt(deviceId, enabled);
    }
  }

  // ---------------------------------------------------------------
  // MQTT (works on mobile, desktop, AND web — see mqtt_factory.dart)
  // ---------------------------------------------------------------
  Future<bool> connectMqtt({
    required String broker,
    required int port,
    required String deviceId,
    String? username,
    String? password,
  }) async {
    if (_mqttClient?.connectionStatus?.state == MqttConnectionState.connected) {
      return true; // already connected — avoid reconnect storms on flaky networks
    }

    final client = createPlatformMqttClient(
      broker,
      'shamba_smart_${DateTime.now().millisecondsSinceEpoch}',
      port,
    );
    client.logging(on: false);
    client.keepAlivePeriod = 30;
    client.onDisconnected = () {
      if (activeLink.value == HardwareLink.cloudMqtt) {
        activeLink.value = HardwareLink.offline;
      }
    };

    final connMsg = MqttConnectMessage().withClientIdentifier('shamba_smart').startClean();
    client.connectionMessage = connMsg;

    try {
      await client.connect(username, password);
    } catch (e) {
      debugPrint('ConnectionManager: MQTT connect failed ($e)');
      client.disconnect();
      return false;
    }

    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      return false;
    }

    _mqttClient = client;
    if (activeLink.value != HardwareLink.ble) {
      activeLink.value = HardwareLink.cloudMqtt;
    }

    final telemetryTopic = 'shamba/$deviceId/telemetry';
    client.subscribe(telemetryTopic, MqttQos.atLeastOnce);
    client.updates!.listen((events) {
      final rec = events[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(rec.payload.message);
      _onMqttTelemetry(deviceId, payload);
    });

    return true;
  }

  void _onMqttTelemetry(String deviceId, String payload) {
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final log = SoilLog.fromTelemetry(
        soilMoisture: (map['moisture'] ?? 0).toDouble(),
        ph: (map['ph'] ?? 0).toDouble(),
        ec: (map['ec'] ?? 0).toDouble(),
        temperature: (map['temp'] ?? 0).toDouble(),
        humidity: (map['humidity'] ?? 0).toDouble(),
        deviceId: deviceId,
      );
      if (db.isReady) unawaited(db.saveSoilLog(log));
    } catch (e) {
      debugPrint('ConnectionManager: malformed MQTT payload ($e)');
    }
  }

  Future<void> _publishPumpCommandMqtt(String deviceId, bool enabled) async {
    final client = _mqttClient;
    if (client == null || client.connectionStatus?.state != MqttConnectionState.connected) {
      return; // queued locally via ActuatorState.isSynced=false; retried on reconnect
    }
    final topic = 'shamba/$deviceId/pump/set';
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode({'enabled': enabled}));
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void dispose() {
    _ble.dispose();
    _mqttClient?.disconnect();
  }
}
