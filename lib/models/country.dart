class Country {
  final String name;
  final String officialName;
  final String cca2;
  final String cca3;
  final String flagPng;
  final String? flagEmoji;
  final List<String> capital;
  final String region;
  final String? subregion;
  final Map<String, String> languages;
  final Map<String, CurrencyInfo> currencies;
  final double area;
  final int population;
  final List<String> timezones;
  final List<String> borders;
  final List<double> latlng;
  final bool landlocked;
  final bool unMember;
  final String? googleMapsUrl;
  final String? openStreetMapsUrl;
  final String? callingCode;
  final String? carSide;
  final List<String> continents;

  const Country({
    required this.name,
    required this.officialName,
    required this.cca2,
    required this.cca3,
    required this.flagPng,
    this.flagEmoji,
    required this.capital,
    required this.region,
    this.subregion,
    required this.languages,
    required this.currencies,
    required this.area,
    required this.population,
    required this.timezones,
    required this.borders,
    required this.latlng,
    required this.landlocked,
    required this.unMember,
    this.googleMapsUrl,
    this.openStreetMapsUrl,
    this.callingCode,
    this.carSide,
    required this.continents,
  });

  String get capitalText => capital.isNotEmpty ? capital.join(', ') : 'N/A';
  String get languageList =>
      languages.values.isEmpty ? 'N/A' : languages.values.join(', ');
  String get currencyList => currencies.values.isEmpty
      ? 'N/A'
      : currencies.entries
          .map((e) => '${e.value.symbol} ${e.value.name} (${e.key})')
          .join(', ');
  String get timezoneList => timezones.join(', ');
  String get continentList => continents.join(', ');
  String get borderList => borders.isEmpty ? 'None' : borders.join(', ');
  String get populationFormatted => _formatNumber(population);
  String get areaFormatted => '${_formatNumber(area.toInt())} km²';
  String get densityFormatted =>
      area > 0 ? '${_formatNumber((population / area).round())}/km²' : 'N/A';

  static String _formatNumber(int n) {
    if (n < 1000) return n.toString();
    if (n < 1000000) return '${(n / 1000).toStringAsFixed(1)}k';
    if (n < 1000000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    return '${(n / 1000000000).toStringAsFixed(1)}B';
  }

  factory Country.fromJson(Map<String, dynamic> json) {
    final nameData = json['name'] as Map<String, dynamic>? ?? {};
    final currenciesData = json['currencies'] as Map<String, dynamic>? ?? {};
    final languagesData = json['languages'] as Map<String, dynamic>? ?? {};
    final flagsData = json['flags'] as Map<String, dynamic>? ?? {};
    final mapsData = json['maps'] as Map<String, dynamic>? ?? {};
    final iddData = json['idd'] as Map<String, dynamic>? ?? {};
    final carData = json['car'] as Map<String, dynamic>? ?? {};

    final currencies = <String, CurrencyInfo>{};
    for (final entry in currenciesData.entries) {
      final val = entry.value as Map<String, dynamic>?;
      if (val != null) {
        currencies[entry.key] = CurrencyInfo(
          name: val['name']?.toString() ?? entry.key,
          symbol: val['symbol']?.toString() ?? '',
        );
      }
    }

    final languages = <String, String>{};
    for (final entry in languagesData.entries) {
      languages[entry.key] = entry.value?.toString() ?? '';
    }

    final root = iddData['root']?.toString() ?? '';
    final suffixes = iddData['suffixes'] as List<dynamic>?;
    final callingCode = root.isNotEmpty && suffixes != null && suffixes.isNotEmpty
        ? '$root${suffixes[0]}'
        : null;

    return Country(
      name: nameData['common']?.toString() ?? 'Unknown',
      officialName: nameData['official']?.toString() ?? '',
      cca2: json['cca2']?.toString() ?? '',
      cca3: json['cca3']?.toString() ?? '',
      flagPng: flagsData['png']?.toString() ?? '',
      flagEmoji: json['flag']?.toString(),
      capital: (json['capital'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      region: json['region']?.toString() ?? 'Unknown',
      subregion: json['subregion']?.toString(),
      languages: languages,
      currencies: currencies,
      area: (json['area'] as num?)?.toDouble() ?? 0,
      population: (json['population'] as num?)?.toInt() ?? 0,
      timezones: (json['timezones'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      borders: (json['borders'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      latlng: (json['latlng'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      landlocked: json['landlocked'] == true,
      unMember: json['unMember'] == true,
      googleMapsUrl: mapsData['googleMaps']?.toString(),
      openStreetMapsUrl: mapsData['openStreetMaps']?.toString(),
      callingCode: callingCode,
      carSide: carData['side']?.toString(),
      continents: (json['continents'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': {'common': name, 'official': officialName},
        'cca2': cca2,
        'cca3': cca3,
        'flags': {'png': flagPng},
        'flag': flagEmoji,
        'capital': capital,
        'region': region,
        'subregion': subregion,
        'languages': languages,
        'currencies': currencies.map((k, v) => MapEntry(k, v.toJson())),
        'area': area,
        'population': population,
        'timezones': timezones,
        'borders': borders,
        'latlng': latlng,
        'landlocked': landlocked,
        'unMember': unMember,
        'maps': {
          if (googleMapsUrl != null) 'googleMaps': googleMapsUrl,
          if (openStreetMapsUrl != null) 'openStreetMaps': openStreetMapsUrl,
        },
        'callingCode': callingCode,
        'carSide': carSide,
        'continents': continents,
      };
}

class CurrencyInfo {
  final String name;
  final String symbol;

  const CurrencyInfo({required this.name, required this.symbol});

  Map<String, dynamic> toJson() => {'name': name, 'symbol': symbol};
}
