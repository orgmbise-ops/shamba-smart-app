import 'package:isar/isar.dart';

part 'farm_news.g.dart';

/// Agricultural news article, cached locally so the feed stays
/// readable offline (pulled from Supabase whenever online).
@collection
class FarmNews {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  late String title;
  late String publisher;
  late String timeAgo;
  late String category; // e.g. Prices, Weather, Pests, Fertilizer
  String contentUrl = '';
  DateTime cachedAt = DateTime.now();

  FarmNews();

  factory FarmNews.fromMap(Map<String, dynamic> map) => FarmNews()
    ..remoteId = map['id'].toString()
    ..title = map['title'] ?? ''
    ..publisher = map['publisher'] ?? ''
    ..timeAgo = map['time_ago'] ?? ''
    ..category = map['category'] ?? 'General'
    ..contentUrl = map['content_url'] ?? ''
    ..cachedAt = DateTime.now();
}
