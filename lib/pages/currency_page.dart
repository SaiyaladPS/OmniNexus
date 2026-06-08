import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/currency_service.dart';
import '../services/currency_history_service.dart';
import '../models/currency_rates.dart';

class CurrencyPage extends StatefulWidget {
  const CurrencyPage({super.key});

  @override
  State<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage> {
  final _amountController = TextEditingController(text: '1');
  ExchangeRates? _rates;
  bool _loading = true;
  String _from = 'USD';
  String _to = 'THB';
  double? _result;
  List<CurrencyRecord> _history = [];

  @override
  void initState() {
    super.initState();
    _loadRates();
    _loadHistory();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _loadHistory() {
    setState(() => _history = currencyHistoryService.getAll());
  }

  Future<void> _loadRates() async {
    setState(() => _loading = true);
    final rates = await currencyService.fetchRates(_from);
    if (mounted) {
      setState(() {
        _rates = rates;
        _loading = false;
      });
      _convert();
    }
  }

  void _convert() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (_rates == null || amount <= 0) {
      setState(() => _result = null);
      return;
    }
    setState(() {
      _result = _rates!.convert(amount, _from, _to);
    });
  }

  Future<void> _saveRecord() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (_result == null || amount <= 0) return;
    await currencyHistoryService.addRecord(
      CurrencyRecord(from: _from, to: _to, amount: amount, result: _result!, timestamp: DateTime.now()),
    );
    _loadHistory();
  }

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
    });
    _loadRates();
  }

  void _pickCurrency({required bool isSource}) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CurrencyPickerSheet(selected: isSource ? _from : _to),
    );
    if (result != null) {
      setState(() {
        if (isSource) {
          _from = result;
        } else {
          _to = result;
        }
      });
      _loadRates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Currency Converter'),
        backgroundColor: c.appBar,
        foregroundColor: c.accentTertiary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAmountField(c),
          const SizedBox(height: 16),
          _buildCurrencyRow(c),
          const SizedBox(height: 24),
          _buildResult(c),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                _convert();
                await _saveRecord();
              },
              icon: const Icon(Icons.swap_horiz),
              label: Text(_from == _to ? 'Select different currencies' : 'Convert & Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _from == _to ? c.textSecondary : c.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildHistory(c),
        ],
      ),
    );
  }

  Widget _buildAmountField(AppThemeColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.accent.withValues(alpha: 0.15)),
      ),
      child: TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: c.text),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Enter amount',
          hintStyle: TextStyle(color: c.textSecondary),
        ),
        onChanged: (_) => _convert(),
      ),
    );
  }

  Widget _buildCurrencyRow(AppThemeColors c) {
    return Row(
      children: [
        Expanded(child: _currencySelector(c, _from, () => _pickCurrency(isSource: true))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GestureDetector(
            onTap: _swap,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.accent.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.swap_vert, color: c.accent, size: 22),
            ),
          ),
        ),
        Expanded(child: _currencySelector(c, _to, () => _pickCurrency(isSource: false))),
      ],
    );
  }

  Widget _currencySelector(AppThemeColors c, String code, VoidCallback onTap) {
    final name = currencyNames[code] ?? code;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.accent.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(code, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c.accent)),
            const SizedBox(height: 2),
            Text(name, style: TextStyle(fontSize: 11, color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(AppThemeColors c) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: c.accent));
    }
    if (_result == null) {
      return Center(child: Text('Enter an amount to convert', style: TextStyle(color: c.textSecondary)));
    }
    if (_from == _to) {
      return Center(child: Text('Select different currencies', style: TextStyle(fontSize: 16, color: c.textSecondary)));
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text('${_amountController.text} $_from =', style: TextStyle(fontSize: 16, color: c.textSecondary)),
          const SizedBox(height: 8),
          Text(_result!.toStringAsFixed(2), style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: c.accent)),
          Text(_to, style: TextStyle(fontSize: 18, color: c.textSecondary)),
          if (_rates != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '1 $_from = ${_rates!.convert(1, _from, _to).toStringAsFixed(4)} $_to',
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistory(AppThemeColors c) {
    if (_history.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Text('Conversion History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text)),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                await currencyHistoryService.clear();
                _loadHistory();
              },
              child: Text('Clear', style: TextStyle(fontSize: 12, color: c.accent)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._history.take(10).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.accent.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${r.amount.toStringAsFixed(2)} ${r.from} → ${r.result.toStringAsFixed(2)} ${r.to}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
                          Text(_formatTime(r.timestamp),
                              style: TextStyle(fontSize: 10, color: c.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, size: 16, color: c.accent.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _CurrencyPickerSheet extends StatefulWidget {
  final String selected;
  const _CurrencyPickerSheet({required this.selected});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _searchController = TextEditingController();
  List<String> _filtered = List.from(commonCurrencies);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.from(commonCurrencies);
      } else {
        _filtered = commonCurrencies.where((c) {
          final name = (currencyNames[c] ?? '').toLowerCase();
          return c.toLowerCase().contains(q) || name.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: c.text),
              decoration: InputDecoration(
                hintText: 'Search currency...',
                hintStyle: TextStyle(color: c.textSecondary, fontSize: 14),
                filled: true,
                fillColor: c.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: c.accent, size: 22),
              ),
              onChanged: _filter,
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filtered.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final code = _filtered[i];
                final name = currencyNames[code] ?? code;
                final isSelected = code == widget.selected;
                return InkWell(
                  onTap: () => Navigator.pop(context, code),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Text(code, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c.text)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(name, style: TextStyle(fontSize: 13, color: c.textSecondary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, size: 18, color: c.accent),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
