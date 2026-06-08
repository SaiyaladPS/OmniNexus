import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/air_quality.dart';

class AirQualityService {
  static const String _baseUrl = 'https://api.waqi.info';
  static const String _token = '651e6bc55c4d5fd60d6feb017d756e6af9e0150a';

  Future<AirQualityData> fetchNearby({
    double latitude = 13.75,
    double longitude = 100.52,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/feed/geo:$latitude;$longitude/?token=$_token',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] == 'ok') return AirQualityData.fromJson(json);
      throw Exception(json['data']?.toString() ?? 'API error');
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  Future<AirQualityData> searchByCity(String city) async {
    final encodedCity = Uri.encodeComponent(city);
    final url = Uri.parse('$_baseUrl/feed/$encodedCity/?token=$_token');
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] == 'ok') return AirQualityData.fromJson(json);
      throw Exception(json['data']?.toString() ?? 'City not found');
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  Future<List<StationInfo>> fetchStations({
    double lat = 13.75,
    double lng = 100.52,
    double radiusDeg = 1.0,
  }) async {
    final lat1 = lat - radiusDeg;
    final lng1 = lng - radiusDeg;
    final lat2 = lat + radiusDeg;
    final lng2 = lng + radiusDeg;
    final url = Uri.parse(
      '$_baseUrl/v2/map/bounds/?latlng=$lat1,$lng1,$lat2,$lng2&token=$_token',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] == 'ok') {
        final data = json['data'] as List? ?? [];
        return data
            .map((e) => StationInfo.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }
}
