import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Category tab — browse crop/topic categories (news, advisory
/// content, marketplace listings) grouped for quick filtering.
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = const [
      ('Mahindi', Icons.grass),
      ('Mpunga', Icons.rice_bowl),
      ('Mboga', Icons.local_florist),
      ('Mifugo', Icons.pets),
      ('Umwagiliaji', Icons.water),
      ('Soko', Icons.storefront),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Category')),
      body: GridView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemBuilder: (context, i) {
          final (label, icon) = categories[i];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {},
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColors.mintGreen, size: 28),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
