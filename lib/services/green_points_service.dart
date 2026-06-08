import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class GreenPointRecord {
  final String id;
  final String itemName;
  final int points;
  final DateTime date;
  final String category;

  GreenPointRecord({
    required this.id,
    required this.itemName,
    required this.points,
    required this.date,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemName': itemName,
    'points': points,
    'date': date.toIso8601String(),
    'category': category,
  };

  factory GreenPointRecord.fromJson(Map<String, dynamic> json) => GreenPointRecord(
    id: json['id']?.toString() ?? '',
    itemName: json['itemName']?.toString() ?? '',
    points: json['points'] as int? ?? 0,
    date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    category: json['category']?.toString() ?? '',
  );
}

class GreenPointsService extends ChangeNotifier {
  static const _boxName = 'green_points';
  Box<String>? _box;
  bool _ready = false;
  int _totalPoints = 0;
  int _recyclingCount = 0;
  List<GreenPointRecord> _history = [];

  bool get ready => _ready;
  int get totalPoints => _totalPoints;
  int get recyclingCount => _recyclingCount;
  List<GreenPointRecord> get history => _history;

  Future<void> init() async {
    try {
      _box = await Hive.openBox<String>(_boxName);
      _load();
      _ready = true;
    } catch (_) {}
  }

  void _load() {
    final pts = _box?.get('total_points');
    _totalPoints = int.tryParse(pts ?? '') ?? 0;

    final cnt = _box?.get('recycling_count');
    _recyclingCount = int.tryParse(cnt ?? '') ?? 0;

    final raw = _box?.get('history');
    if (raw != null) {
      final list = json.decode(raw) as List;
      _history = list.map((e) => GreenPointRecord.fromJson(e as Map<String, dynamic>)).toList();
    }
    notifyListeners();
  }

  void _save() {
    _box?.put('total_points', _totalPoints.toString());
    _box?.put('recycling_count', _recyclingCount.toString());
    _box?.put('history', json.encode(_history.map((r) => r.toJson()).toList()));
    notifyListeners();
  }

  void addRecord(String itemName, String category, {int points = 10}) {
    _totalPoints += points;
    _recyclingCount++;
    _history.insert(
      0,
      GreenPointRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itemName: itemName,
        points: points,
        date: DateTime.now(),
        category: category,
      ),
    );
    _save();
  }

  void reset() {
    _totalPoints = 0;
    _recyclingCount = 0;
    _history.clear();
    _save();
  }

  String get level {
    if (_totalPoints >= 500) return '🌍 Earth Guardian';
    if (_totalPoints >= 250) return '🌟 Eco Champion';
    if (_totalPoints >= 100) return '♻️ Recycling Pro';
    if (_totalPoints >= 50) return '🌱 Green Beginner';
    return '🌿 Newcomer';
  }

  double get nextLevelProgress {
    if (_totalPoints >= 500) return 1.0;
    if (_totalPoints >= 250) return (_totalPoints - 250) / 250;
    if (_totalPoints >= 100) return (_totalPoints - 100) / 150;
    if (_totalPoints >= 50) return (_totalPoints - 50) / 50;
    return _totalPoints / 50;
  }

  int get currentLevelThreshold {
    if (_totalPoints >= 500) return 500;
    if (_totalPoints >= 250) return 250;
    if (_totalPoints >= 100) return 100;
    if (_totalPoints >= 50) return 50;
    return 0;
  }

  int get nextLevelThreshold {
    if (_totalPoints >= 500) return 500;
    if (_totalPoints >= 250) return 500;
    if (_totalPoints >= 100) return 250;
    if (_totalPoints >= 50) return 100;
    return 50;
  }
}

final greenPointsService = GreenPointsService();
