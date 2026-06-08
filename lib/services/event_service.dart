import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CalendarEvent {
  final String id;
  final String title;
  final DateTime dateTime;
  final String? notes;
  final String? city;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    this.notes,
    this.city,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'dateTime': dateTime.toIso8601String(),
    'notes': notes,
    'city': city,
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
    id: json['id'] as String,
    title: json['title'] as String,
    dateTime: DateTime.parse(json['dateTime'] as String),
    notes: json['notes'] as String?,
    city: json['city'] as String?,
  );
}

class EventService {
  Box<String>? _box;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init() async {
    _box = await Hive.openBox<String>('calendar_events');
    _ready = true;
  }

  List<CalendarEvent> getAll() {
    if (!_ready) return [];
    final raw = _box?.get('events', defaultValue: '[]') ?? '[]';
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<CalendarEvent> getUpcoming({int limit = 10}) {
    final all = getAll();
    final now = DateTime.now();
    return all.where((e) => e.dateTime.isAfter(now)).take(limit).toList();
  }

  Future<void> add(CalendarEvent event) async {
    if (!_ready) return;
    final all = getAll();
    all.add(event);
    _save(all);
  }

  Future<void> remove(String id) async {
    if (!_ready) return;
    final all = getAll();
    all.removeWhere((e) => e.id == id);
    _save(all);
  }

  void _save(List<CalendarEvent> events) {
    _box?.put('events', json.encode(events.map((e) => e.toJson()).toList()));
  }
}

final eventService = EventService();
