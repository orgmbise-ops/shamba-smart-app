import 'package:flutter/material.dart';

import '../models/farm_news.dart';
import '../theme/app_theme.dart';

class NewsFeed extends StatelessWidget {
  const NewsFeed({super.key, required this.articles});
  final List<FarmNews> articles;

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'prices':
      case 'bei':
        return AppColors.solarYellow;
      case 'weather':
      case 'mvua':
        return AppColors.infoBlue;
      case 'disease':
      case 'magonjwa':
        return AppColors.dangerRed;
      default:
        return AppColors.mintGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Hakuna habari zilizohifadhiwa bado.',
              style: TextStyle(color: AppColors.textLightMuted)),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: articles.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final n = articles[i];
          return ListTile(
            leading: Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(color: _categoryColor(n.category), shape: BoxShape.circle),
            ),
            title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('${n.publisher} · ${n.timeAgo}',
                style: const TextStyle(fontSize: 12, color: AppColors.textLightMuted)),
          );
        },
      ),
    );
  }
}
