import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/iss_now.dart';

class IssService {
  static const String _baseUrl = 'http://api.open-notify.org/iss-now.json';

  Future<IssNow> fetchIssPosition() async {
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == 200) {
      return IssNow.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load ISS position: ${response.statusCode}');
    }
  }
}
