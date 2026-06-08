import '../models/iss_now.dart';
import '../models/weather.dart';
import '../models/earthquake.dart';
import '../models/portfolio.dart';
import 'iss_service.dart';
import 'weather_service.dart';
import 'earthquake_service.dart';
import 'portfolio_service.dart';

class GlobalStatsData {
  final IssNow? iss;
  final WeatherData? weather;
  final List<StockData> stocks;
  final List<Earthquake> earthquakes;
  final DateTime updatedAt;

  GlobalStatsData({
    this.iss,
    this.weather,
    required this.stocks,
    required this.earthquakes,
    required this.updatedAt,
  });

  int get quakeCount => earthquakes.length;
  double get maxQuakeMag => earthquakes.isEmpty ? 0 : earthquakes.map((e) => e.magnitude).reduce((a, b) => a > b ? a : b);
  double get avgTemp => weather?.current?.temperature ?? 0;
  int get stockCount => stocks.length;
  int get stockGainers => stocks.where((s) => s.isPositive).length;
  int get stockLosers => stocks.where((s) => !s.isPositive).length;
  String get issLocation => iss != null ? '${iss!.position.latitude.toStringAsFixed(2)}°, ${iss!.position.longitude.toStringAsFixed(2)}°' : 'N/A';

  int get minorQuakes => earthquakes.where((e) => e.isMinor).length;
  int get moderateQuakes => earthquakes.where((e) => e.isModerate).length;
  int get severeQuakes => earthquakes.where((e) => e.isSevere).length;
}

class GlobalStatsService {
  final _issService = IssService();
  final _weatherService = WeatherService();
  final _quakeService = EarthquakeService();
  final _portfolioService = PortfolioService();

  static const _watchSymbols = ['AAPL', 'TSLA', 'MSFT', 'GOOGL', 'AMZN'];

  Future<GlobalStatsData> fetchAll({
    double lat = 13.736717,
    double lng = 100.523186,
  }) async {
    final results = await Future.wait([
      _issService.fetchIssPosition(),
      _weatherService.fetchWeather(latitude: lat, longitude: lng),
      _fetchStocks(),
      _quakeService.fetchEarthquakes(
        range: TimeRange.day,
        minMagnitude: 2.5,
        limit: 30,
      ),
    ], eagerError: false);

    return GlobalStatsData(
      iss: results[0] as IssNow?,
      weather: results[1] as WeatherData?,
      stocks: results[2] as List<StockData>,
      earthquakes: results[3] as List<Earthquake>,
      updatedAt: DateTime.now(),
    );
  }

  Future<List<StockData>> _fetchStocks() async {
    final results = await Future.wait(
      _watchSymbols.map((s) => _portfolioService.fetchStock(s)),
      eagerError: false,
    );
    return results.whereType<StockData>().toList();
  }
}
