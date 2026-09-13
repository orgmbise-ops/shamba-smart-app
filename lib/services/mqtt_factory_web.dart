import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

/// Browser MQTT transport: connects over secure WebSockets, since raw TCP
/// sockets aren't available to web apps. Your broker (HiveMQ Cloud, etc.)
/// must have a WebSocket listener enabled — see README for the endpoint.
MqttClient createPlatformMqttClient(String server, String clientId, int port) {
  final wsUrl = 'wss://$server:$port/mqtt';
  return MqttBrowserClient(wsUrl, clientId);
}
