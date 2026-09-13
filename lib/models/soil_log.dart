import 'package:isar/isar.dart';

part 'soil_log.g.dart';

/// A single reading of the farm's soil / environmental telemetry.
///
/// Records are written locally the instant they arrive from BLE/MQTT
/// (or are entered manually while offline), with [isSynced] = false.
/// [SyncService] later pushes any `isSynced == false` rows to the
/// Supabase `soil_logs` table and flips the flag once acknowledged.
@collection
class SoilLog {
  Id id = Isar.autoIncrement;

  /// Server-side UUID once synced (kept null while purely local).
  String? remoteId;

  @Index()
  late DateTime timestamp;

  double soilMoisture = 0; // %
  double ph = 0; // 0-14
  double ec = 0; // mS/cm
  double temperature = 0; // °C
  double humidity = 0; // % RH

  /// Which device produced this reading (BLE MAC / MQTT client id).
  String deviceId = 'unknown';

  /// True once this row has been upserted into Supabase `soil_logs`.
  @Index()
  bool isSynced = false;

  SoilLog();

  factory SoilLog.fromTelemetry({
    required double soilMoisture,
    required double ph,
    required double ec,
    required double temperature,
    required double humidity,
    required String deviceId,
    DateTime? timestamp,
  }) {
    return SoilLog()
      ..timestamp = timestamp ?? DateTime.now()
      ..soilMoisture = soilMoisture
      ..ph = ph
      ..ec = ec
      ..temperature = temperature
      ..humidity = humidity
      ..deviceId = deviceId
      ..isSynced = false;
  }

  Map<String, dynamic> toSupabaseRow(String userId) => {
        if (remoteId != null) 'id': remoteId,
        'user_id': userId,
        'device_id': deviceId,
        'soil_moisture': soilMoisture,
        'ph': ph,
        'ec': ec,
        'temperature': temperature,
        'humidity': humidity,
        'recorded_at': timestamp.toIso8601String(),
      };
}
