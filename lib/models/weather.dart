class WeatherData {
  final double latitude;
  final double longitude;
  final CurrentWeather? current;
  final List<DailyWeather> daily;
  final Map<int, List<HourlyWeather>> hourlyByDay;

  WeatherData({
    required this.latitude,
    required this.longitude,
    this.current,
    required this.daily,
    required this.hourlyByDay,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final daily = json['daily'] as Map<String, dynamic>? ?? {};
    final times = (daily['time'] as List?) ?? [];
    final tempsMax = (daily['temperature_2m_max'] as List?) ?? [];
    final tempsMin = (daily['temperature_2m_min'] as List?) ?? [];
    final codes = (daily['weather_code'] as List?) ?? [];
    final precip = (daily['precipitation_probability_max'] as List?) ?? [];
    final uv = (daily['uv_index_max'] as List?) ?? [];
    final sunrise = (daily['sunrise'] as List?) ?? [];
    final sunset = (daily['sunset'] as List?) ?? [];
    final wsMax = (daily['wind_speed_10m_max'] as List?) ?? [];
    final wdDom = (daily['wind_direction_10m_dominant'] as List?) ?? [];

    CurrentWeather? current;
    if (json['current'] != null) {
      final c = json['current'] as Map<String, dynamic>;
      current = CurrentWeather(
        temperature: (c['temperature_2m'] as num?)?.toDouble() ?? 0,
        humidity: (c['relative_humidity_2m'] as num?)?.toInt() ?? 0,
        apparentTemperature: (c['apparent_temperature'] as num?)?.toDouble(),
        windSpeed: (c['wind_speed_10m'] as num?)?.toDouble(),
        windDirection: (c['wind_direction_10m'] as num?)?.toDouble(),
        pressure: (c['surface_pressure'] as num?)?.toDouble(),
      );
    }

    final dailyList = List.generate(times.length, (i) => DailyWeather(
      date: times[i] as String,
      temperatureMax: (tempsMax[i] as num).toDouble(),
      temperatureMin: (tempsMin[i] as num).toDouble(),
      weatherCode: (codes[i] as num).toInt(),
      precipitationProbability: i < precip.length ? (precip[i] as num?)?.toDouble() : null,
      uvIndex: i < uv.length ? (uv[i] as num?)?.toDouble() : null,
      sunrise: i < sunrise.length ? sunrise[i]?.toString() : null,
      sunset: i < sunset.length ? sunset[i]?.toString() : null,
      windSpeedMax: i < wsMax.length ? (wsMax[i] as num?)?.toDouble() : null,
      windDirection: i < wdDom.length ? (wdDom[i] as num?)?.toDouble() : null,
    ));

    Map<int, List<HourlyWeather>> hourlyByDay = {};
    if (json['hourly'] != null) {
      final h = json['hourly'] as Map<String, dynamic>;
      final hTimes = (h['time'] as List?) ?? [];
      final hTemps = (h['temperature_2m'] as List?) ?? [];
      final hCodes = (h['weather_code'] as List?) ?? [];
      final hPrecip = (h['precipitation_probability'] as List?) ?? [];
      final hWind = (h['wind_speed_10m'] as List?) ?? [];

      for (int i = 0; i < hTimes.length; i++) {
        final dt = DateTime.tryParse(hTimes[i] as String);
        if (dt == null) continue;
        final dayKey = DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
        hourlyByDay.putIfAbsent(dayKey, () => []);
        hourlyByDay[dayKey]!.add(HourlyWeather(
          time: hTimes[i] as String,
          temperature: (hTemps[i] as num?)?.toDouble() ?? 0,
          weatherCode: (hCodes[i] as num?)?.toInt() ?? 0,
          precipitationProbability: i < hPrecip.length ? (hPrecip[i] as num?)?.toDouble() : null,
          windSpeed: i < hWind.length ? (hWind[i] as num?)?.toDouble() : null,
        ));
      }
    }

    return WeatherData(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      current: current,
      daily: dailyList,
      hourlyByDay: hourlyByDay,
    );
  }
}

class CurrentWeather {
  final double temperature;
  final int humidity;
  final double? apparentTemperature;
  final double? windSpeed;
  final double? windDirection;
  final double? pressure;

  CurrentWeather({
    required this.temperature,
    required this.humidity,
    this.apparentTemperature,
    this.windSpeed,
    this.windDirection,
    this.pressure,
  });
}

class DailyWeather {
  final String date;
  final double temperatureMax;
  final double temperatureMin;
  final int weatherCode;
  final double? precipitationProbability;
  final double? uvIndex;
  final String? sunrise;
  final String? sunset;
  final double? windSpeedMax;
  final double? windDirection;

  DailyWeather({
    required this.date,
    required this.temperatureMax,
    required this.temperatureMin,
    required this.weatherCode,
    this.precipitationProbability,
    this.uvIndex,
    this.sunrise,
    this.sunset,
    this.windSpeedMax,
    this.windDirection,
  });

  DateTime get dateTime => DateTime.tryParse(date) ?? DateTime.now();
}

class HourlyWeather {
  final String time;
  final double temperature;
  final int weatherCode;
  final double? precipitationProbability;
  final double? windSpeed;

  HourlyWeather({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    this.precipitationProbability,
    this.windSpeed,
  });

  DateTime get dateTime => DateTime.tryParse(time) ?? DateTime.now();
  int get hour => dateTime.hour;
}
