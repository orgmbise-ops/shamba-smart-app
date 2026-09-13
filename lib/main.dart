import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'providers/app_providers.dart';
import 'screens/root_shell.dart';
import 'services/database_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Local persistence first — the app must be fully usable with
  //    zero network, so Isar is opened before anything else. (No-op on
  //    web — see DatabaseService.init().)
  await DatabaseService.instance.init();

  // 2. Supabase client — used for auth + cloud sync when online.
  //    supabase_flutter itself initializes fine offline; individual
  //    calls simply fail/queue, which SyncService already accounts for.
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  runApp(const ProviderScope(child: ShambaSmartApp()));
}

class ShambaSmartApp extends ConsumerStatefulWidget {
  const ShambaSmartApp({super.key});

  @override
  ConsumerState<ShambaSmartApp> createState() => _ShambaSmartAppState();
}

class _ShambaSmartAppState extends ConsumerState<ShambaSmartApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapConnectivity());
  }

  /// Starts the offline-first sync engine AND makes sure there's always a
  /// path to the ESP32:
  ///  - Mobile/desktop: BLE first (see Monitor screen's scan button); MQTT
  ///    is attempted in the background as a remote/cloud fallback.
  ///  - Web: BLE is unavailable by design, so this MQTT connection (over
  ///    secure WebSockets) is the *only* path to the ESP32 — which is why
  ///    it's started unconditionally here rather than left as a manual
  ///    "Scan" action like BLE is.
  Future<void> _bootstrapConnectivity() async {
    final syncService = ref.read(syncServiceProvider);
    await syncService.start();

    if (!Env.hasMqttConfig) return; // no broker configured — BLE-only setup is fine

    final connectionManager = ref.read(connectionManagerProvider);
    final port = kIsWeb ? Env.mqttWsPort : Env.mqttPort;

    Future<void> tryConnect() async {
      if (syncService.isOnline.value) {
        await connectionManager.connectMqtt(
          broker: Env.mqttBroker,
          port: port,
          deviceId: kDefaultDeviceId,
          username: Env.mqttUsername,
          password: Env.mqttPassword,
        );
      }
    }

    syncService.isOnline.addListener(tryConnect);
    await tryConnect(); // attempt immediately in case we're already online
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shamba Smart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const RootShell(),
    );
  }
}
