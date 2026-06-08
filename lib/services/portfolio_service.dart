import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/portfolio.dart';
import 'notification_service.dart';

class PortfolioService {
  Future<StockData?> fetchStock(String symbol) async {
    try {
      final uri = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?range=1mo&interval=1d');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final result = (body['chart']?['result'] as List?)?.firstOrNull as Map<String, dynamic>?;
        if (result == null) return null;

        final meta = result['meta'] as Map<String, dynamic>? ?? {};
        final indicators = result['indicators'] as Map<String, dynamic>? ?? {};
        final quotes = (indicators['quote'] as List?) ?? [];
        final quote = quotes.isNotEmpty ? quotes[0] as Map<String, dynamic>? : null;
        final closes = (quote?['close'] as List?)?.cast<num?>() ?? [];

        final price = (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0;
        final prevClose = (meta['previousClose'] as num?)?.toDouble() ?? price;
        final change = price - prevClose;
        final changePercent = prevClose > 0 ? (change / prevClose) * 100 : 0.0;

        final sparkline = closes.where((c) => c != null).map((c) => c!.toDouble()).toList();

        String name = meta['shortName']?.toString() ?? symbol;
        if (name.length > 30) {
          name = meta['longName']?.toString() ?? symbol;
        }

        return StockData(symbol: symbol, name: name, price: price,
            change: change, changePercent: changePercent, sparkline: sparkline,
            detail: _parseDetail(meta));
      }
    } catch (_) {}
    return null;
  }

  StockDetail? _parseDetail(Map<String, dynamic> meta) {
    return StockDetail(
      marketCap: (meta['marketCap'] as num?)?.toDouble(),
      volume: (meta['regularMarketVolume'] as num?)?.toDouble(),
      high52w: (meta['fiftyTwoWeekHigh'] as num?)?.toDouble(),
      low52w: (meta['fiftyTwoWeekLow'] as num?)?.toDouble(),
      peRatio: (meta['trailingPE'] as num?)?.toDouble(),
      dividendYield: (meta['dividendYield'] as num?)?.toDouble(),
    );
  }

  Future<List<OhlcData>> fetchOhlc(String symbol) async {
    try {
      final uri = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?range=1mo&interval=1d');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final result = (body['chart']?['result'] as List?)?.firstOrNull as Map<String, dynamic>?;
        if (result == null) return [];

        final timestamps = (result['timestamp'] as List?)?.cast<int>() ?? [];
        final indicators = result['indicators'] as Map<String, dynamic>? ?? {};
        final quotes = (indicators['quote'] as List?) ?? [];
        final quote = quotes.isNotEmpty ? quotes[0] as Map<String, dynamic>? : null;
        final opens = (quote?['open'] as List?)?.cast<num?>() ?? [];
        final highs = (quote?['high'] as List?)?.cast<num?>() ?? [];
        final lows = (quote?['low'] as List?)?.cast<num?>() ?? [];
        final closes = (quote?['close'] as List?)?.cast<num?>() ?? [];

        return List.generate(timestamps.length, (i) {
          if (i >= opens.length || i >= highs.length || i >= lows.length || i >= closes.length) return null;
          return OhlcData(
            time: DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000),
            open: opens[i]?.toDouble() ?? 0,
            high: highs[i]?.toDouble() ?? 0,
            low: lows[i]?.toDouble() ?? 0,
            close: closes[i]?.toDouble() ?? 0,
          );
        }).whereType<OhlcData>().toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<SearchSuggestion>> searchSymbols(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(
          'https://query1.finance.yahoo.com/v1/finance/search?q=$query&quotesCount=10&newsCount=0');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final quotes = body['quotes'] as List? ?? [];
        return quotes.map((q) {
          final m = q as Map<String, dynamic>;
          return SearchSuggestion(
            symbol: m['symbol']?.toString() ?? '',
            name: m['shortname']?.toString() ?? m['longname']?.toString() ?? '',
            type: m['quoteType']?.toString() ?? '',
          );
        }).where((s) => s.symbol.isNotEmpty && s.type != 'CRYPTOCURRENCY').take(6).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<StockData>> fetchCryptos(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final uri = Uri.parse('https://api.coingecko.com/api/v3/simple/price')
          .replace(queryParameters: {
        'ids': ids.join(','), 'vs_currencies': 'usd', 'include_24hr_change': 'true',
      });
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final results = <StockData>[];
        for (final id in ids) {
          final data = body[id] as Map<String, dynamic>?;
          if (data == null) continue;
          final price = (data['usd'] as num?)?.toDouble() ?? 0;
          final change24h = (data['usd_24h_change'] as num?)?.toDouble() ?? 0;
          final change = price * (change24h / 100);
          final label = cryptoLabelMap[id] ?? id.toUpperCase();
          final name = cryptoNameMap[id] ?? id;

          String? imageUrl;
          List<double> sparkline = [];
          try {
            final coinUri = Uri.parse('https://api.coingecko.com/api/v3/coins/$id')
                .replace(queryParameters: {
              'localization': 'false', 'tickers': 'false',
              'community_data': 'false', 'developer_data': 'false', 'sparkline': 'true',
            });
            final coinRes = await http.get(coinUri);
            if (coinRes.statusCode == 200) {
              final coinBody = json.decode(coinRes.body) as Map<String, dynamic>;
              imageUrl = (coinBody['image'] as Map?)?['small']?.toString();
              final md = coinBody['market_data'] as Map<String, dynamic>?;
              if (md != null) {
                final sp = md['sparkline_7d'] as Map<String, dynamic>?;
                if (sp != null) {
                  final prices = sp['price'] as List?;
                  if (prices != null) sparkline = prices.map((p) => (p as num).toDouble()).toList();
                }
              }
            }
          } catch (_) {}

          results.add(StockData(symbol: label, name: name, price: price,
              change: change, changePercent: change24h, sparkline: sparkline,
              isCrypto: true, imageUrl: imageUrl));
        }
        return results;
      }
    } catch (_) {}
    return _mockCryptos(ids);
  }

