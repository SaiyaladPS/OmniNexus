import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class RecipeService {
  static const _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  Future<List<Recipe>> searchByIngredient(String ingredient) async {
    final trimmed = ingredient.trim();
    if (trimmed.isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/filter.php')
          .replace(queryParameters: {'i': trimmed});
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final meals = body['meals'] as List<dynamic>?;
        if (meals == null) return [];
        return meals
            .map((m) => Recipe.fromJson(m as Map<String, dynamic>))
            .where((r) => r.id.isNotEmpty)
            .toList();
      }
    } catch (_) {}

    return _mockRecipes(trimmed);
  }

  Future<Recipe?> getRecipeDetail(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/lookup.php')
          .replace(queryParameters: {'i': id});
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final meals = body['meals'] as List<dynamic>?;
        if (meals != null && meals.isNotEmpty) {
          return Recipe.fromJson(meals[0] as Map<String, dynamic>);
        }
      }
    } catch (_) {}

    return null;
  }

  List<Recipe> _mockRecipes(String query) {
    final q = query.toLowerCase();
    final results = _allMockRecipes.where((r) {
      final matchesIngredient = r.ingredients != null &&
          r.ingredients!
              .any((ing) => ing.toLowerCase().contains(q));
      return matchesIngredient || r.name.toLowerCase().contains(q);
    }).toList();
    if (results.isEmpty) return List.from(_allMockRecipes);
    return results;
  }
}

final recipeService = RecipeService();

const _allMockRecipes = [
  Recipe(
    id: 'mock:1',
    name: 'Classic Chicken Stir-Fry',
    thumbnail: 'https://placehold.co/400x300/F4A6A6/FFFFFF?text=Stir-Fry',
    category: 'Chicken',
    area: 'Asian',
    instructions:
        'Heat oil in a wok over high heat. Add chicken and stir-fry for 3 minutes. '
        'Add mixed vegetables and cook for 2 more minutes. '
        'Pour in soy sauce, add minced garlic and ginger. '
        'Stir everything together and serve hot over rice.',
    ingredients: [
      '500g Chicken breast',
      '2 tbsp Soy sauce',
      '3 cloves Garlic',
      '1 tbsp Ginger',
      '2 cups Mixed vegetables',
    ],
    estimatedCalories: 420,
  ),
  Recipe(
    id: 'mock:2',
    name: 'Fluffy Omelette',
    thumbnail: 'https://placehold.co/400x300/A3C4F3/FFFFFF?text=Omelette',
    category: 'Egg',
    area: 'American',
    instructions:
        'Beat eggs with salt and pepper. Melt butter in a non-stick pan over medium heat. '
        'Pour in eggs and let cook until edges are set. '
        'Sprinkle cheese and chives on one half, fold the other half over. '
        'Cook for 1 more minute and slide onto a plate.',
    ingredients: [
      '3 Eggs',
      '1 tbsp Butter',
      'Salt',
      'Pepper',
      '30g Cheese',
      '1 tbsp Chives',
    ],
    estimatedCalories: 320,
  ),
  Recipe(
    id: 'mock:3',
    name: 'Lemon Herb Grilled Chicken',
    thumbnail: 'https://placehold.co/400x300/A8E6CF/FFFFFF?text=Grilled+Chicken',
    category: 'Chicken',
    area: 'Mediterranean',
    instructions:
        'Marinate chicken thighs with lemon juice, olive oil, minced garlic, '
        'and chopped rosemary for at least 30 minutes. '
        'Grill over medium-high heat for 6 minutes per side until cooked through. '
        'Let rest for 5 minutes before serving.',
    ingredients: [
      '4 Chicken thighs',
      '2 Lemons',
      '3 cloves Garlic',
      'Fresh rosemary',
      '2 tbsp Olive oil',
    ],
    estimatedCalories: 380,
  ),
  Recipe(
    id: 'mock:4',
    name: 'Egg Fried Rice',
    thumbnail: 'https://placehold.co/400x300/FFD6A5/FFFFFF?text=Fried+Rice',
    category: 'Rice',
    area: 'Asian',
    instructions:
        'Scramble eggs in a wok with oil, then set aside. '
        'Stir-fry diced carrot and peas for 2 minutes. '
        'Add cold rice and soy sauce, stir-fry for 3 minutes. '
        'Return eggs to the wok, add chopped green onions, and toss together.',
    ingredients: [
      '3 Eggs',
      '3 cups Cooked rice',
      '2 tbsp Soy sauce',
      '3 Green onions',
      '1/2 cup Peas',
      '1 Carrot',
    ],
    estimatedCalories: 450,
  ),
  Recipe(
    id: 'mock:5',
    name: 'Chicken Caesar Salad',
    thumbnail: 'https://placehold.co/400x300/B5EAD7/FFFFFF?text=Caesar+Salad',
    category: 'Salad',
    area: 'American',
    ingredients: [
      '200g Chicken breast',
      '1 head Lettuce',
      '30g Parmesan',
      '1/2 cup Croutons',
      '3 tbsp Caesar dressing',
    ],
    estimatedCalories: 280,
  ),
  Recipe(
    id: 'mock:6',
    name: 'Spaghetti Carbonara',
    thumbnail: 'https://placehold.co/400x300/FFB7B2/FFFFFF?text=Carbonara',
    category: 'Pasta',
    area: 'Italian',
    instructions:
        'Cook spaghetti in salted boiling water until al dente. '
        'Meanwhile, fry pancetta until crispy. '
        'Beat eggs with grated Parmesan and black pepper. '
        'Toss hot pasta with pancetta, then quickly stir in the egg mixture '
        'off the heat until creamy. Serve immediately.',
    ingredients: [
      '400g Spaghetti',
      '3 Eggs',
      '150g Pancetta',
      '100g Parmesan',
      'Black pepper',
    ],
    estimatedCalories: 620,
  ),
];
