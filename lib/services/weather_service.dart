import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherData> fetchWeather({
    double latitude = 52.52,
    double longitude = 13.41,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'latitude': latitude.toStringAsFixed(4),
        'longitude': longitude.toStringAsFixed(4),
        'current': [
          'temperature_2m',
          'relative_humidity_2m',
          'apparent_temperature',
          'wind_speed_10m',
          'wind_direction_10m',
          'surface_pressure',
        ].join(','),
        'daily': [
          'temperature_2m_max',
          'temperature_2m_min',
          'weather_code',
          'precipitation_probability_max',
          'uv_index_max',
          'sunrise',
          'sunset',
          'wind_speed_10m_max',
          'wind_direction_10m_dominant',
        ].join(','),
        'hourly': [
          'temperature_2m',
          'weather_code',
          'precipitation_probability',
          'wind_speed_10m',
        ].join(','),
        'timezone': 'auto',
        'forecast_days': '7',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return WeatherData.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }
  }
}
