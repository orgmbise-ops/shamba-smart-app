import 'package:isar/isar.dart';

part 'actuator_state.g.dart';

/// Local mirror of a physical actuator (currently: the water pump relay).
/// Toggling while offline writes here with isSynced=false; SyncService
/// later reconciles it with the Supabase `actuator_states` table and/or
/// re-sends the command over BLE/MQTT once a transport is available.
@collection
class ActuatorState {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String deviceId;

  bool waterPumpEnabled = false;
  late DateTime lastUpdated;

  @Index()
  bool isSynced = false;

  ActuatorState();

  factory ActuatorState.create({
    required String deviceId,
    required bool waterPumpEnabled,
  }) =>
      ActuatorState()
        ..deviceId = deviceId
        ..waterPumpEnabled = waterPumpEnabled
        ..lastUpdated = DateTime.now()
        ..isSynced = false;

  Map<String, dynamic> toSupabaseRow(String userId) => {
        'device_id': deviceId,
        'user_id': userId,
        'water_pump_enabled': waterPumpEnabled,
        'last_updated': lastUpdated.toIso8601String(),
      };
}
