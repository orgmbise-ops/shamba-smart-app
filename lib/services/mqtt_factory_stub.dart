import 'package:mqtt_client/mqtt_client.dart';

/// Fallback used only if neither dart:io nor dart:html is detected
/// (shouldn't happen on any real Flutter target) — fails loudly instead
/// of silently picking the wrong transport.
MqttClient createPlatformMqttClient(String server, String clientId, int port) {
  throw UnsupportedError('No MQTT transport available on this platform.');
}
