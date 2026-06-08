import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/currency_rates.dart';

class CurrencyHistoryService {
  Box<String>? _box;
  bool _ready = false;

  bool get isReady => _ready;
  static const _maxRecords = 20;

  Future<void> init() async {
    _box = await Hive.openBox<String>('currency_history');
    _ready = true;
  }

  String get _historyJson =>
      _box?.get('history', defaultValue: '[]') ?? '[]';

  set _historyJson(String v) => _box?.put('history', v);

  List<CurrencyRecord> getAll() {
    if (!_ready) return [];
    final list = json.decode(_historyJson) as List<dynamic>;
    return list
        .map((e) => CurrencyRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addRecord(CurrencyRecord record) async {
    if (!_ready) return;
    final all = getAll();
    all.insert(0, record);
    while (all.length > _maxRecords) { all.removeLast(); }
    _historyJson = json.encode(all.map((r) => r.toJson()).toList());
  }

  Future<void> clear() async {
    if (!_ready) return;
    _historyJson = '[]';
  }
}

final currencyHistoryService = CurrencyHistoryService();
