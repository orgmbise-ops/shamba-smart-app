import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../services/connection_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/sensor_gauge.dart';

/// MonitorScreen — live telemetry gauges + hardware link status.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _linkLabel(HardwareLink link) {
    switch (link) {
      case HardwareLink.ble:
        return 'BLE Live';
      case HardwareLink.cloudMqtt:
        return 'Cloud MQTT';
      case HardwareLink.offline:
        return 'Offline';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestSoilLogProvider);
    final link = ref.watch(hardwareLinkProvider).value ?? HardwareLink.offline;
    final connMgr = ref.read(connectionManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_searching),
            tooltip: 'Scan for ESP32 (BLE)',
            onPressed: () async {
              final ok = await connMgr.scanAndConnectBle();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'ESP32 imeunganishwa (BLE)' : 'Haikupata kifaa cha ESP32')),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _LinkBadge(link: link, label: _linkLabel(link)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              SensorGauge(
                label: 'Unyevu wa Udongo',
                value: latest?.soilMoisture.toStringAsFixed(1) ?? '--',
                unit: '%',
                icon: Icons.opacity,
                isWarning: (latest?.soilMoisture ?? 100) < 25,
              ),
              SensorGauge(
                label: 'pH',
                value: latest?.ph.toStringAsFixed(1) ?? '--',
                unit: '',
                icon: Icons.science,
                isWarning: latest != null && (latest.ph < 5.5 || latest.ph > 7.5),
              ),
              SensorGauge(
                label: 'EC',
                value: latest?.ec.toStringAsFixed(2) ?? '--',
                unit: 'mS/cm',
                icon: Icons.bolt,
              ),
              SensorGauge(
                label: 'Joto',
                value: latest?.temperature.toStringAsFixed(1) ?? '--',
                unit: '°C',
                icon: Icons.thermostat,
              ),
              SensorGauge(
                label: 'Unyevu wa Hewa',
                value: latest?.humidity.toStringAsFixed(1) ?? '--',
                unit: '%',
                icon: Icons.water_drop,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (latest != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Sasisho la mwisho: ${latest.timestamp.toLocal()}',
                style: const TextStyle(fontSize: 12, color: AppColors.textLightMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinkBadge extends StatelessWidget {
  const _LinkBadge({required this.link, required this.label});
  final HardwareLink link;
  final String label;

  Color get _color {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.sensors, color: _color, size: 18),
          const SizedBox(width: 8),
          Text('Muunganisho: $label', style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
