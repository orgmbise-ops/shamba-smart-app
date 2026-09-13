import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A single telemetry readout tile used on the Monitor/Dashboard screen.
class SensorGauge extends StatelessWidget {
  const SensorGauge({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.isWarning = false,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final valueColor = isWarning ? AppColors.solarYellow : AppColors.mintGreen;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: valueColor, size: 20),
            const SizedBox(height: 10),
            Text(label.toUpperCase(),
                style: const TextStyle(fontSize: 11, letterSpacing: 0.5, color: AppColors.textLightMuted)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: valueColor)),
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(fontSize: 12, color: AppColors.textLightMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
