import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recipe.dart';

class FavoriteService {
  Box<String>? _box;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init() async {
    _box = await Hive.openBox<String>('recipe_favorites');
    _ready = true;
  }

  String get _favoritesJson =>
      _box?.get('favorites', defaultValue: '[]') ?? '[]';

  set _favoritesJson(String v) => _box?.put('favorites', v);

  List<Recipe> getAll() {
    if (!_ready) return [];
    final list = json.decode(_favoritesJson) as List<dynamic>;
    return list
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  bool isFavorite(String id) {
    if (!_ready) return false;
    final all = getAll();
    return all.any((r) => r.id == id);
  }

  Future<void> toggle(Recipe recipe) async {
    if (!_ready) return;
    final all = getAll();
    final idx = all.indexWhere((r) => r.id == recipe.id);
    if (idx >= 0) {
      all.removeAt(idx);
    } else {
      all.add(recipe);
    }
    _favoritesJson = json.encode(all.map((r) => r.toJson()).toList());
  }
}

final favoriteService = FavoriteService();
