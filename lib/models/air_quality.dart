enum AqiLevel {
  good,
  moderate,
  unhealthySensitive,
  unhealthy,
  veryUnhealthy,
  hazardous,
}

class StationInfo {
  final String name;
  final double lat;
  final double lng;
  final int aqi;
  final String? time;

  StationInfo({
    required this.name,
    required this.lat,
    required this.lng,
    required this.aqi,
    this.time,
  });

  factory StationInfo.fromJson(Map<String, dynamic> json) {
    final latlng = (json['lat'] as num?)?.toDouble() ?? 0;
    final lnglng = (json['lon'] as num?)?.toDouble() ?? 0;
    final aqiVal = json['aqi']?.toString() ?? '';
    final timeText = json['time']?.toString().replaceAll('T', ' ');
    return StationInfo(
      name: json['station']?['name']?.toString() ?? 'Unknown',
      lat: (json['station']?['latitude'] as num?)?.toDouble() ?? latlng,
      lng: (json['station']?['longitude'] as num?)?.toDouble() ?? lnglng,
      aqi: int.tryParse(aqiVal) ?? 0,
      time: timeText?.substring(0, timeText.length < 16 ? timeText.length : 16),
    );
  }
}

class ActivityRecommendation {
  final String name;
  final String emoji;
  final bool safe;
  final String note;

  const ActivityRecommendation({
    required this.name,
    required this.emoji,
    required this.safe,
    required this.note,
  });
}

class AirQualityData {
  final int aqi;
  final String cityName;
  final double latitude;
  final double longitude;
  final double? pm25;
  final double? pm10;
  final double? o3;
  final double? no2;
  final double? so2;
  final double? co;
  final double? temperature;
  final double? humidity;
  final double? windSpeed;
  final String updatedAt;

