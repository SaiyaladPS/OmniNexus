class GlobalDiseaseStats {
  final int cases;
  final int todayCases;
  final int deaths;
  final int todayDeaths;
  final int recovered;
  final int active;
  final int critical;
  final int tests;
  final int population;
  final int affectedCountries;
  final DateTime? updated;

  const GlobalDiseaseStats({
    required this.cases,
    required this.todayCases,
    required this.deaths,
    required this.todayDeaths,
    required this.recovered,
    required this.active,
    required this.critical,
    required this.tests,
    required this.population,
    required this.affectedCountries,
    this.updated,
  });

  factory GlobalDiseaseStats.fromJson(Map<String, dynamic> json) {
    return GlobalDiseaseStats(
      cases: _intVal(json['cases']),
      todayCases: _intVal(json['todayCases']),
      deaths: _intVal(json['deaths']),
      todayDeaths: _intVal(json['todayDeaths']),
      recovered: _intVal(json['recovered']),
      active: _intVal(json['active']),
      critical: _intVal(json['critical']),
      tests: _intVal(json['tests']),
      population: _intVal(json['population']),
      affectedCountries: _intVal(json['affectedCountries']),
      updated: _dateFromMillis(json['updated']),
    );
  }

  double get caseFatalityRate => cases == 0 ? 0 : deaths / cases * 100;
  double get recoveryRate => cases == 0 ? 0 : recovered / cases * 100;
  double get activePerMillion =>
      population == 0 ? 0 : active / population * 1000000;
}

class CountryDiseaseStats {
  final String country;
  final String iso2;
  final String continent;
  final String flagUrl;
  final double latitude;
  final double longitude;
  final int cases;
  final int todayCases;
  final int deaths;
  final int todayDeaths;
  final int recovered;
  final int active;
  final int critical;
  final int tests;
  final int population;
  final double activePerOneMillion;
  final double casesPerOneMillion;
  final double deathsPerOneMillion;
  final DateTime? updated;
  final int vaccineDoses;

  const CountryDiseaseStats({
    required this.country,
    required this.iso2,
    required this.continent,
    required this.flagUrl,
    required this.latitude,
    required this.longitude,
    required this.cases,
    required this.todayCases,
    required this.deaths,
    required this.todayDeaths,
    required this.recovered,
    required this.active,
    required this.critical,
    required this.tests,
    required this.population,
    required this.activePerOneMillion,
    required this.casesPerOneMillion,
    required this.deathsPerOneMillion,
    this.updated,
    this.vaccineDoses = 0,
  });

  factory CountryDiseaseStats.fromJson(Map<String, dynamic> json) {
    final info = json['countryInfo'] as Map<String, dynamic>? ?? {};
    return CountryDiseaseStats(
      country: json['country']?.toString() ?? 'Unknown',
      iso2: info['iso2']?.toString() ?? '',
      continent: json['continent']?.toString() ?? 'Unknown',
      flagUrl: info['flag']?.toString() ?? '',
      latitude: _doubleVal(info['lat']),
      longitude: _doubleVal(info['long']),
      cases: _intVal(json['cases']),
      todayCases: _intVal(json['todayCases']),
      deaths: _intVal(json['deaths']),
      todayDeaths: _intVal(json['todayDeaths']),
      recovered: _intVal(json['recovered']),
      active: _intVal(json['active']),
      critical: _intVal(json['critical']),
      tests: _intVal(json['tests']),
      population: _intVal(json['population']),
      activePerOneMillion: _doubleVal(json['activePerOneMillion']),
      casesPerOneMillion: _doubleVal(json['casesPerOneMillion']),
      deathsPerOneMillion: _doubleVal(json['deathsPerOneMillion']),
      updated: _dateFromMillis(json['updated']),
    );
  }

  CountryDiseaseStats copyWith({int? vaccineDoses}) {
    return CountryDiseaseStats(
      country: country,
      iso2: iso2,
      continent: continent,
      flagUrl: flagUrl,
      latitude: latitude,
      longitude: longitude,
      cases: cases,
      todayCases: todayCases,
      deaths: deaths,
      todayDeaths: todayDeaths,
      recovered: recovered,
      active: active,
      critical: critical,
      tests: tests,
      population: population,
      activePerOneMillion: activePerOneMillion,
      casesPerOneMillion: casesPerOneMillion,
      deathsPerOneMillion: deathsPerOneMillion,
      updated: updated,
      vaccineDoses: vaccineDoses ?? this.vaccineDoses,
    );
  }

  double get todayCasesPerMillion =>
      population == 0 ? 0 : todayCases / population * 1000000;

  double get vaccineDosesPer100 =>
      population == 0 ? 0 : vaccineDoses / population * 100;

  TravelRiskLevel get travelRisk {
    if (todayCasesPerMillion >= 50 ||
        activePerOneMillion >= 2000 ||
        todayDeaths > 100) {
      return TravelRiskLevel.high;
    }
    if (todayCasesPerMillion >= 10 ||
        activePerOneMillion >= 500 ||
        todayDeaths > 10) {
      return TravelRiskLevel.moderate;
    }
    return TravelRiskLevel.low;
  }

  String get travelSummary {
    switch (travelRisk) {
      case TravelRiskLevel.low:
        return 'Low current COVID-19 signal. Keep routine hygiene, travel insurance, and destination entry checks.';
      case TravelRiskLevel.moderate:
        return 'Moderate outbreak signal. Consider masks in crowded indoor areas and avoid travel if symptomatic.';
      case TravelRiskLevel.high:
        return 'High outbreak signal. Review travel plans, use high-quality masks, and monitor official health advisories.';
    }
  }
}

enum TravelRiskLevel { low, moderate, high }

extension TravelRiskLevelX on TravelRiskLevel {
  String get label {
    switch (this) {
      case TravelRiskLevel.low:
        return 'Low Watch';
      case TravelRiskLevel.moderate:
        return 'Moderate Watch';
      case TravelRiskLevel.high:
        return 'High Alert';
    }
  }
}

class DiseaseDashboardData {
  final GlobalDiseaseStats global;
  final List<CountryDiseaseStats> countries;
  final DateTime fetchedAt;

  const DiseaseDashboardData({
    required this.global,
    required this.countries,
    required this.fetchedAt,
  });

  int get totalVaccineDoses =>
      countries.fold(0, (sum, c) => sum + c.vaccineDoses);

  List<CountryDiseaseStats> get topActiveCountries {
    final sorted = [...countries]..sort((a, b) => b.active.compareTo(a.active));
    return sorted.take(8).toList();
  }

  List<CountryDiseaseStats> get highRiskCountries =>
      countries.where((c) => c.travelRisk == TravelRiskLevel.high).toList();
}

int _intVal(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _doubleVal(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _dateFromMillis(dynamic value) {
  final millis = _intVal(value);
  if (millis == 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(millis);
}
