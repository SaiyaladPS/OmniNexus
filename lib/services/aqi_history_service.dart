import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AqiRecord {
  final DateTime date;
  final int aqi;
  final double? pm25;
  final double? pm10;
  final String city;

  AqiRecord({
    required this.date,
    required this.aqi,
    this.pm25,
    this.pm10,
    required this.city,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'aqi': aqi,
    'pm25': pm25,
    'pm10': pm10,
    'city': city,
  };

  factory AqiRecord.fromJson(Map<String, dynamic> json) => AqiRecord(
    date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    aqi: json['aqi'] as int? ?? 0,
    pm25: (json['pm25'] as num?)?.toDouble(),
    pm10: (json['pm10'] as num?)?.toDouble(),
    city: json['city']?.toString() ?? '',
  );
}

class AqiHistoryService extends ChangeNotifier {
  static const _boxName = 'aqi_history';
  Box<String>? _box;
  bool _ready = false;
  List<AqiRecord> _records = [];

  bool get ready => _ready;
  List<AqiRecord> get records => _records;

  Future<void> init() async {
    try {
      _box = await Hive.openBox<String>(_boxName);
      _load();
      _ready = true;
    } catch (_) {}
  }

  void _load() {
    final raw = _box?.get('records');
    if (raw == null) { _records = []; return; }
    final list = json.decode(raw) as List;
    _records = list.map((e) => AqiRecord.fromJson(e as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  void _save() {
    _box?.put('records', json.encode(_records.map((r) => r.toJson()).toList()));
    notifyListeners();
  }

  void addRecord(AqiRecord record) {
    _records.insert(0, record);
    if (_records.length > 30) _records = _records.sublist(0, 30);
    _save();
  }

  void clear() {
    _records.clear();
    _save();
  }
}

final aqiHistoryService = AqiHistoryService();
