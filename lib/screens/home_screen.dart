import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../services/connection_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/hardware_banner.dart';
import '../widgets/news_feed.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/weather_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onNavigate});

  /// Lets Home's quick-action grid jump to another bottom-nav tab.
  final void Function(int tabIndex) onNavigate;

  String _linkLabel(HardwareLink link) {
    switch (link) {
      case HardwareLink.ble:
        return 'BLE';
      case HardwareLink.cloudMqtt:
        return 'CLOUD';
      case HardwareLink.offline:
        return 'OFFLINE';
    }
  }

  Color _linkColor(HardwareLink link) {
    switch (link) {
      case HardwareLink.ble:
        return AppColors.mintGreen;
      case HardwareLink.cloudMqtt:
        return AppColors.infoBlue;
      case HardwareLink.offline:
        return AppColors.solarYellow;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider).value ?? false;
    final link = ref.watch(hardwareLinkProvider).value ?? HardwareLink.offline;
    final weather = ref.watch(weatherProvider).value;
    final news = ref.watch(newsFeedProvider).value ?? [];
    final actuator = ref.watch(actuatorStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Shamba Smart')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncServiceProvider).syncNow(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          children: [
            _StatusBanner(isOnline: isOnline),
            const SizedBox(height: 10),
            WeatherCard(forecast: weather),
            const SizedBox(height: 14),
            QuickActionGrid(
              actions: [
                QuickAction(icon: Icons.monitor_heart, label: 'Monitor', onTap: () => onNavigate(1)),
                QuickAction(icon: Icons.storefront, label: 'Market', onTap: () => onNavigate(2)),
                QuickAction(icon: Icons.smart_toy, label: 'AI Advisor', onTap: () => onNavigate(3)),
                QuickAction(icon: Icons.grid_view, label: 'Category', onTap: () => onNavigate(4)),
                QuickAction(icon: Icons.person, label: 'Biography', onTap: () => onNavigate(5)),
                QuickAction(
                  icon: Icons.bug_report,
                  label: 'Diagnose',
                  onTap: () {
                    onNavigate(3);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            HardwareBanner(
              pumpEnabled: actuator?.waterPumpEnabled ?? false,
              linkLabel: _linkLabel(link),
              linkColor: _linkColor(link),
              onPumpChanged: (v) {
                ref.read(connectionManagerProvider).setPumpState(kDefaultDeviceId, v);
              },
            ),
            const SizedBox(height: 18),
            const Text('Habari za Kilimo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            NewsFeed(articles: news),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.mintGreen : AppColors.solarYellow;
    final label = isOnline ? 'Mtandaoni · Data inasawazishwa' : 'Nje ya Mtandao · Demo/Offline Mode';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(isOnline ? Icons.cloud_done : Icons.cloud_off, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
