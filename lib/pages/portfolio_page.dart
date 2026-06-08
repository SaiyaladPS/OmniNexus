import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../models/portfolio.dart';
import '../services/portfolio_service.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final List<StockData> _watchlist = [];
  List<PortfolioHolding> _holdings = [];
  final Map<String, StockData> _priceMap = {};
  bool _searching = false;
  StockData? _searchResult;
  String? _searchError;
  int _tabIndex = 0;

  List<SearchSuggestion> _suggestions = [];
  bool _loadingSuggestions = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
    _loadPopularCryptos();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      setState(() { _suggestions = []; _searchResult = null; _searchError = null; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetchSuggestions(q));
  }

  Future<void> _fetchSuggestions(String q) async {
    setState(() => _loadingSuggestions = true);
    final result = await portfolioService.searchSymbols(q);
    if (!mounted) return;
    setState(() {
      _suggestions = result;
      _loadingSuggestions = false;
    });
  }

  Future<void> _loadPortfolio() async {
    setState(() => _holdings = portfolioStorage.getAll());
    await _refreshPrices();
  }

  Future<void> _refreshPrices() async {
    final symbols = _holdings.map((h) => h.symbol).toSet();
    for (final w in _watchlist) { symbols.add(w.symbol); }
    if (symbols.isEmpty) return;
    for (final sym in symbols) {
      final data = await portfolioService.fetchStock(sym);
      if (data != null && mounted) { setState(() { _priceMap[sym] = data; }); }
    }
    priceAlertService.checkAlerts(_priceMap.map((k, v) => MapEntry(k, v.price)));
  }

  Future<void> _loadPopularCryptos() async {
    final data = await portfolioService.fetchCryptos(popularCryptos.take(5).toList());
    if (!mounted) return;
    for (final d in data) { _priceMap[d.symbol] = d; }
    setState(() {});
  }

  Future<void> _search(String query) async {
    _searchFocus.unfocus();
    final q = query.trim().toUpperCase();
    if (q.isEmpty) return;
    setState(() { _searching = true; _searchResult = null; _searchError = null; _suggestions = []; });

    if (q.startsWith(r'$')) {
      final cryptoKey = cryptoLabelMap.entries.firstWhereOrNull((e) => '\$${e.value}' == q)?.key;
      if (cryptoKey != null) {
        final cryptos = await portfolioService.fetchCryptos([cryptoKey]);
        if (cryptos.isNotEmpty && mounted) {
          setState(() { _searchResult = cryptos.first; _searching = false; });
          _addToWatchlist(cryptos.first);
          return;
        }
      }
    }

    final stock = await portfolioService.fetchStock(q);
    if (stock != null && mounted) {
      setState(() { _searchResult = stock; _searching = false; });
      _addToWatchlist(stock);
      return;
    }

    final cryptoId = cryptoLabelMap.entries.firstWhereOrNull((e) => e.value == q)?.key;
    if (cryptoId != null) {
      final cryptos = await portfolioService.fetchCryptos([cryptoId]);
      if (cryptos.isNotEmpty && mounted) {
        setState(() { _searchResult = cryptos.first; _searching = false; });
        _addToWatchlist(cryptos.first);
        return;
      }
    }
    if (mounted) setState(() { _searchError = 'No data for "$q"'; _searching = false; });
  }

  void _addToWatchlist(StockData data) {
    if (_watchlist.any((w) => w.symbol == data.symbol)) return;
    _watchlist.insert(0, data);
    _priceMap[data.symbol] = data;
  }

  void _removeFromWatchlist(String symbol) => setState(() => _watchlist.removeWhere((w) => w.symbol == symbol));

  void _showAddHoldingDialog(StockData data) {
    final sharesCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: data.price.toStringAsFixed(2));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Add ${data.symbol}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: sharesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Shares', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Purchase Price (\$)', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final shares = double.tryParse(sharesCtrl.text);
          final price = double.tryParse(priceCtrl.text);
          if (shares == null || price == null || shares <= 0 || price <= 0) return;
          await portfolioStorage.addHolding(PortfolioHolding(symbol: data.symbol, name: data.name, shares: shares, purchasePrice: price, addedAt: DateTime.now()));
          if (!ctx.mounted) return;
          Navigator.pop(ctx);
          if (!mounted) return;
          _loadPortfolio();
          _showSnack('${data.symbol} added');
        }, child: const Text('Add')),
      ],
    ));
  }

  void _showEditHoldingDialog(PortfolioHolding h) {
    final sharesCtrl = TextEditingController(text: h.shares.toString());
    final priceCtrl = TextEditingController(text: h.purchasePrice.toStringAsFixed(2));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Edit ${h.symbol}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: sharesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Shares', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Purchase Price (\$)', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final shares = double.tryParse(sharesCtrl.text);
          final price = double.tryParse(priceCtrl.text);
          if (shares == null || price == null || shares <= 0 || price <= 0) return;
          await portfolioStorage.updateHolding(h.symbol, shares, price);
          if (!ctx.mounted) return;
          Navigator.pop(ctx);
          if (!mounted) return;
          _loadPortfolio();
          _showSnack('${h.symbol} updated');
        }, child: const Text('Save')),
      ],
    ));
  }

  void _showPriceAlertDialog(StockData data) {
    final priceCtrl = TextEditingController(text: data.price.toStringAsFixed(2));
    bool isAbove = data.isPositive;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text('Price Alert: ${data.symbol}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Current: \$${data.priceFormatted}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Target Price (\$)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Row(children: [
            Text(isAbove ? 'Alert when price goes above' : 'Alert when price goes below',
                style: const TextStyle(fontSize: 13)),
            const Spacer(),
            Switch(value: isAbove, onChanged: (v) => setDialogState(() => isAbove = v)),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            final target = double.tryParse(priceCtrl.text);
            if (target == null || target <= 0) return;
            await priceAlertService.addAlert(PriceAlert(symbol: data.symbol, targetPrice: target, isAbove: isAbove, createdAt: DateTime.now()));
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            if (!mounted) return;
            _showSnack('Alert set for ${data.symbol} at \$${target.toStringAsFixed(2)}');
          }, child: const Text('Set Alert')),
        ],
      ),
    ));
  }

  void _showDetailSheet(StockData data) async {
    final ohlc = await portfolioService.fetchOhlc(data.symbol);
    final news = await portfolioService.fetchNews(data.symbol);
    if (!mounted) return;
    _buildDetailSheet(context, data, ohlc, news);
  }

  void _exportCsv() {
    final h = _holdings;
    if (h.isEmpty) { _showSnack('No holdings to export'); return; }
    final rows = StringBuffer('Symbol,Name,Shares,Purchase Price,Current Price,Cost,Value,P&L\n');
    for (final item in h) {
      final price = _priceMap[item.symbol]?.price ?? 0;
      final cost = item.shares * item.purchasePrice;
      final value = item.shares * price;
      rows.writeln('${item.symbol},${item.name},${item.shares},${item.purchasePrice},$price,$cost,$value,${value - cost}');
    }
    Share.share(rows.toString(), subject: 'Portfolio Export');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Stock & Crypto'),
        backgroundColor: c.appBar,
        foregroundColor: c.accent,
        elevation: 0,
        actions: [
          if (_holdings.isNotEmpty)
            IconButton(icon: const Icon(Icons.file_download, size: 20), onPressed: _exportCsv, tooltip: 'Export CSV'),
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _refreshPrices),
        ],
      ),
      body: Column(children: [
        _buildSearchBar(c),
        _buildQuickCrypto(c),
        _buildTabRow(c),
        Expanded(child: _buildBody(c)),
      ]),
    );
  }

  Widget _buildSearchBar(AppThemeColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.accent.withValues(alpha: 0.15))),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    style: TextStyle(color: c.text, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search symbol or name...',
                      hintStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                      border: InputBorder.none,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(icon: Icon(Icons.clear, size: 18, color: c.textSecondary),
                              onPressed: () { _searchController.clear(); setState(() { _searchResult = null; _searchError = null; _suggestions = []; }); })
                          : null,
                    ),
                    onSubmitted: _search,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _search(_searchController.text),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(14)),
                  child: _searching
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(Icons.search, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.accent.withValues(alpha: 0.1))),
              child: Column(
                children: [
                  if (_loadingSuggestions)
                    const Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                  else
                    ..._suggestions.map((s) => InkWell(
                      onTap: () { _searchController.text = s.symbol; _search(s.symbol); },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(children: [
                          Text(s.symbol, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: c.text)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s.name, style: TextStyle(fontSize: 12, color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(4)),
                            child: Text(s.type, style: TextStyle(fontSize: 8, color: c.textSecondary))),
                        ]),
                      ),
                    )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickCrypto(AppThemeColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SizedBox(
        height: 32,
        child: ListView(scrollDirection: Axis.horizontal,
          children: popularCryptos.take(8).map((id) {
            final label = cryptoLabelMap[id] ?? id;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () { _searchController.text = label; _search(label); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.accent.withValues(alpha: 0.2))),
                  child: Center(child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.accent))),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabRow(AppThemeColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
      child: Row(children: [
        _tab(c, 'Watchlist', 0), const SizedBox(width: 8), _tab(c, 'Portfolio', 1),
        if (_holdings.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 8),
            child: Text('${_holdings.length} items', style: TextStyle(fontSize: 11, color: c.textSecondary))),
      ]),
    );
  }

  Widget _tab(AppThemeColors c, String label, int i) {
    final active = _tabIndex == i;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(color: active ? c.accent : c.surface, borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : c.textSecondary)),
      ),
    );
  }

  Widget _buildBody(AppThemeColors c) {
    if (_searchResult != null) {
      return Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: _buildStockCard(c, _searchResult!, showActions: true)),
        Expanded(child: _buildTabContent(c)),
      ]);
    }
    if (_searchError != null) {
      return Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Container(width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Text(_searchError!, style: TextStyle(color: Colors.red.shade300, fontSize: 13)))),
        Expanded(child: _buildTabContent(c)),
      ]);
    }
    return _buildTabContent(c);
  }

  Widget _buildTabContent(AppThemeColors c) {
    if (_tabIndex == 0) return _buildWatchlist(c);
    return _buildPortfolio(c);
  }

  Widget _buildWatchlist(AppThemeColors c) {
    if (_watchlist.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.travel_explore, size: 48, color: c.textSecondary),
        const SizedBox(height: 12),
        Text('Search stocks or tap crypto above', style: TextStyle(color: c.textSecondary, fontSize: 14)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _refreshPrices, color: c.accent,
      child: ListView.builder(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _watchlist.length,
        itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(bottom: 8),
            child: _buildStockCard(c, _watchlist[i], onRemove: () => _removeFromWatchlist(_watchlist[i].symbol))),
      ),
    );
  }

  Widget _buildPortfolio(AppThemeColors c) {
    if (_holdings.isEmpty && _watchlist.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.account_balance, size: 48, color: c.textSecondary),
        const SizedBox(height: 12),
        Text('Portfolio is empty', style: TextStyle(color: c.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Search any stock or crypto above,', style: TextStyle(color: c.textSecondary, fontSize: 13)),
        Text('then tap "Add to Portfolio"', style: TextStyle(color: c.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: () { _search('BTC'); setState(() {}); },
          icon: const Icon(Icons.trending_up, size: 18), label: const Text('Try BTC as example', style: TextStyle(fontSize: 13)),
          style: FilledButton.styleFrom(backgroundColor: c.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      ]));
    }
    if (_holdings.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(14), margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.accent.withValues(alpha: 0.15))),
          child: Column(children: [
            Row(children: [Icon(Icons.lightbulb_outline, size: 18, color: c.accent), const SizedBox(width: 8),
              Text('How to add holdings?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text))]),
            const SizedBox(height: 10),
            Text('• Search a stock/crypto above', style: TextStyle(fontSize: 12, color: c.textSecondary)),
            Text('• Tap "Add to Portfolio" on the result', style: TextStyle(fontSize: 12, color: c.textSecondary)),
            Text('• Enter shares & purchase price', style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ])),
        const SizedBox(height: 16),
        TextButton.icon(onPressed: () => setState(() => _tabIndex = 0),
          icon: Icon(Icons.visibility, size: 16, color: c.accent),
          label: Text('Switch to Watchlist', style: TextStyle(color: c.accent, fontSize: 13))),
      ]));
    }

    double totalCost = 0, totalValue = 0;
    final items = _holdings.map((h) {
      final price = _priceMap[h.symbol]?.price ?? 0;
      final cost = h.shares * h.purchasePrice;
      final value = h.shares * price;
      totalCost += cost; totalValue += value;
      return _HoldingDisplay(holding: h, currentPrice: price, cost: cost, value: value);
    }).toList();
    final pnl = totalValue - totalCost;
    final pnlP = totalCost > 0 ? (pnl / totalCost) * 100 : 0.0;

    return RefreshIndicator(
      onRefresh: _refreshPrices, color: c.accent,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
        _buildPortfolioHeader(c, totalValue, pnl, pnlP, items),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 8),
            child: _buildHoldingCard(c, item))),
      ]),
    );
  }

  Widget _buildPortfolioHeader(AppThemeColors c, double total, double pnl, double pnlP, List<_HoldingDisplay> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [c.card, c.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16), border: Border.all(color: c.accent.withValues(alpha: 0.15))),
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Portfolio Value', style: TextStyle(fontSize: 12, color: c.textSecondary)),
            Text('\$${(total).toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c.text)),
            Row(children: [
              Icon(pnl >= 0 ? Icons.trending_up : Icons.trending_down, size: 14, color: pnl >= 0 ? Colors.green : Colors.red),
              const SizedBox(width: 4),
              Text('${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)} (${pnlP >= 0 ? '+' : ''}${pnlP.toStringAsFixed(2)}%)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: pnl >= 0 ? Colors.green : Colors.red)),
            ]),
          ])),
          if (items.isNotEmpty)
            SizedBox(
              width: 80, height: 80,
              child: PieChart(PieChartData(
                sectionsSpace: 2, centerSpaceRadius: 16,
                sections: items.map((item) {
                  final pct = total > 0 ? item.value / total : 0.0;
                  return PieChartSectionData(value: pct.toDouble(), color: _stockIconColor(item.holding.symbol),
                      radius: 14, title: '${(pct * 100).toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white));
                }).toList(),
              )),
            ),
        ]),
      ]),
    );
  }

  Widget _buildStockCard(AppThemeColors c, StockData data, {bool showActions = false, VoidCallback? onRemove}) {
    return GestureDetector(
      onTap: () => _showDetailSheet(data),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.accent.withValues(alpha: 0.1))),
        child: Column(children: [
          Row(children: [
            StockIcon(symbol: data.symbol, imageUrl: data.imageUrl, size: 36),
            const SizedBox(width: 10),
            SizedBox(width: 60, height: 36,
                child: data.sparkline.length >= 2 ? Sparkline(data: data.sparkline, color: data.isPositive ? Colors.green : Colors.red) : null),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(data.symbol, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.text)),
                if (data.isCrypto) ...[const SizedBox(width: 4),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
                    child: Text('C', style: TextStyle(fontSize: 8, color: Colors.orange.shade400, fontWeight: FontWeight.w600)))],
              ]),
              Text(data.name, style: TextStyle(fontSize: 10, color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('\$${data.priceFormatted}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.text)),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(data.isPositive ? Icons.arrow_upward : Icons.arrow_downward, size: 11, color: data.isPositive ? Colors.green : Colors.red),
                Text(data.changePercentFormatted, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: data.isPositive ? Colors.green : Colors.red)),
              ]),
            ]),
          ]),
          if (data.detail != null) _buildDetailRow(c, data.detail!),
          if (showActions || onRemove != null)
            Padding(padding: const EdgeInsets.only(top: 8), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (showActions) ...[
                TextButton.icon(onPressed: () => _showPriceAlertDialog(data), icon: const Icon(Icons.notifications, size: 14), label: const Text('Alert', style: TextStyle(fontSize: 11))),
                const SizedBox(width: 4),
                TextButton.icon(onPressed: () => _showAddHoldingDialog(data), icon: const Icon(Icons.add, size: 14), label: const Text('Buy', style: TextStyle(fontSize: 11))),
              ],
              if (onRemove != null) IconButton(icon: Icon(Icons.close, size: 16, color: c.textSecondary), onPressed: onRemove, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ])),
        ]),
      ),
    );
  }

  Widget _buildDetailRow(AppThemeColors c, StockDetail d) {
    return Padding(padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        if (d.marketCap != null) ...[Icon(Icons.account_balance, size: 11, color: c.textSecondary),
          Text(' ${d.marketCapFormatted}', style: TextStyle(fontSize: 10, color: c.textSecondary)), const SizedBox(width: 8)],
        if (d.volume != null) ...[Icon(Icons.bar_chart, size: 11, color: c.textSecondary),
          Text(' ${d.volumeFormatted}', style: TextStyle(fontSize: 10, color: c.textSecondary)), const SizedBox(width: 8)],
        if (d.peRatio != null) ...[Icon(Icons.trending_up, size: 11, color: c.textSecondary),
          Text('P/E ${d.peRatio!.toStringAsFixed(1)}', style: TextStyle(fontSize: 10, color: c.textSecondary))],
      ]),
    );
  }

  Widget _buildHoldingCard(AppThemeColors c, _HoldingDisplay item) {
    final pnl = item.value - item.cost;
    final pnlP = item.cost > 0 ? (pnl / item.cost) * 100 : 0.0;
    final perf = item.cost > 0 ? (item.value / item.cost) : 1.0;
    return GestureDetector(
      onLongPress: () => _showEditHoldingDialog(item.holding),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.accent.withValues(alpha: 0.1))),
        child: Column(children: [
          Row(children: [
            StockIcon(symbol: item.holding.symbol, size: 32),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.holding.symbol, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.text)),
              Text(item.holding.name, style: TextStyle(fontSize: 10, color: c.textSecondary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('\$${item.value.toStringAsFixed(2)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.text)),
              Text('${item.holding.shares.toStringAsFixed(4)} sh', style: TextStyle(fontSize: 10, color: c.textSecondary)),
            ]),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(value: perf < 2 ? perf : 1.0, minHeight: 4,
              backgroundColor: c.surface,
              valueColor: AlwaysStoppedAnimation(pnl >= 0 ? Colors.green : Colors.red)),
          ),
          const SizedBox(height: 6),
          Row(children: [
            _chip(c, 'Cost', '\$${item.cost.toStringAsFixed(2)}'),
            const SizedBox(width: 6),
            _chip(c, 'Price', '\$${item.currentPrice.toStringAsFixed(2)}'),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: pnl >= 0 ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text('${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)} (${pnlP >= 0 ? '+' : ''}${pnlP.toStringAsFixed(1)}%)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pnl >= 0 ? Colors.green : Colors.red)),
            ),
            const SizedBox(width: 4),
            GestureDetector(onTap: () async { await portfolioStorage.removeHolding(item.holding.symbol); _loadPortfolio(); },
                child: Icon(Icons.delete_outline, size: 16, color: c.textSecondary)),
          ]),
        ]),
      ),
    );
  }

  Widget _chip(AppThemeColors c, String label, String value) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(6)),
      child: Text('$label: $value', style: TextStyle(fontSize: 10, color: c.textSecondary)));
  }

  void _buildDetailSheet(BuildContext context, StockData data, List<OhlcData> ohlc, List<NewsItem> news) {
    final c = ThemeProviderScope.of(context).colors;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(color: c.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(controller: scrollCtrl, padding: const EdgeInsets.all(20), children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: c.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              margin: const EdgeInsets.only(bottom: 16, left: 0)),
            Row(children: [
              StockIcon(symbol: data.symbol, imageUrl: data.imageUrl, size: 44),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data.symbol, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c.text)),
                Text(data.name, style: TextStyle(fontSize: 12, color: c.textSecondary)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('\$${data.priceFormatted}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c.text)),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(data.isPositive ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: data.isPositive ? Colors.green : Colors.red),
                  Text(data.changePercentFormatted, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: data.isPositive ? Colors.green : Colors.red)),
                ]),
              ]),
            ]),
            const SizedBox(height: 16),
            if (ohlc.length >= 2) ...[
              SizedBox(height: 160, child: _CandlestickChart(data: ohlc)),
              const SizedBox(height: 16),
            ],
            if (data.detail != null) ...[
              Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.accent.withValues(alpha: 0.1))),
                child: Column(children: [
                  Row(children: [
                    _statBox(c, 'Market Cap', data.detail!.marketCapFormatted),
                    _statBox(c, 'Volume', data.detail!.volumeFormatted),
                    _statBox(c, 'P/E', data.detail!.peRatio?.toStringAsFixed(1) ?? 'N/A'),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    _statBox(c, '52W High', data.detail!.high52w?.toStringAsFixed(2) ?? 'N/A'),
                    _statBox(c, '52W Low', data.detail!.low52w?.toStringAsFixed(2) ?? 'N/A'),
                    _statBox(c, 'Div Yield', data.detail!.dividendYield != null ? '${(data.detail!.dividendYield! * 100).toStringAsFixed(2)}%' : 'N/A'),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
            ],
            Row(children: [
              Expanded(child: FilledButton.icon(onPressed: () => _showAddHoldingDialog(data),
                  icon: const Icon(Icons.add, size: 16), label: const Text('Buy'),
                  style: FilledButton.styleFrom(backgroundColor: c.accent))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () => _showPriceAlertDialog(data),
                  icon: const Icon(Icons.notifications, size: 16), label: const Text('Alert'),
                  style: OutlinedButton.styleFrom(foregroundColor: c.accent, side: BorderSide(color: c.accent)))),
            ]),
            if (news.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(children: [Icon(Icons.article, size: 16, color: c.accent), const SizedBox(width: 6),
                Text('News', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text))]),
              const SizedBox(height: 8),
              ...news.map((n) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.accent.withValues(alpha: 0.08))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.text)),
                  const SizedBox(height: 4),
                  Row(children: [
                    if (n.source != null) Text(n.source!, style: TextStyle(fontSize: 10, color: c.accent)),
                    if (n.publishedAt != null) ...[const SizedBox(width: 8),
                      Text(_timeAgo(n.publishedAt!), style: TextStyle(fontSize: 10, color: c.textSecondary))],
                  ]),
                ]),
              ))),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _statBox(AppThemeColors c, String label, String value) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c.text)),
      Text(label, style: TextStyle(fontSize: 9, color: c.textSecondary)),
    ]));
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