  List<StockData> _mockCryptos(List<String> ids) {
    final prices = {
      'bitcoin': 67500.0, 'ethereum': 3450.0, 'cardano': 0.45,
      'solana': 165.0, 'dogecoin': 0.12, 'ripple': 0.52,
      'polkadot': 7.8, 'avalanche-2': 38.0, 'polygon': 0.72, 'chainlink': 14.5,
    };
    return ids.map((id) {
      final price = prices[id] ?? 1.0;
      final changePercent = (id.hashCode % 10 - 5).toDouble();
      return StockData(symbol: cryptoLabelMap[id] ?? id.toUpperCase(),
          name: cryptoNameMap[id] ?? id, price: price,
          change: price * (changePercent / 100), changePercent: changePercent,
          sparkline: List.generate(30, (i) => price * (1 + (i - 15) * 0.005)),
          isCrypto: true, imageUrl: null);
    }).toList();
  }

  Future<List<NewsItem>> fetchNews(String query) async {
    try {
      final uri = Uri.parse('https://query1.finance.yahoo.com/v1/finance/news?symbols=$query');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final items = body['items'] as List? ?? [];
        return items.map((i) {
          final m = i as Map<String, dynamic>;
          return NewsItem(
            title: m['title']?.toString() ?? '',
            source: m['publisher']?.toString(),
            url: m['link']?.toString(),
            imageUrl: (m['main_image'] as Map?)?['url']?.toString(),
            publishedAt: DateTime.tryParse(m['pubDate']?.toString() ?? ''),
          );
        }).where((n) => n.title.isNotEmpty).take(10).toList();
      }
    } catch (_) {}
    return _mockNews(query);
  }

  List<NewsItem> _mockNews(String query) => [
    NewsItem(title: '$query Reports Strong Quarterly Earnings', source: 'Financial Times',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2))),
    NewsItem(title: 'Analysts Raise $query Price Target', source: 'Bloomberg',
        publishedAt: DateTime.now().subtract(const Duration(hours: 5))),
    NewsItem(title: '$query Announces New Product Line', source: 'Reuters',
        publishedAt: DateTime.now().subtract(const Duration(days: 1))),
    NewsItem(title: '$query Stock Surges on Market Optimism', source: 'CNBC',
        publishedAt: DateTime.now().subtract(const Duration(days: 2))),
    NewsItem(title: 'Why $query Is a Top Pick for 2026', source: 'Morningstar',
        publishedAt: DateTime.now().subtract(const Duration(days: 3))),
  ];
}

class PortfolioStorageService {
  Box<String>? _box;
  bool _ready = false;

  Future<void> init() async {
    _box = await Hive.openBox<String>('portfolio');
    _ready = true;
  }

  bool get isReady => _ready;

  List<PortfolioHolding> getAll() {
    if (!_ready) return [];
    final raw = _box?.get('holdings', defaultValue: '[]') ?? '[]';
    return (json.decode(raw) as List).map((e) => PortfolioHolding.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addHolding(PortfolioHolding h) async {
    if (!_ready) return;
    final all = getAll();
    all.insert(0, h);
    _save(all);
  }

  Future<void> updateHolding(String symbol, double shares, double price) async {
    if (!_ready) return;
    final all = getAll().map((h) => h.symbol == symbol ? h.copyWith(shares: shares, purchasePrice: price) : h).toList();
    _save(all);
  }

  Future<void> removeHolding(String symbol) async {
    if (!_ready) return;
    _save(getAll().where((h) => h.symbol != symbol).toList());
  }

  void _save(List<PortfolioHolding> list) {
    _box?.put('holdings', json.encode(list.map((h) => h.toJson()).toList()));
  }
}

class PriceAlertService {
  Box<String>? _box;
  bool _ready = false;

  Future<void> init() async {
    _box = await Hive.openBox<String>('price_alerts');
    _ready = true;
  }

  List<PriceAlert> getAll() {
    if (!_ready) return [];
    final raw = _box?.get('alerts', defaultValue: '[]') ?? '[]';
    return (json.decode(raw) as List).map((e) => PriceAlert.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addAlert(PriceAlert a) async {
    if (!_ready) return;
    final all = getAll();
    all.insert(0, a);
    _box?.put('alerts', json.encode(all.map((a) => a.toJson()).toList()));
  }

  Future<void> removeAlert(String symbol) async {
    if (!_ready) return;
    final all = getAll().where((a) => a.symbol != symbol).toList();
    _box?.put('alerts', json.encode(all.map((a) => a.toJson()).toList()));
  }

  void checkAlerts(Map<String, double> prices) {
    if (!_ready) return;
    for (final a in getAll()) {
      final price = prices[a.symbol];
      if (price == null) continue;
      if ((a.isAbove && price >= a.targetPrice) || (!a.isAbove && price <= a.targetPrice)) {
        notificationService.showPriceAlert(a.symbol, price, a.targetPrice);
        removeAlert(a.symbol);
      }
    }
  }
}

final portfolioService = PortfolioService();
final portfolioStorage = PortfolioStorageService();
final priceAlertService = PriceAlertService();