  AirQualityData({
    required this.aqi,
    required this.cityName,
    required this.latitude,
    required this.longitude,
    this.pm25,
    this.pm10,
    this.o3,
    this.no2,
    this.so2,
    this.co,
    this.temperature,
    this.humidity,
    this.windSpeed,
    required this.updatedAt,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final iaqi = data['iaqi'] as Map<String, dynamic>? ?? {};
    final city = data['city'] as Map<String, dynamic>? ?? {};
    final geo = city['geo'] as List? ?? [];
    final timeData = data['time'] as Map<String, dynamic>? ?? {};

    double? val(String key) {
      final item = iaqi[key];
      if (item is Map) return (item['v'] as num?)?.toDouble();
      return null;
    }

    return AirQualityData(
      aqi: (data['aqi'] as num?)?.toInt() ?? 0,
      cityName: city['name']?.toString() ?? 'Unknown',
      latitude: geo.isNotEmpty ? (geo[0] as num).toDouble() : 0,
      longitude: geo.isNotEmpty ? (geo[1] as num).toDouble() : 0,
      pm25: val('pm25'),
      pm10: val('pm10'),
      o3: val('o3'),
      no2: val('no2'),
      so2: val('so2'),
      co: val('co'),
      temperature: val('t'),
      humidity: val('h'),
      windSpeed: val('w'),
      updatedAt: timeData['s']?.toString() ?? '',
    );
  }

  AqiLevel get level {
    if (aqi <= 50) return AqiLevel.good;
    if (aqi <= 100) return AqiLevel.moderate;
    if (aqi <= 150) return AqiLevel.unhealthySensitive;
    if (aqi <= 200) return AqiLevel.unhealthy;
    if (aqi <= 300) return AqiLevel.veryUnhealthy;
    return AqiLevel.hazardous;
  }

  String get levelLabel {
    switch (level) {
      case AqiLevel.good:
        return 'Good';
      case AqiLevel.moderate:
        return 'Moderate';
      case AqiLevel.unhealthySensitive:
        return 'Unhealthy (Sensitive)';
      case AqiLevel.unhealthy:
        return 'Unhealthy';
      case AqiLevel.veryUnhealthy:
        return 'Very Unhealthy';
      case AqiLevel.hazardous:
        return 'Hazardous';
    }
  }

  String get levelEmoji {
    switch (level) {
      case AqiLevel.good:
        return '😊';
      case AqiLevel.moderate:
        return '🙂';
      case AqiLevel.unhealthySensitive:
        return '😷';
      case AqiLevel.unhealthy:
        return '🤢';
      case AqiLevel.veryUnhealthy:
        return '🤮';
      case AqiLevel.hazardous:
        return '☠️';
    }
  }

  int get levelColor {
    switch (level) {
      case AqiLevel.good:
        return 0xFF00E400;
      case AqiLevel.moderate:
        return 0xFFFFFF00;
      case AqiLevel.unhealthySensitive:
        return 0xFFFF7E00;
      case AqiLevel.unhealthy:
        return 0xFFFF0000;
      case AqiLevel.veryUnhealthy:
        return 0xFF8F3F97;
      case AqiLevel.hazardous:
        return 0xFF7E0023;
    }
  }

  String get healthAdvice {
    switch (level) {
      case AqiLevel.good:
        return 'Excellent air quality! Perfect for outdoor activities, running, cycling, or any outdoor exercise. No precautions needed.';
      case AqiLevel.moderate:
        return 'Air quality is acceptable. Sensitive individuals (elderly, children, those with respiratory conditions) should limit prolonged outdoor exertion.';
      case AqiLevel.unhealthySensitive:
        return 'Sensitive groups should reduce outdoor activities. Children, elderly, and people with lung/heart disease should wear N95 masks outdoors. Close windows.';
      case AqiLevel.unhealthy:
        return 'Everyone should limit outdoor exertion. Wear N95 masks when going outside. Keep windows closed. Use air purifiers if available. Avoid outdoor exercise.';
      case AqiLevel.veryUnhealthy:
        return 'Avoid all outdoor activities. Stay indoors with windows sealed. Wear N95 masks even for short trips. Run air purifiers at max. Seek cleaner indoor environments.';
      case AqiLevel.hazardous:
        return 'Health emergency! Everyone should stay indoors. Wear N95 masks at all times indoors. Use air purifiers. Do not open windows. Seek relocation if possible.';
    }
  }

  String get shortAdvice {
    switch (level) {
      case AqiLevel.good:
        return 'Great day for outdoor activities! 🌞';
      case AqiLevel.moderate:
        return 'OK for outdoors. Sensitive groups take care.';
      case AqiLevel.unhealthySensitive:
        return 'Wear N95 mask outdoors 😷';
      case AqiLevel.unhealthy:
        return 'Limit outdoor time. Wear N95 mask.';
      case AqiLevel.veryUnhealthy:
        return 'Stay indoors! Use air purifier.';
      case AqiLevel.hazardous:
        return 'Health warning! Stay inside! ☠️';
    }
  }

  // ─── WHO Guidelines Comparison ─────────────────────────────────────
  String? get whoPm25Note {
    if (pm25 == null) return null;
    if (pm25! <= 5) return 'Within WHO safe guideline (≤5 μg/m³) ✓';
    if (pm25! <= 15) {
      return '${pm25!.toStringAsFixed(1)}x above WHO guideline of 5 μg/m³';
    }
    return '${(pm25! / 5).toStringAsFixed(1)}x above WHO safe limit!';
  }

  String? get whoPm10Note {
    if (pm10 == null) return null;
    if (pm10! <= 15) return 'Within WHO safe guideline (≤15 μg/m³) ✓';
    return '${(pm10! / 15).toStringAsFixed(1)}x above WHO guideline of 15 μg/m³';
  }

  // ─── Activity Recommendations ──────────────────────────────────────
  List<ActivityRecommendation> get activityRecommendations {
    switch (level) {
      case AqiLevel.good:
        return const [
          ActivityRecommendation(
            name: 'Running',
            emoji: '🏃',
            safe: true,
            note: 'Perfect! Go for a run.',
          ),
          ActivityRecommendation(
            name: 'Cycling',
            emoji: '🚴',
            safe: true,
            note: 'Great day to ride.',
          ),
          ActivityRecommendation(
            name: 'Walking',
            emoji: '🚶',
            safe: true,
            note: 'Enjoy a stroll outdoors.',
          ),
          ActivityRecommendation(
            name: 'Kids Play',
            emoji: '🧒',
            safe: true,
            note: 'Safe for children to play outside.',
          ),
          ActivityRecommendation(
            name: 'Yoga',
            emoji: '🧘',
            safe: true,
            note: 'Perfect for outdoor yoga.',
          ),
        ];
      case AqiLevel.moderate:
        return const [
          ActivityRecommendation(
            name: 'Running',
            emoji: '🏃',
            safe: true,
            note: 'OK for most people.',
          ),
          ActivityRecommendation(
            name: 'Cycling',
            emoji: '🚴',
            safe: true,
            note: 'OK but sensitive groups take care.',
          ),
          ActivityRecommendation(
            name: 'Walking',
            emoji: '🚶',
            safe: true,
            note: 'Fine for short walks.',
          ),
          ActivityRecommendation(
            name: 'Kids Play',
            emoji: '🧒',
            safe: false,
            note: 'Limit prolonged outdoor play.',
          ),
          ActivityRecommendation(
            name: 'Yoga',
            emoji: '🧘',
            safe: true,
            note: 'Better indoors.',
          ),
        ];
      case AqiLevel.unhealthySensitive:
        return const [
          ActivityRecommendation(
            name: 'Running',
            emoji: '🏃',
            safe: false,
            note: 'Not recommended.',
          ),
          ActivityRecommendation(
            name: 'Cycling',
            emoji: '🚴',
            safe: false,
            note: 'Avoid. Wear N95 if necessary.',
          ),
          ActivityRecommendation(
            name: 'Walking',
            emoji: '🚶',
            safe: false,
            note: 'Limit to 15 min. Wear mask.',
          ),
          ActivityRecommendation(
            name: 'Kids Play',
            emoji: '🧒',
            safe: false,
            note: 'Keep children indoors.',
          ),
          ActivityRecommendation(
            name: 'Yoga',
            emoji: '🧘',
            safe: false,
            note: 'Practice indoors.',
          ),
        ];
      case AqiLevel.unhealthy:
        return const [
          ActivityRecommendation(
            name: 'Running',
            emoji: '🏃',
            safe: false,
            note: 'Avoid completely.',
          ),
          ActivityRecommendation(
            name: 'Cycling',
            emoji: '🚴',
            safe: false,
            note: 'Do not cycle outdoors.',
          ),
          ActivityRecommendation(
            name: 'Walking',
            emoji: '🚶',
            safe: false,
            note: 'Only essential outings.',
          ),
          ActivityRecommendation(
            name: 'Kids Play',
            emoji: '🧒',
            safe: false,
            note: 'Keep children indoors.',
          ),
          ActivityRecommendation(
            name: 'Yoga',
            emoji: '🧘',
            safe: false,
            note: 'Definitely indoors.',
          ),
        ];
      case AqiLevel.veryUnhealthy:
        return const [
          ActivityRecommendation(
            name: 'Running',
            emoji: '🏃',
            safe: false,
            note: 'Stay indoors!',
          ),
          ActivityRecommendation(
            name: 'Cycling',
            emoji: '🚴',
            safe: false,
            note: 'Stay indoors!',
          ),
          ActivityRecommendation(
            name: 'Walking',
            emoji: '🚶',
            safe: false,
            note: 'Do not go outside.',
          ),
          ActivityRecommendation(
            name: 'Kids Play',
            emoji: '🧒',
            safe: false,
            note: 'Do not let children outside.',
          ),
          ActivityRecommendation(
            name: 'Yoga',
            emoji: '🧘',
            safe: false,
            note: 'Stay inside with purifier.',
          ),
        ];
      case AqiLevel.hazardous:
        return const [
          ActivityRecommendation(
            name: 'Running',
            emoji: '🏃',
            safe: false,
            note: 'Health emergency!',
          ),
          ActivityRecommendation(
            name: 'Cycling',
            emoji: '🚴',
            safe: false,
            note: 'Health emergency!',
          ),
          ActivityRecommendation(
            name: 'Walking',
            emoji: '🚶',
            safe: false,
            note: 'Do not leave home.',
          ),
          ActivityRecommendation(
            name: 'Kids Play',
            emoji: '🧒',
            safe: false,
            note: 'Keep everyone indoors.',
          ),
          ActivityRecommendation(
            name: 'Yoga',
            emoji: '🧘',
            safe: false,
            note: 'Stay inside sealed home.',
          ),
        ];
    }
  }

  // ─── Pollutant Health Info ─────────────────────────────────────────
  static String pollutantHealthInfo(String name, double? value) {
    switch (name) {
      case 'PM2.5':
        return 'Fine particles (≤2.5μm) that penetrate deep into lungs and bloodstream.\n'
            'Sources: vehicle exhaust, industrial emissions, burning.\n'
            'Health effects: respiratory issues, heart problems, reduced lung function.\n'
            'Current: ${value?.toStringAsFixed(1) ?? "N/A"} μg/m³';
      case 'PM10':
        return 'Coarse particles (≤10μm) that irritate eyes, nose, and throat.\n'
            'Sources: dust, construction, agriculture, road traffic.\n'
            'Health effects: coughing, wheezing, aggravated asthma.\n'
            'Current: ${value?.toStringAsFixed(1) ?? "N/A"} μg/m³';
      case 'O₃':
        return 'Ground-level ozone — a key component of smog.\n'
            'Sources: chemical reactions between NOx and VOCs in sunlight.\n'
            'Health effects: throat irritation, reduced lung function, asthma aggravation.\n'
            'Current: ${value?.toStringAsFixed(1) ?? "N/A"} ppb';
      case 'NO₂':
        return 'Nitrogen dioxide — a reddish-brown toxic gas.\n'
            'Sources: traffic emissions, power plants, industrial burning.\n'
            'Health effects: airway inflammation, increased asthma risk.\n'
            'Current: ${value?.toStringAsFixed(1) ?? "N/A"} ppb';
      case 'SO₂':
        return 'Sulfur dioxide — a colorless gas with sharp odor.\n'
            'Sources: burning fossil fuels (coal, oil), industrial processes.\n'
            'Health effects: breathing difficulty, throat irritation.\n'
            'Current: ${value?.toStringAsFixed(1) ?? "N/A"} ppb';
      case 'CO':
        return 'Carbon monoxide — a colorless, odorless gas.\n'
            'Sources: incomplete burning of fuels, vehicle emissions.\n'
            'Health effects: headaches, dizziness, reduced oxygen delivery.\n'
            'Current: ${value?.toStringAsFixed(1) ?? "N/A"} ppb';
      default:
        return 'No information available.';
    }
  }
}