final _stockColors = [
  const Color(0xFFE57373), const Color(0xFFF06292), const Color(0xFFBA68C8),
  const Color(0xFF9575CD), const Color(0xFF7986CB), const Color(0xFF64B5F6),
  const Color(0xFF4FC3F7), const Color(0xFF4DD0E1), const Color(0xFF4DB6AC),
  const Color(0xFF81C784), const Color(0xFFAED581), const Color(0xFFFFD54F),
  const Color(0xFFFFB74D), const Color(0xFFF57C00), const Color(0xFFA1887F),
  const Color(0xFF90A4AE),
];

Color _stockIconColor(String symbol) => _stockColors[symbol.hashCode.abs() % _stockColors.length];

class StockIcon extends StatelessWidget {
  final String symbol;
  final String? imageUrl;
  final double size;
  const StockIcon({super.key, required this.symbol, this.imageUrl, this.size = 36});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return Container(width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
        child: ClipOval(child: Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => _textAvatar())),
      );
    }
    return _textAvatar();
  }

  Widget _textAvatar() => Container(width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: _stockIconColor(symbol)),
    child: Center(child: Text(symbol.substring(0, 1).toUpperCase(),
        style: TextStyle(fontSize: size * 0.45, fontWeight: FontWeight.bold, color: Colors.white))));
}

class Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  const Sparkline({super.key, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return const SizedBox.shrink();
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final pad = (max - min) * 0.1;
    if (pad == 0) return const SizedBox.shrink();
    return LineChart(LineChartData(
      minY: min - pad, maxY: max + pad, clipData: const FlClipData.all(),
      gridData: const FlGridData(show: false), titlesData: const FlTitlesData(show: false), borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(
        spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
        isCurved: true, preventCurveOverShooting: true, color: color, barWidth: 1.5,
        dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
      )],
    ), duration: const Duration(milliseconds: 300));
  }
}

class _CandlestickChart extends StatelessWidget {
  final List<OhlcData> data;
  const _CandlestickChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final c = ThemeProviderScope.of(context).colors;
    return LayoutBuilder(builder: (_, constraints) {
      return CustomPaint(size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _CandlestickPainter(data, c));
    });
  }
}

class _CandlestickPainter extends CustomPainter {
  final List<OhlcData> data;
  final AppThemeColors c;
  _CandlestickPainter(this.data, this.c);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final all = data.expand((d) => [d.high, d.low]).toList();
    final min = all.reduce((a, b) => a < b ? a : b) - 2;
    final max = all.reduce((a, b) => a > b ? a : b) + 2;
    final range = max - min;
    if (range <= 0) return;

    final w = size.width / data.length;
    final candleW = (w * 0.6).clamp(2.0, 12.0);

    for (int i = 0; i < data.length; i++) {
      final o = data[i];
      final x = i * w + w / 2;
      final yHigh = _y(o.high, min, range, size.height);
      final yLow = _y(o.low, min, range, size.height);
      final yOpen = _y(o.open, min, range, size.height);
      final yClose = _y(o.close, min, range, size.height);
      final isUp = o.close >= o.open;
      final color = isUp ? Colors.green : Colors.red;

      canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), Paint()..color = color..strokeWidth = 1);
      canvas.drawRect(Rect.fromLTRB(x - candleW / 2, yOpen, x + candleW / 2, yClose),
          Paint()..color = color);
    }
  }

  double _y(double v, double min, double range, double h) =>
      h - ((v - min) / range) * (h - 20) - 10;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _HoldingDisplay {
  final PortfolioHolding holding;
  final double currentPrice;
  final double cost;
  final double value;
  const _HoldingDisplay({required this.holding, required this.currentPrice, required this.cost, required this.value});
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final e in this) { if (test(e)) return e; }
    return null;
  }
}
