class TimezoneInfo {
  final String city;
  final String country;
  final String flag;
  final String utcOffset;
  final int offsetMinutes;
  final double lat;
  final double lng;

  const TimezoneInfo({
    required this.city,
    required this.country,
    required this.flag,
    required this.utcOffset,
    required this.offsetMinutes,
    required this.lat,
    required this.lng,
  });

  DateTime nowInZone() {
    final utc = DateTime.now().toUtc();
    return utc.add(Duration(minutes: offsetMinutes));
  }

  String get timeFormatted {
    final t = nowInZone();
    final hour = t.hour.toString().padLeft(2, '0');
    final min = t.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  String get dateFormatted {
    final t = nowInZone();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[t.month - 1]} ${t.day}, ${t.year}';
  }

  bool get isDaytime {
    final h = nowInZone().hour;
    return h >= 6 && h < 18;
  }
}

class TimezoneService {
  static const List<TimezoneInfo> cities = [
    TimezoneInfo(city: 'London', country: 'United Kingdom', flag: '\u{1F3F4}\u{E0067}\u{E0062}\u{E0065}\u{E006E}\u{E0067}\u{E007F}', utcOffset: 'UTC+0', offsetMinutes: 0, lat: 51.5074, lng: -0.1278),
    TimezoneInfo(city: 'New York', country: 'United States', flag: '\u{1F1FA}\u{1F1F8}', utcOffset: 'UTC-5', offsetMinutes: -300, lat: 40.7128, lng: -74.0060),
    TimezoneInfo(city: 'Los Angeles', country: 'United States', flag: '\u{1F1FA}\u{1F1F8}', utcOffset: 'UTC-8', offsetMinutes: -480, lat: 34.0522, lng: -118.2437),
    TimezoneInfo(city: 'Chicago', country: 'United States', flag: '\u{1F1FA}\u{1F1F8}', utcOffset: 'UTC-6', offsetMinutes: -360, lat: 41.8781, lng: -87.6298),
    TimezoneInfo(city: 'Tokyo', country: 'Japan', flag: '\u{1F1EF}\u{1F1F5}', utcOffset: 'UTC+9', offsetMinutes: 540, lat: 35.6762, lng: 139.6503),
    TimezoneInfo(city: 'Shanghai', country: 'China', flag: '\u{1F1E8}\u{1F1F3}', utcOffset: 'UTC+8', offsetMinutes: 480, lat: 31.2304, lng: 121.4737),
    TimezoneInfo(city: 'Hong Kong', country: 'China', flag: '\u{1F1ED}\u{1F1F0}', utcOffset: 'UTC+8', offsetMinutes: 480, lat: 22.3193, lng: 114.1694),
    TimezoneInfo(city: 'Paris', country: 'France', flag: '\u{1F1EB}\u{1F1F7}', utcOffset: 'UTC+1', offsetMinutes: 60, lat: 48.8566, lng: 2.3522),
    TimezoneInfo(city: 'Berlin', country: 'Germany', flag: '\u{1F1E9}\u{1F1EA}', utcOffset: 'UTC+1', offsetMinutes: 60, lat: 52.5200, lng: 13.4050),
    TimezoneInfo(city: 'Moscow', country: 'Russia', flag: '\u{1F1F7}\u{1F1FA}', utcOffset: 'UTC+3', offsetMinutes: 180, lat: 55.7558, lng: 37.6173),
    TimezoneInfo(city: 'Dubai', country: 'United Arab Emirates', flag: '\u{1F1E6}\u{1F1EA}', utcOffset: 'UTC+4', offsetMinutes: 240, lat: 25.2048, lng: 55.2708),
    TimezoneInfo(city: 'Mumbai', country: 'India', flag: '\u{1F1EE}\u{1F1F3}', utcOffset: 'UTC+5:30', offsetMinutes: 330, lat: 19.0760, lng: 72.8777),
    TimezoneInfo(city: 'Singapore', country: 'Singapore', flag: '\u{1F1F8}\u{1F1EC}', utcOffset: 'UTC+8', offsetMinutes: 480, lat: 1.3521, lng: 103.8198),
    TimezoneInfo(city: 'Sydney', country: 'Australia', flag: '\u{1F1E6}\u{1F1FA}', utcOffset: 'UTC+11', offsetMinutes: 660, lat: -33.8688, lng: 151.2093),
    TimezoneInfo(city: 'Seoul', country: 'South Korea', flag: '\u{1F1F0}\u{1F1F7}', utcOffset: 'UTC+9', offsetMinutes: 540, lat: 37.5665, lng: 126.9780),
    TimezoneInfo(city: 'Bangkok', country: 'Thailand', flag: '\u{1F1F9}\u{1F1ED}', utcOffset: 'UTC+7', offsetMinutes: 420, lat: 13.7563, lng: 100.5018),
    TimezoneInfo(city: 'São Paulo', country: 'Brazil', flag: '\u{1F1E7}\u{1F1F7}', utcOffset: 'UTC-3', offsetMinutes: -180, lat: -23.5505, lng: -46.6333),
    TimezoneInfo(city: 'Toronto', country: 'Canada', flag: '\u{1F1E8}\u{1F1E6}', utcOffset: 'UTC-5', offsetMinutes: -300, lat: 43.6532, lng: -79.3832),
    TimezoneInfo(city: 'Istanbul', country: 'Turkey', flag: '\u{1F1F9}\u{1F1F7}', utcOffset: 'UTC+3', offsetMinutes: 180, lat: 41.0082, lng: 28.9784),
    TimezoneInfo(city: 'Cairo', country: 'Egypt', flag: '\u{1F1EA}\u{1F1EC}', utcOffset: 'UTC+2', offsetMinutes: 120, lat: 30.0444, lng: 31.2357),
    TimezoneInfo(city: 'Jakarta', country: 'Indonesia', flag: '\u{1F1EE}\u{1F1E9}', utcOffset: 'UTC+7', offsetMinutes: 420, lat: -6.2088, lng: 106.8456),
    TimezoneInfo(city: 'Kuala Lumpur', country: 'Malaysia', flag: '\u{1F1F2}\u{1F1FE}', utcOffset: 'UTC+8', offsetMinutes: 480, lat: 3.1390, lng: 101.6869),
    TimezoneInfo(city: 'Manila', country: 'Philippines', flag: '\u{1F1F5}\u{1F1ED}', utcOffset: 'UTC+8', offsetMinutes: 480, lat: 14.5995, lng: 120.9842),
    TimezoneInfo(city: 'Mexico City', country: 'Mexico', flag: '\u{1F1F2}\u{1F1FD}', utcOffset: 'UTC-6', offsetMinutes: -360, lat: 19.4326, lng: -99.1332),
    TimezoneInfo(city: 'Buenos Aires', country: 'Argentina', flag: '\u{1F1E6}\u{1F1F7}', utcOffset: 'UTC-3', offsetMinutes: -180, lat: -34.6037, lng: -58.3816),
    TimezoneInfo(city: 'Rome', country: 'Italy', flag: '\u{1F1EE}\u{1F1F9}', utcOffset: 'UTC+1', offsetMinutes: 60, lat: 41.9028, lng: 12.4964),
    TimezoneInfo(city: 'Madrid', country: 'Spain', flag: '\u{1F1EA}\u{1F1F8}', utcOffset: 'UTC+1', offsetMinutes: 60, lat: 40.4168, lng: -3.7038),
    TimezoneInfo(city: 'Lagos', country: 'Nigeria', flag: '\u{1F1F3}\u{1F1EC}', utcOffset: 'UTC+1', offsetMinutes: 60, lat: 6.5244, lng: 3.3792),
    TimezoneInfo(city: 'Nairobi', country: 'Kenya', flag: '\u{1F1F0}\u{1F1EA}', utcOffset: 'UTC+3', offsetMinutes: 180, lat: -1.2921, lng: 36.8219),
    TimezoneInfo(city: 'Cape Town', country: 'South Africa', flag: '\u{1F1FF}\u{1F1E6}', utcOffset: 'UTC+2', offsetMinutes: 120, lat: -33.9249, lng: 18.4241),
    TimezoneInfo(city: 'Vancouver', country: 'Canada', flag: '\u{1F1E8}\u{1F1E6}', utcOffset: 'UTC-8', offsetMinutes: -480, lat: 49.2827, lng: -123.1207),
    TimezoneInfo(city: 'Auckland', country: 'New Zealand', flag: '\u{1F1F3}\u{1F1FF}', utcOffset: 'UTC+13', offsetMinutes: 780, lat: -36.8485, lng: 174.7633),
    TimezoneInfo(city: 'Amsterdam', country: 'Netherlands', flag: '\u{1F1F3}\u{1F1F1}', utcOffset: 'UTC+1', offsetMinutes: 60, lat: 52.3676, lng: 4.9041),
    TimezoneInfo(city: 'Stockholm', country: 'Sweden', flag: '\u{1F1F8}\u{1F1EA}', utcOffset: 'UTC+1', offsetMinutes: 60, lat: 59.3293, lng: 18.0686),
    TimezoneInfo(city: 'Oslo', country: 'Norway', flag: '\u{1F1F3}\u{1F1F4}', utcOffset: 'UTC+1', offsetMinutes: 60, lat: 59.9139, lng: 10.7522),
    TimezoneInfo(city: 'Zurich', country: 'Switzerland', flag: '\u{1F1E8}\u{1F1ED}', utcOffset: 'UTC+1', offsetMinutes: 60, lat: 47.3769, lng: 8.5417),
    TimezoneInfo(city: 'Vienna', country: 'Austria', flag: '\u{1F1E6}\u{1F1F9}', utcOffset: 'UTC+1', offsetMinutes: 60, lat: 48.2082, lng: 16.3738),
    TimezoneInfo(city: 'Warsaw', country: 'Poland', flag: '\u{1F1F5}\u{1F1F1}', utcOffset: 'UTC+1', offsetMinutes: 60, lat: 52.2297, lng: 21.0122),
    TimezoneInfo(city: 'Prague', country: 'Czech Republic', flag: '\u{1F1E8}\u{1F1FF}', utcOffset: 'UTC+1', offsetMinutes: 60, lat: 50.0755, lng: 14.4378),
    TimezoneInfo(city: 'Athens', country: 'Greece', flag: '\u{1F1EC}\u{1F1F7}', utcOffset: 'UTC+2', offsetMinutes: 120, lat: 37.9838, lng: 23.7275),
    TimezoneInfo(city: 'Lisbon', country: 'Portugal', flag: '\u{1F1F5}\u{1F1F9}', utcOffset: 'UTC+0', offsetMinutes: 0, lat: 38.7223, lng: -9.1393),
    TimezoneInfo(city: 'Helsinki', country: 'Finland', flag: '\u{1F1EB}\u{1F1EE}', utcOffset: 'UTC+2', offsetMinutes: 120, lat: 60.1699, lng: 24.9384),
    TimezoneInfo(city: 'Dublin', country: 'Ireland', flag: '\u{1F1EE}\u{1F1EA}', utcOffset: 'UTC+0', offsetMinutes: 0, lat: 53.3498, lng: -6.2603),
    TimezoneInfo(city: 'Reykjavik', country: 'Iceland', flag: '\u{1F1EE}\u{1F1F8}', utcOffset: 'UTC+0', offsetMinutes: 0, lat: 64.1466, lng: -21.9426),
    TimezoneInfo(city: 'Denver', country: 'United States', flag: '\u{1F1FA}\u{1F1F8}', utcOffset: 'UTC-7', offsetMinutes: -420, lat: 39.7392, lng: -104.9903),
    TimezoneInfo(city: 'Miami', country: 'United States', flag: '\u{1F1FA}\u{1F1F8}', utcOffset: 'UTC-5', offsetMinutes: -300, lat: 25.7617, lng: -80.1918),
    TimezoneInfo(city: 'San Francisco', country: 'United States', flag: '\u{1F1FA}\u{1F1F8}', utcOffset: 'UTC-8', offsetMinutes: -480, lat: 37.7749, lng: -122.4194),
    TimezoneInfo(city: 'Tehran', country: 'Iran', flag: '\u{1F1EE}\u{1F1F7}', utcOffset: 'UTC+3:30', offsetMinutes: 210, lat: 35.6892, lng: 51.3890),
    TimezoneInfo(city: 'Kolkata', country: 'India', flag: '\u{1F1EE}\u{1F1F3}', utcOffset: 'UTC+5:30', offsetMinutes: 330, lat: 22.5726, lng: 88.3639),
    TimezoneInfo(city: 'Karachi', country: 'Pakistan', flag: '\u{1F1F5}\u{1F1F0}', utcOffset: 'UTC+5', offsetMinutes: 300, lat: 24.8607, lng: 67.0011),
    TimezoneInfo(city: 'Dhaka', country: 'Bangladesh', flag: '\u{1F1E7}\u{1F1E9}', utcOffset: 'UTC+6', offsetMinutes: 360, lat: 23.8103, lng: 90.4125),
    TimezoneInfo(city: 'Hanoi', country: 'Vietnam', flag: '\u{1F1FB}\u{1F1F3}', utcOffset: 'UTC+7', offsetMinutes: 420, lat: 21.0278, lng: 105.8342),
    TimezoneInfo(city: 'Riyadh', country: 'Saudi Arabia', flag: '\u{1F1F8}\u{1F1E6}', utcOffset: 'UTC+3', offsetMinutes: 180, lat: 24.7136, lng: 46.6753),
    TimezoneInfo(city: 'Tel Aviv', country: 'Israel', flag: '\u{1F1EE}\u{1F1F1}', utcOffset: 'UTC+2', offsetMinutes: 120, lat: 32.0853, lng: 34.7818),
    TimezoneInfo(city: 'Lima', country: 'Peru', flag: '\u{1F1F5}\u{1F1EA}', utcOffset: 'UTC-5', offsetMinutes: -300, lat: -12.0464, lng: -77.0428),
    TimezoneInfo(city: 'Santiago', country: 'Chile', flag: '\u{1F1E8}\u{1F1F1}', utcOffset: 'UTC-3', offsetMinutes: -180, lat: -33.4489, lng: -70.6693),
    TimezoneInfo(city: 'Bogotá', country: 'Colombia', flag: '\u{1F1E8}\u{1F1F4}', utcOffset: 'UTC-5', offsetMinutes: -300, lat: 4.7110, lng: -74.0721),
    TimezoneInfo(city: 'Kinshasa', country: 'DR Congo', flag: '\u{1F1E8}\u{1F1E9}', utcOffset: 'UTC+1', offsetMinutes: 60, lat: -4.4419, lng: 15.2663),
    TimezoneInfo(city: 'Casablanca', country: 'Morocco', flag: '\u{1F1F2}\u{1F1E6}', utcOffset: 'UTC+0', offsetMinutes: 0, lat: 33.5731, lng: -7.5898),
    TimezoneInfo(city: 'Anchorage', country: 'United States', flag: '\u{1F1FA}\u{1F1F8}', utcOffset: 'UTC-9', offsetMinutes: -540, lat: 61.2181, lng: -149.9003),
    TimezoneInfo(city: 'Honolulu', country: 'United States', flag: '\u{1F1FA}\u{1F1F8}', utcOffset: 'UTC-10', offsetMinutes: -600, lat: 21.3069, lng: -157.8583),
    TimezoneInfo(city: 'Nuuk', country: 'Greenland', flag: '\u{1F1EC}\u{1F1F1}', utcOffset: 'UTC-3', offsetMinutes: -180, lat: 64.1814, lng: -51.6941),
    TimezoneInfo(city: 'Kathmandu', country: 'Nepal', flag: '\u{1F1F3}\u{1F1F5}', utcOffset: 'UTC+5:45', offsetMinutes: 345, lat: 27.7172, lng: 85.3240),
    TimezoneInfo(city: 'Yangon', country: 'Myanmar', flag: '\u{1F1F2}\u{1F1F2}', utcOffset: 'UTC+6:30', offsetMinutes: 390, lat: 16.8404, lng: 96.1735),
    TimezoneInfo(city: 'Perth', country: 'Australia', flag: '\u{1F1E6}\u{1F1FA}', utcOffset: 'UTC+8', offsetMinutes: 480, lat: -31.9505, lng: 115.8605),
    TimezoneInfo(city: 'Adelaide', country: 'Australia', flag: '\u{1F1E6}\u{1F1FA}', utcOffset: 'UTC+10:30', offsetMinutes: 630, lat: -34.9285, lng: 138.6007),
    TimezoneInfo(city: 'Brisbane', country: 'Australia', flag: '\u{1F1E6}\u{1F1FA}', utcOffset: 'UTC+10', offsetMinutes: 600, lat: -27.4698, lng: 153.0251),
    TimezoneInfo(city: 'Ulaanbaatar', country: 'Mongolia', flag: '\u{1F1F2}\u{1F1F3}', utcOffset: 'UTC+8', offsetMinutes: 480, lat: 47.8864, lng: 106.9057),
    TimezoneInfo(city: 'Tashkent', country: 'Uzbekistan', flag: '\u{1F1FA}\u{1F1FF}', utcOffset: 'UTC+5', offsetMinutes: 300, lat: 41.2995, lng: 69.2401),
    TimezoneInfo(city: 'Beirut', country: 'Lebanon', flag: '\u{1F1F1}\u{1F1E7}', utcOffset: 'UTC+2', offsetMinutes: 120, lat: 33.8938, lng: 35.5018),
    TimezoneInfo(city: 'Baghdad', country: 'Iraq', flag: '\u{1F1EE}\u{1F1F6}', utcOffset: 'UTC+3', offsetMinutes: 180, lat: 33.3152, lng: 44.3661),
    TimezoneInfo(city: 'Kabul', country: 'Afghanistan', flag: '\u{1F1E6}\u{1F1EB}', utcOffset: 'UTC+4:30', offsetMinutes: 270, lat: 34.5553, lng: 69.2075),
    TimezoneInfo(city: 'Caracas', country: 'Venezuela', flag: '\u{1F1FB}\u{1F1EA}', utcOffset: 'UTC-4', offsetMinutes: -240, lat: 10.4806, lng: -66.9036),
    TimezoneInfo(city: 'Panama City', country: 'Panama', flag: '\u{1F1F5}\u{1F1E6}', utcOffset: 'UTC-5', offsetMinutes: -300, lat: 8.9824, lng: -79.5199),
    TimezoneInfo(city: 'San Juan', country: 'Puerto Rico', flag: '\u{1F1F5}\u{1F1F7}', utcOffset: 'UTC-4', offsetMinutes: -240, lat: 18.4655, lng: -66.1057),
    TimezoneInfo(city: 'Montevideo', country: 'Uruguay', flag: '\u{1F1FA}\u{1F1FE}', utcOffset: 'UTC-3', offsetMinutes: -180, lat: -34.9011, lng: -56.1645),
  ];

  static List<TimezoneInfo> search(String query) {
    final q = query.toLowerCase();
    return cities.where((c) =>
      c.city.toLowerCase().contains(q) ||
      c.country.toLowerCase().contains(q)
    ).toList();
  }

  static int timeDifferenceMinutes(TimezoneInfo a, TimezoneInfo b) {
    return a.offsetMinutes - b.offsetMinutes;
  }

  static String formatTimeDifference(int diffMinutes) {
    if (diffMinutes == 0) return 'Same time';
    final abs = diffMinutes.abs();
    final hours = abs ~/ 60;
    final mins = abs % 60;
    final sign = diffMinutes > 0 ? 'ahead' : 'behind';
    if (hours > 0 && mins > 0) return '$hours h $mins m $sign';
    if (hours > 0) return '$hours h $sign';
    return '$mins m $sign';
  }
}
