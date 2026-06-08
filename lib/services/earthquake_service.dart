import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/earthquake.dart';

enum TimeRange { hour, day, week }

class EarthquakeService {
  static const _baseUrl =
      'https://earthquake.usgs.gov/fdsnws/event/1/query';

  Future<List<Earthquake>> fetchEarthquakes({
    int limit = 50,
    TimeRange range = TimeRange.day,
    double minMagnitude = 0,
    double? userLat,
    double? userLng,
    bool sortByDistance = false,
  }) async {
    try {
      final now = DateTime.now();
      final start = switch (range) {
        TimeRange.hour => now.subtract(const Duration(hours: 1)),
        TimeRange.day => now.subtract(const Duration(days: 1)),
        TimeRange.week => now.subtract(const Duration(days: 7)),
      };
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'format': 'geojson',
        'starttime': start.toIso8601String().split('.').first,
        'endtime': now.toIso8601String().split('.').first,
        'minmagnitude': minMagnitude.toStringAsFixed(1),
        'orderby': 'magnitude',
        'limit': limit.toString(),
      });
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final features = body['features'] as List<dynamic>? ?? [];
        var quakes = features
            .map((f) => Earthquake.fromGeoJson(f as Map<String, dynamic>))
            .where((e) => e.id.isNotEmpty && e.magnitude >= minMagnitude)
            .toList();
        if (sortByDistance && userLat != null && userLng != null) {
          quakes.sort((a, b) =>
              a.distanceFrom(userLat, userLng)
                  .compareTo(b.distanceFrom(userLat, userLng)));
        }
        return quakes;
      }
    } catch (_) {}

    return _mockByRange(range, minMagnitude, userLat, userLng, sortByDistance);
  }

  List<Earthquake> _mockByRange(TimeRange range, double minMag,
      double? userLat, double? userLng, bool sortByDist) {
    final now = DateTime.now();
    var quakes = List.of(_mockEarthquakes);

    quakes = quakes.where((e) {
      final age = now.difference(e.time);
      final withinRange = switch (range) {
        TimeRange.hour => age.inHours < 1,
        TimeRange.day => age.inDays < 1,
        TimeRange.week => age.inDays < 7,
      };
      return withinRange && e.magnitude >= minMag;
    }).toList();

    if (sortByDist && userLat != null && userLng != null) {
      quakes.sort((a, b) =>
          a.distanceFrom(userLat, userLng)
              .compareTo(b.distanceFrom(userLat, userLng)));
    }

    return quakes;
  }
}

final earthquakeService = EarthquakeService();

final _mockEarthquakes = [
  Earthquake(
    id: 'mock:1',
    magnitude: 6.2,
    place: '120km SE of Tokyo, Japan',
    time: DateTime(2026, 5, 30, 14, 32),
    latitude: 35.2,
    longitude: 140.8,
    depth: 10.0,
    tsunami: 0,
    alert: 'yellow',
    title: 'M 6.2 - 120km SE of Tokyo, Japan',
  ),
  Earthquake(
    id: 'mock:2',
    magnitude: 5.5,
    place: '45km W of Los Angeles, USA',
    time: DateTime(2026, 5, 30, 8, 15),
    latitude: 34.0,
    longitude: -118.5,
    depth: 8.2,
    tsunami: 0,
    alert: null,
    title: 'M 5.5 - 45km W of Los Angeles, USA',
  ),
  Earthquake(
    id: 'mock:3',
    magnitude: 4.8,
    place: '30km N of Bangkok, Thailand',
    time: DateTime(2026, 5, 30, 22, 45),
    latitude: 14.2,
    longitude: 100.6,
    depth: 15.0,
    tsunami: 0,
    alert: null,
    title: 'M 4.8 - 30km N of Bangkok, Thailand',
  ),
  Earthquake(
    id: 'mock:4',
    magnitude: 7.1,
    place: '100km SW of Lima, Peru',
    time: DateTime(2026, 5, 30, 6, 30),
    latitude: -12.5,
    longitude: -77.5,
    depth: 25.0,
    tsunami: 1,
    alert: 'orange',
    title: 'M 7.1 - 100km SW of Lima, Peru',
  ),
  Earthquake(
    id: 'mock:5',
    magnitude: 3.2,
    place: '10km E of San Francisco, USA',
    time: DateTime(2026, 5, 30, 11, 20),
    latitude: 37.8,
    longitude: -122.3,
    depth: 5.0,
    tsunami: 0,
    alert: null,
    title: 'M 3.2 - 10km E of San Francisco, USA',
  ),
  Earthquake(
    id: 'mock:6',
    magnitude: 5.8,
    place: '80km S of Istanbul, Turkey',
    time: DateTime(2026, 5, 30, 3, 10),
    latitude: 40.2,
    longitude: 29.0,
    depth: 12.0,
    tsunami: 0,
    alert: 'yellow',
    title: 'M 5.8 - 80km S of Istanbul, Turkey',
  ),
];
