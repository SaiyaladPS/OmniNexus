import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/currency_rates.dart';

class CurrencyService {
  static const _baseUrl = 'https://open.er-api.com/v6/latest';

  Future<ExchangeRates> fetchRates(String base) async {
    try {
      final uri = Uri.parse('$_baseUrl/$base');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['result'] == 'success') {
          return ExchangeRates.fromJson(body);
        }
      }
    } catch (_) {}

    return _mockRates(base);
  }

  ExchangeRates _mockRates(String base) {
    final now = DateTime.now();
    switch (base) {
      case 'USD':
        return ExchangeRates(
          baseCode: 'USD',
          lastUpdated: now,
          rates: {
            'USD': 1.0, 'EUR': 0.92, 'GBP': 0.79, 'JPY': 149.5,
            'THB': 35.12, 'AUD': 1.53, 'CAD': 1.37, 'CHF': 0.88,
            'CNY': 7.24, 'HKD': 7.82, 'SGD': 1.34, 'INR': 83.1,
            'KRW': 1320.0, 'MXN': 17.15, 'BRL': 5.05, 'ZAR': 18.7,
            'SEK': 10.45, 'NOK': 10.67, 'DKK': 6.88, 'NZD': 1.65,
            'MYR': 4.68, 'PHP': 56.2, 'IDR': 15600.0, 'VND': 24800.0,
            'AED': 3.67, 'SAR': 3.75, 'KWD': 0.31, 'QAR': 3.64,
            'TRY': 32.1, 'RUB': 92.5, 'PLN': 3.95, 'CZK': 22.8,
            'HUF': 362.0, 'ILS': 3.72, 'CLP': 935.0, 'COP': 3950.0,
            'PEN': 3.72, 'ARS': 875.0, 'EGP': 47.5, 'NGN': 1480.0,
          },
        );
      default:
        return ExchangeRates(baseCode: base, lastUpdated: now, rates: {base: 1.0});
    }
  }
}

final currencyService = CurrencyService();
