import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Native (mobile/desktop) MQTT transport: a plain TCP/TLS socket client.
MqttClient createPlatformMqttClient(String server, String clientId, int port) {
  return MqttServerClient.withPort(server, clientId, port)..secure = true;
}
