import 'package:isar/isar.dart';

part 'weather_forecast.g.dart';

@embedded
class DayForecast {
  String dayName = '';
  double highTemp = 0;
  double lowTemp = 0;
  String conditionIcon = 'sun'; // maps to an icon key in the UI
}

/// Cached weather snapshot for offline display on the Home screen.
/// Only one row is kept (id fixed at 1) — each refresh overwrites it.
@collection
class WeatherForecast {
  Id id = 1;

  String location = 'Dodoma, TZ';
  double currentTemp = 0;
  String condition = 'Sunny';
  int humidity = 0;
  double windSpeed = 0;
  List<DayForecast> forecastDays = [];
  DateTime updatedAt = DateTime.now();
}
