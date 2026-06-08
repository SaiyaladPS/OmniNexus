import 'dart:math' as math;

class Earthquake {
  final String id;
  final double magnitude;
  final String place;
  final DateTime time;
  final double latitude;
  final double longitude;
  final double depth;
  final int? tsunami;
  final String? alert;
  final String? url;
  final String title;

  const Earthquake({
    required this.id,
    required this.magnitude,
    required this.place,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.depth,
    this.tsunami,
    this.alert,
    this.url,
    required this.title,
  });

  String get magFormatted => magnitude.toStringAsFixed(1);

  bool get isSevere => magnitude >= 5.0;
  bool get isModerate => magnitude >= 4.0 && magnitude < 5.0;
  bool get isMinor => magnitude < 4.0;
  bool get hasTsunami => tsunami == 1;

  String get timeFormatted {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.month}/${time.day}/${time.year}';
  }

  double distanceFrom(double lat, double lng) {
    const R = 6371.0;
    final dLat = _toRad(latitude - lat);
    final dLon = _toRad(longitude - lng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat)) *
            math.cos(_toRad(latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180;

  factory Earthquake.fromGeoJson(Map<String, dynamic> feature) {
    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
    final coords = geometry['coordinates'] as List<dynamic>? ?? [];

    return Earthquake(
      id: feature['id']?.toString() ?? '',
      magnitude: (props['mag'] as num?)?.toDouble() ?? 0,
      place: props['place']?.toString() ?? 'Unknown location',
      time: DateTime.fromMillisecondsSinceEpoch(
          (props['time'] as num?)?.toInt() ?? 0),
      latitude: coords.length > 1 ? (coords[1] as num).toDouble() : 0,
      longitude: coords.isNotEmpty ? (coords[0] as num).toDouble() : 0,
      depth: coords.length > 2 ? (coords[2] as num).toDouble() : 0,
      tsunami: (props['tsunami'] as num?)?.toInt(),
      alert: props['alert']?.toString(),
      url: props['url']?.toString(),
      title: props['title']?.toString() ?? 'M ${props['mag']} - Unknown',
    );
  }
}
