class Recipe {
  final String id;
  final String name;
  final String thumbnail;
  final String? category;
  final String? area;
  final String? instructions;
  final String? youtubeUrl;
  final List<String>? ingredients;
  final int estimatedCalories;

  const Recipe({
    required this.id,
    required this.name,
    required this.thumbnail,
    this.category,
    this.area,
    this.instructions,
    this.youtubeUrl,
    this.ingredients,
    required this.estimatedCalories,
  });

  String get areaLabel => area ?? 'Unknown';
  String get categoryLabel => category ?? 'Various';

  static int estimateCalories(String name, {String? category}) {
    final lower = '$name ${category ?? ''}'.toLowerCase();

    if (_hasAny(lower, [
      'salad', 'veggie', 'vegetable', 'light', 'raw', 'steamed',
      'broth', 'green', 'soup',
    ])) {
      return _hashInRange(name, 120, 280);
    }
    if (_hasAny(lower, [
      'grilled', 'baked', 'roasted', 'fish', 'seafood', 'lean',
      'chicken breast',
    ])) {
      return _hashInRange(name, 250, 420);
    }
    if (_hasAny(lower, [
      'chicken', 'turkey', 'pasta', 'rice', 'noodle', 'stir-fry',
      'curry', 'risotto', 'pilaf',
    ])) {
      return _hashInRange(name, 350, 520);
    }
    if (_hasAny(lower, [
      'beef', 'pork', 'lamb', 'burger', 'sandwich', 'wrap', 'pizza',
      'pie', 'creamy', 'cheese', 'sauce', 'gratin', 'lasagna',
      'casserole', 'stew',
    ])) {
      return _hashInRange(name, 450, 650);
    }
    if (_hasAny(lower, [
      'fried', 'cake', 'sweet', 'chocolate', 'dessert', 'cookie',
      'pastry', 'donut', 'doughnut', 'ice cream', 'cream', 'butter',
      'bacon', 'sausage', 'ribs', 'caramel', 'pancake', 'waffle',
      'brownie', 'pie',
    ])) {
      return _hashInRange(name, 500, 850);
    }

    return _hashInRange(name, 300, 450);
  }

  static bool _hasAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  static int _hashInRange(String seed, int min, int max) {
    final hash = seed.hashCode.abs();
    return min + (hash % (max - min + 1));
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final ingredients = <String>[];
    for (var i = 1; i <= 20; i++) {
      final ing = json['strIngredient$i']?.toString().trim() ?? '';
      final measure = json['strMeasure$i']?.toString().trim() ?? '';
      if (ing.isNotEmpty) {
        ingredients.add(measure.isNotEmpty ? '$measure $ing' : ing);
      }
    }

    final name = json['strMeal']?.toString() ?? 'Unknown Meal';
    final category = json['strCategory']?.toString();
    final area = json['strArea']?.toString();

    return Recipe(
      id: json['idMeal']?.toString() ?? '',
      name: name,
      thumbnail: json['strMealThumb']?.toString() ?? '',
      category: category,
      area: area,
      instructions: json['strInstructions']?.toString(),
      youtubeUrl: json['strYoutube']?.toString(),
      ingredients: ingredients.isNotEmpty ? ingredients : null,
      estimatedCalories: estimateCalories(name, category: category),
    );
  }

  Map<String, dynamic> toJson() => {
        'idMeal': id,
        'strMeal': name,
        'strMealThumb': thumbnail,
        'strCategory': category,
        'strArea': area,
        'strInstructions': instructions,
        'strYoutube': youtubeUrl,
        'estimatedCalories': estimatedCalories,
        if (ingredients != null)
          for (var i = 0; i < ingredients!.length; i++)
            'strIngredient${i + 1}': ingredients![i],
      };
}
