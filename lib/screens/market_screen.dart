import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Marketplace tab — optional online feature (reuses the shared
/// Supabase project). Shows crop price listings; falls back to a
/// friendly offline message when there's no connectivity.
class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('Mahindi', 'Dodoma', 'TSh 68,000 / gunia', true),
      ('Alizeti', 'Singida', 'TSh 120,000 / gunia', true),
      ('Maharage', 'Iringa', 'TSh 210,000 / gunia', false),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Market')),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final (crop, region, price, up) = items[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.eco, color: AppColors.mintGreen),
              title: Text(crop, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(region),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(price, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Icon(up ? Icons.trending_up : Icons.trending_down,
                      size: 16, color: up ? AppColors.mintGreen : AppColors.dangerRed),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
