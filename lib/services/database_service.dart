import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/soil_log.dart';
import '../models/farm_news.dart';
import '../models/weather_forecast.dart';
import '../models/actuator_state.dart';

/// Owns the single Isar instance for the app.
///
/// Every other service/provider reads/writes through this class so
/// there is exactly one source of truth for local persistence, and
/// exactly one place that needs to know about Isar's schema list.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Isar? _isar;
  Isar get isar {
    final db = _isar;
    if (db == null) {
      throw StateError('DatabaseService.init() must be awaited before use.');
    }
    return db;
  }

  bool get isReady => _isar != null;

  Future<void> init() async {
    if (_isar != null) return;

    // Web builds don't get a local Isar file — the app runs online-first
    // against Supabase directly (see ConnectionManager / SyncService).
    if (kIsWeb) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        SoilLogSchema,
        FarmNewsSchema,
        WeatherForecastSchema,
        ActuatorStateSchema,
      ],
      directory: dir.path,
      name: 'shamba_smart_db',
    );
  }

  // ---------------------------------------------------------------
  // Soil logs
  // ---------------------------------------------------------------
  Future<void> saveSoilLog(SoilLog log) async {
    await isar.writeTxn(() => isar.soilLogs.put(log));
  }

  Stream<List<SoilLog>> watchRecentSoilLogs({int limit = 50}) {
    return isar.soilLogs
        .where()
        .sortByTimestampDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  Future<List<SoilLog>> unsyncedSoilLogs() =>
      isar.soilLogs.filter().isSyncedEqualTo(false).findAll();

  Future<void> markSoilLogsSynced(List<Id> ids) async {
    await isar.writeTxn(() async {
      for (final id in ids) {
        final log = await isar.soilLogs.get(id);
        if (log != null) {
          log.isSynced = true;
          await isar.soilLogs.put(log);
        }
      }
    });
  }

  // ---------------------------------------------------------------
  // Actuator state (water pump, etc.)
  // ---------------------------------------------------------------
  Future<void> saveActuatorState(ActuatorState state) async {
    await isar.writeTxn(() => isar.actuatorStates.put(state));
  }

  Future<ActuatorState?> getActuatorState(String deviceId) =>
      isar.actuatorStates.filter().deviceIdEqualTo(deviceId).findFirst();

  Stream<ActuatorState?> watchActuatorState(String deviceId) => isar.actuatorStates
      .filter()
      .deviceIdEqualTo(deviceId)
      .watch(fireImmediately: true)
      .map((list) => list.isEmpty ? null : list.first);

  Future<List<ActuatorState>> unsyncedActuatorStates() =>
      isar.actuatorStates.filter().isSyncedEqualTo(false).findAll();

  Future<void> markActuatorStatesSynced(List<Id> ids) async {
    await isar.writeTxn(() async {
      for (final id in ids) {
        final state = await isar.actuatorStates.get(id);
        if (state != null) {
          state.isSynced = true;
          await isar.actuatorStates.put(state);
        }
      }
    });
  }

  // ---------------------------------------------------------------
  // News cache
  // ---------------------------------------------------------------
  Future<void> cacheNews(List<FarmNews> articles) async {
    await isar.writeTxn(() => isar.farmNews.putAll(articles));
  }

  Stream<List<FarmNews>> watchNews() =>
      isar.farmNews.where().sortByCachedAtDesc().watch(fireImmediately: true);

  // ---------------------------------------------------------------
  // Weather cache
  // ---------------------------------------------------------------
  Future<void> cacheWeather(WeatherForecast forecast) async {
    await isar.writeTxn(() => isar.weatherForecasts.put(forecast));
  }

  Stream<WeatherForecast?> watchWeather() =>
      isar.weatherForecasts.watchObject(1, fireImmediately: true);
}
