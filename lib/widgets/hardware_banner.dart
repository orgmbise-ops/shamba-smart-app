import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ESP32 "Smart Farm Manager" promo/status card with the pump toggle.
class HardwareBanner extends StatelessWidget {
  const HardwareBanner({
    super.key,
    required this.pumpEnabled,
    required this.onPumpChanged,
    required this.linkLabel,
    required this.linkColor,
  });

  final bool pumpEnabled;
  final ValueChanged<bool> onPumpChanged;
  final String linkLabel;
  final Color linkColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primaryGreen,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.memory, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ESP32 Smart Farm Manager',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text('BLE + Cloud MQTT dual-mode controller',
                          style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: linkColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: linkColor),
                  ),
                  child: Text(linkLabel,
                      style: TextStyle(fontSize: 10, color: linkColor, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.water_drop, color: Colors.white),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Pampu ya Maji', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                Switch(value: pumpEnabled, onChanged: onPumpChanged),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
