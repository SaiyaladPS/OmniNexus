import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/disease_tracker.dart';

class DiseaseTrackerService {
  static const _baseUrl = 'https://disease.sh/v3/covid-19';

  Future<DiseaseDashboardData> fetchDashboard() async {
    final coreResponses = await Future.wait([
      _getJson('$_baseUrl/all'),
      _getJson('$_baseUrl/countries?sort=active'),
    ]);
    final vaccinePayload = await _tryGetJson(
      '$_baseUrl/vaccine/coverage/countries?lastdays=1',
    );

    final global = GlobalDiseaseStats.fromJson(
      coreResponses[0] as Map<String, dynamic>,
    );
    final vaccineByCountry = _parseVaccineCoverage(vaccinePayload);
    final countries = (coreResponses[1] as List)
        .whereType<Map<String, dynamic>>()
        .map((json) {
          final country = CountryDiseaseStats.fromJson(json);
          return country.copyWith(
            vaccineDoses: vaccineByCountry[country.country] ?? 0,
          );
        })
        .toList();

    return DiseaseDashboardData(
      global: global,
      countries: countries,
      fetchedAt: DateTime.now(),
    );
  }

  Future<dynamic> _getJson(String url) async {
    final response = await http
        .get(Uri.parse(url), headers: {'accept': 'application/json'})
        .timeout(const Duration(seconds: 18));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Disease API HTTP ${response.statusCode}');
  }

  Future<dynamic> _tryGetJson(String url) async {
    try {
      return await _getJson(url);
    } catch (_) {
      return null;
    }
  }

  Map<String, int> _parseVaccineCoverage(dynamic payload) {
    if (payload is! List) return {};
    final result = <String, int>{};
    for (final item in payload) {
      if (item is! Map<String, dynamic>) continue;
      final country = item['country']?.toString();
      final timeline = item['timeline'];
      if (country == null || timeline is! Map) continue;
      if (timeline.isEmpty) continue;
      final latestValue = timeline.values.last;
      if (latestValue is num) result[country] = latestValue.toInt();
    }
    return result;
  }
}
