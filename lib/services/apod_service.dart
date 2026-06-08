import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/apod.dart';

class ApodService {
  static const String _baseUrl = 'https://api.nasa.gov/planetary/apod';
  static const String _apiKey = '0LWrihyPLP3ZYGUBVxGWmFPPH9Vikt71iTvizOIK';

  Future<Apod> fetchApod() async {
    final uri = Uri.parse('$_baseUrl?api_key=$_apiKey');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return Apod.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load APOD data: ${response.statusCode}');
    }
  }
}
