import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/actuator_state.dart';
import '../models/farm_news.dart';
import '../models/soil_log.dart';
import '../models/weather_forecast.dart';
import '../services/connection_manager.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/sync_service.dart';

/// The default hardware device id used throughout the demo/home
/// deployment. In a multi-device household this would come from
/// a device-picker instead of being hard-coded.
const String kDefaultDeviceId = 'esp32-farm-01';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    supabase: ref.watch(supabaseClientProvider),
    db: ref.watch(databaseServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final connectionManagerProvider = Provider<ConnectionManager>((ref) {
  final manager = ConnectionManager(db: ref.watch(databaseServiceProvider));
  ref.onDispose(manager.dispose);
  return manager;
});

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

/// True while the device has any network connectivity.
final isOnlineProvider = StreamProvider<bool>((ref) {
  final sync = ref.watch(syncServiceProvider);
  return sync.isOnline.toValueStream();
});

/// Which hardware transport is currently driving telemetry.
final hardwareLinkProvider = StreamProvider<HardwareLink>((ref) {
  final manager = ref.watch(connectionManagerProvider);
  return manager.activeLink.toValueStream();
});

/// Live-updating list of the most recent soil telemetry, newest first.
final soilLogStreamProvider = StreamProvider<List<SoilLog>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  if (!db.isReady) return const Stream.empty();
  return db.watchRecentSoilLogs();
});

final latestSoilLogProvider = Provider<SoilLog?>((ref) {
  final logs = ref.watch(soilLogStreamProvider).value ?? [];
  return logs.isEmpty ? null : logs.first;
});

final actuatorStateProvider = StreamProvider<ActuatorState?>((ref) {
  final db = ref.watch(databaseServiceProvider);
  if (!db.isReady) return const Stream.empty();
  return db.watchActuatorState(kDefaultDeviceId);
});

final newsFeedProvider = StreamProvider<List<FarmNews>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  if (!db.isReady) return const Stream.empty();
  return db.watchNews();
});

final weatherProvider = StreamProvider<WeatherForecast?>((ref) {
  final db = ref.watch(databaseServiceProvider);
  if (!db.isReady) return const Stream.empty();
  return db.watchWeather();
});

/// Small helper: turns a ValueNotifier into a broadcast Stream so it
/// can be exposed via StreamProvider without extra plumbing per call site.
extension ValueNotifierStream<T> on ValueNotifier<T> {
  Stream<T> toValueStream() {
    late final StreamController<T> controller;
    void listener() => controller.add(value);
    controller = StreamController<T>.broadcast(
      onListen: () {
        addListener(listener);
        controller.add(value);
      },
      onCancel: () => removeListener(listener),
    );
    return controller.stream;
  }
}
