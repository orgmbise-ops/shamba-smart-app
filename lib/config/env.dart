/// Compile-time configuration, injected via --dart-define at build time
/// (see README). Centralizing these here means main.dart and any service
/// that needs them import one small file instead of duplicating consts.
class Env {
  Env._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR-PROJECT.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR-ANON-KEY',
  );

  /// MQTT broker used as the fallback/web transport to reach the ESP32.
  /// For HiveMQ Cloud (free tier), this is your cluster URL, e.g.
  /// "xxxxxxxx.s1.eu.hivemq.cloud". Native builds connect over TLS on
  /// MQTT_PORT (commonly 8883); web builds connect over secure WebSockets
  /// on MQTT_WS_PORT (commonly 8884) — see mqtt_factory_web.dart.
  static const mqttBroker = String.fromEnvironment(
    'MQTT_BROKER',
    defaultValue: 'YOUR-CLUSTER.hivemq.cloud',
  );
  static const mqttPort = int.fromEnvironment('MQTT_PORT', defaultValue: 8883);
  static const mqttWsPort = int.fromEnvironment('MQTT_WS_PORT', defaultValue: 8884);
  static const mqttUsername = String.fromEnvironment('MQTT_USERNAME', defaultValue: '');
  static const mqttPassword = String.fromEnvironment('MQTT_PASSWORD', defaultValue: '');

  static bool get hasMqttConfig => mqttUsername.isNotEmpty && mqttBroker.contains('.');
}
