class ExchangeRates {
  final String baseCode;
  final Map<String, double> rates;
  final DateTime lastUpdated;

  const ExchangeRates({
    required this.baseCode,
    required this.rates,
    required this.lastUpdated,
  });

  double? getRate(String code) => rates[code];

  double convert(double amount, String from, String to) {
    final fromRate = rates[from];
    final toRate = rates[to];
    if (fromRate == null || toRate == null) return 0;
    if (from == baseCode) return amount * toRate;
    if (to == baseCode) return amount / fromRate;
    return amount / fromRate * toRate;
  }

  factory ExchangeRates.fromJson(Map<String, dynamic> json) {
    final rawRates = json['rates'] as Map<String, dynamic>? ?? {};
    final rates = <String, double>{};
    for (final entry in rawRates.entries) {
      final v = entry.value;
      if (v is num) rates[entry.key] = v.toDouble();
    }

    final timeStr = json['time_last_update_utc']?.toString() ?? '';
    return ExchangeRates(
      baseCode: json['base_code']?.toString() ?? 'USD',
      rates: rates,
      lastUpdated: DateTime.tryParse(timeStr) ?? DateTime.now(),
    );
  }
}

class CurrencyRecord {
  final String from;
  final String to;
  final double amount;
  final double result;
  final DateTime timestamp;

  const CurrencyRecord({
    required this.from,
    required this.to,
    required this.amount,
    required this.result,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'amount': amount,
        'result': result,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CurrencyRecord.fromJson(Map<String, dynamic> json) {
    return CurrencyRecord(
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      result: (json['result'] as num?)?.toDouble() ?? 0,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

const commonCurrencies = [
  'USD', 'EUR', 'GBP', 'JPY', 'THB', 'AUD', 'CAD', 'CHF', 'CNY', 'HKD',
  'SGD', 'INR', 'KRW', 'MXN', 'BRL', 'ZAR', 'SEK', 'NOK', 'DKK', 'NZD',
  'MYR', 'PHP', 'IDR', 'VND', 'AED', 'SAR', 'KWD', 'QAR', 'TRY', 'RUB',
  'PLN', 'CZK', 'HUF', 'ILS', 'CLP', 'COP', 'PEN', 'ARS', 'EGP', 'NGN',
];

const currencyNames = {
  'USD': 'US Dollar',
  'EUR': 'Euro',
  'GBP': 'British Pound',
  'JPY': 'Japanese Yen',
  'THB': 'Thai Baht',
  'AUD': 'Australian Dollar',
  'CAD': 'Canadian Dollar',
  'CHF': 'Swiss Franc',
  'CNY': 'Chinese Yuan',
  'HKD': 'Hong Kong Dollar',
  'SGD': 'Singapore Dollar',
  'INR': 'Indian Rupee',
  'KRW': 'South Korean Won',
  'MXN': 'Mexican Peso',
  'BRL': 'Brazilian Real',
  'ZAR': 'South African Rand',
  'SEK': 'Swedish Krona',
  'NOK': 'Norwegian Krone',
  'DKK': 'Danish Krone',
  'NZD': 'New Zealand Dollar',
  'MYR': 'Malaysian Ringgit',
  'PHP': 'Philippine Peso',
  'IDR': 'Indonesian Rupiah',
  'VND': 'Vietnamese Dong',
  'AED': 'UAE Dirham',
  'SAR': 'Saudi Riyal',
  'KWD': 'Kuwaiti Dinar',
  'QAR': 'Qatari Riyal',
  'TRY': 'Turkish Lira',
  'RUB': 'Russian Ruble',
  'PLN': 'Polish Zloty',
  'CZK': 'Czech Koruna',
  'HUF': 'Hungarian Forint',
  'ILS': 'Israeli Shekel',
  'CLP': 'Chilean Peso',
  'COP': 'Colombian Peso',
  'PEN': 'Peruvian Sol',
  'ARS': 'Argentine Peso',
  'EGP': 'Egyptian Pound',
  'NGN': 'Nigerian Naira',
};
