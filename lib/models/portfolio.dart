class StockData {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final List<double> sparkline;
  final bool isCrypto;
  final String? imageUrl;
  final StockDetail? detail;

  StockData({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.sparkline,
    this.isCrypto = false,
    this.imageUrl,
    this.detail,
  });

  bool get isPositive => change >= 0;
  String get priceFormatted => price.toStringAsFixed(2);
  String get changeFormatted =>
      '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}';
  String get changePercentFormatted =>
      '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%';
}

class StockDetail {
  final double? marketCap;
  final double? volume;
  final double? high52w;
  final double? low52w;
  final double? peRatio;
  final double? dividendYield;

  StockDetail({
    this.marketCap,
    this.volume,
    this.high52w,
    this.low52w,
    this.peRatio,
    this.dividendYield,
  });

  String get marketCapFormatted {
    if (marketCap == null) return 'N/A';
    if (marketCap! >= 1e12) return '${(marketCap! / 1e12).toStringAsFixed(2)}T';
    if (marketCap! >= 1e9) return '${(marketCap! / 1e9).toStringAsFixed(2)}B';
    if (marketCap! >= 1e6) return '${(marketCap! / 1e6).toStringAsFixed(2)}M';
    return marketCap!.toStringAsFixed(0);
  }

  String get volumeFormatted {
    if (volume == null) return 'N/A';
    if (volume! >= 1e9) return '${(volume! / 1e9).toStringAsFixed(2)}B';
    if (volume! >= 1e6) return '${(volume! / 1e6).toStringAsFixed(2)}M';
    return volume!.toStringAsFixed(0);
  }
}

class OhlcData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  OhlcData({required this.time, required this.open, required this.high, required this.low, required this.close});
}

class PriceAlert {
  final String symbol;
  final double targetPrice;
  final bool isAbove;
  final DateTime createdAt;

  PriceAlert({
    required this.symbol,
    required this.targetPrice,
    required this.isAbove,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'targetPrice': targetPrice,
    'isAbove': isAbove,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PriceAlert.fromJson(Map<String, dynamic> json) => PriceAlert(
    symbol: json['symbol']?.toString() ?? '',
    targetPrice: (json['targetPrice'] as num?)?.toDouble() ?? 0,
    isAbove: json['isAbove'] == true,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
  );
}

class NewsItem {
  final String title;
  final String? source;
  final String? url;
  final String? imageUrl;
  final DateTime? publishedAt;

  NewsItem({required this.title, this.source, this.url, this.imageUrl, this.publishedAt});
}

class SearchSuggestion {
  final String symbol;
  final String name;
  final String type;

  SearchSuggestion({required this.symbol, required this.name, required this.type});
}

class PortfolioHolding {
  final String symbol;
  final String name;
  final double shares;
  final double purchasePrice;
  final DateTime addedAt;

  PortfolioHolding({
    required this.symbol,
    required this.name,
    required this.shares,
    required this.purchasePrice,
    required this.addedAt,
  });

  PortfolioHolding copyWith({double? shares, double? purchasePrice}) => PortfolioHolding(
    symbol: symbol, name: name,
    shares: shares ?? this.shares,
    purchasePrice: purchasePrice ?? this.purchasePrice,
    addedAt: addedAt,
  );

  Map<String, dynamic> toJson() => {
    'symbol': symbol, 'name': name, 'shares': shares,
    'purchasePrice': purchasePrice, 'addedAt': addedAt.toIso8601String(),
  };

  factory PortfolioHolding.fromJson(Map<String, dynamic> json) => PortfolioHolding(
    symbol: json['symbol']?.toString() ?? '',
    name: json['name']?.toString() ?? json['symbol']?.toString() ?? '',
    shares: (json['shares'] as num?)?.toDouble() ?? 0,
    purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0,
    addedAt: DateTime.tryParse(json['addedAt']?.toString() ?? '') ?? DateTime.now(),
  );
}

const popularCryptos = [
  'bitcoin', 'ethereum', 'cardano', 'solana', 'dogecoin',
  'ripple', 'polkadot', 'avalanche-2', 'polygon', 'chainlink',
];

const cryptoLabelMap = {
  'bitcoin': 'BTC', 'ethereum': 'ETH', 'cardano': 'ADA', 'solana': 'SOL',
  'dogecoin': 'DOGE', 'ripple': 'XRP', 'polkadot': 'DOT', 'avalanche-2': 'AVAX',
  'polygon': 'MATIC', 'chainlink': 'LINK',
};

const cryptoNameMap = {
  'bitcoin': 'Bitcoin', 'ethereum': 'Ethereum', 'cardano': 'Cardano',
  'solana': 'Solana', 'dogecoin': 'Dogecoin', 'ripple': 'XRP',
  'polkadot': 'Polkadot', 'avalanche-2': 'Avalanche', 'polygon': 'Polygon',
  'chainlink': 'Chainlink',
};
