import 'package:flutter/material.dart';

import '../models/weather_forecast.dart';
import '../theme/app_theme.dart';

/// Expandable weather card for the Home screen: collapsed shows just
/// temperature + condition; expanded reveals humidity, wind, and a
/// horizontally-scrolling multi-day forecast pill row.
class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key, this.forecast});

  final WeatherForecast? forecast;

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  bool _expanded = false;

  IconData _iconFor(String key) {
    switch (key) {
      case 'rain':
        return Icons.water_drop;
      case 'cloud':
        return Icons.cloud;
      case 'storm':
        return Icons.thunderstorm;
      default:
        return Icons.wb_sunny;
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.forecast;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconFor(f?.condition.toLowerCase() ?? 'sun'),
                      color: AppColors.solarYellow, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f == null ? '--°C' : '${f.currentTemp.toStringAsFixed(0)}°C',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          f == null ? 'Loading…' : '${f.condition} · ${f.location}',
                          style: const TextStyle(color: AppColors.textLightMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textLightMuted),
                ],
              ),
              if (_expanded && f != null) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(icon: Icons.water_drop_outlined, label: '${f.humidity}% Unyevu'),
                    _StatChip(icon: Icons.air, label: '${f.windSpeed.toStringAsFixed(0)} km/h'),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: f.forecastDays.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final d = f.forecastDays[i];
                      return Container(
                        width: 68,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.obsidian,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(d.dayName, style: const TextStyle(fontSize: 11)),
                            const SizedBox(height: 6),
                            Icon(_iconFor(d.conditionIcon), size: 18, color: AppColors.mintGreen),
                            const SizedBox(height: 6),
                            Text('${d.highTemp.toStringAsFixed(0)}° / ${d.lowTemp.toStringAsFixed(0)}°',
                                style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textLightMuted),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLightMuted)),
      ],
    );
  }
}
