import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/farm_news.dart';
import '../models/weather_forecast.dart';
import 'database_service.dart';

/// ============================================================
/// OFFLINE-FIRST SYNC ENGINE
/// ------------------------------------------------------------
/// Responsibilities:
///  1. Watch connectivity_plus for online/offline transitions.
///  2. PUSH: whenever we regain connectivity, flush every Isar
///     row with isSynced == false to Supabase (soil_logs,
///     actuator_states) via bulk upsert, then flag them synced.
///  3. PULL: opportunistically refresh FarmNews + WeatherForecast
///     from Supabase into Isar so they're available next time the
///     farmer is offline.
///
/// On web builds, DatabaseService has no local Isar instance, so
/// this service simply no-ops its push step and lets the UI talk
/// to Supabase directly (see ConnectionManager for that branch).
/// ============================================================
class SyncService {
  SyncService({
    required this.supabase,
    required this.db,
  });

  final SupabaseClient supabase;
  final DatabaseService db;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);

  Timer? _pullTimer;

  Future<void> start() async {
    final initial = await Connectivity().checkConnectivity();
    _handleConnectivity(initial);

    _connSub = Connectivity().onConnectivityChanged.listen(_handleConnectivity);

    // Periodic background pull for news/weather while online, every 15 min.
    _pullTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (isOnline.value) pullRemoteCaches();
    });
  }

  void dispose() {
    _connSub?.cancel();
    _pullTimer?.cancel();
  }

  void _handleConnectivity(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    final wasOffline = !isOnline.value;
    isOnline.value = online;

    if (online && wasOffline) {
      // Reconnected — flush the offline mutation queue immediately.
      unawaited(pushLocalMutations());
      unawaited(pullRemoteCaches());
    }
  }

  /// Trigger a manual sync (e.g. pull-to-refresh on the dashboard).
  Future<void> syncNow() async {
    if (!isOnline.value) return;
    await pushLocalMutations();
    await pullRemoteCaches();
  }

  // ---------------------------------------------------------------
  // PUSH: offline mutation queue -> Supabase
  // ---------------------------------------------------------------
  Future<void> pushLocalMutations() async {
    if (!db.isReady) return; // web build: nothing local to push
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    isSyncing.value = true;
    try {
      await _pushSoilLogs(userId);
      await _pushActuatorStates(userId);
    } catch (e, st) {
      debugPrint('SyncService.pushLocalMutations failed: $e\n$st');
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> _pushSoilLogs(String userId) async {
    final pending = await db.unsyncedSoilLogs();
    if (pending.isEmpty) return;

    final rows = pending.map((l) => l.toSupabaseRow(userId)).toList();
    await supabase.from('soil_logs').upsert(rows);
    await db.markSoilLogsSynced(pending.map((l) => l.id).toList());
  }

  Future<void> _pushActuatorStates(String userId) async {
    final pending = await db.unsyncedActuatorStates();
    if (pending.isEmpty) return;

    final rows = pending.map((a) => a.toSupabaseRow(userId)).toList();
    await supabase.from('actuator_states').upsert(rows, onConflict: 'device_id');
    await db.markActuatorStatesSynced(pending.map((a) => a.id).toList());
  }

  // ---------------------------------------------------------------
  // PULL: Supabase -> local Isar cache (for offline viewing)
  // ---------------------------------------------------------------
  Future<void> pullRemoteCaches() async {
    if (!db.isReady) return; // web build reads Supabase live instead
    try {
      final newsRows = await supabase
          .from('farm_news')
          .select()
          .order('cached_at', ascending: false)
          .limit(30);
      final articles = (newsRows as List)
          .map((row) => FarmNews.fromMap(row as Map<String, dynamic>))
          .toList();
      if (articles.isNotEmpty) await db.cacheNews(articles);
    } catch (e) {
      debugPrint('SyncService: news pull skipped ($e)');
    }

    try {
      final weatherRow = await supabase
          .from('weather_cache')
          .select()
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (weatherRow != null) {
        final forecast = WeatherForecast()
          ..location = weatherRow['location'] ?? 'Dodoma, TZ'
          ..currentTemp = (weatherRow['current_temp'] ?? 0).toDouble()
          ..condition = weatherRow['condition'] ?? 'Sunny'
          ..humidity = weatherRow['humidity'] ?? 0
          ..windSpeed = (weatherRow['wind_speed'] ?? 0).toDouble()
          ..updatedAt = DateTime.now();
        await db.cacheWeather(forecast);
      }
    } catch (e) {
      debugPrint('SyncService: weather pull skipped ($e)');
    }
  }
}
