enum RecycleCategory {
  plastic,
  metal,
  paper,
  glass,
  organic,
  electronic,
  hazardous,
  other;

  String get label {
    switch (this) {
      case RecycleCategory.plastic: return 'Plastic';
      case RecycleCategory.metal: return 'Metal';
      case RecycleCategory.paper: return 'Paper';
      case RecycleCategory.glass: return 'Glass';
      case RecycleCategory.organic: return 'Organic';
      case RecycleCategory.electronic: return 'E-Waste';
      case RecycleCategory.hazardous: return 'Hazardous';
      case RecycleCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case RecycleCategory.plastic: return '🧴';
      case RecycleCategory.metal: return '🥫';
      case RecycleCategory.paper: return '📄';
      case RecycleCategory.glass: return '🥛';
      case RecycleCategory.organic: return '🥬';
      case RecycleCategory.electronic: return '🔌';
      case RecycleCategory.hazardous: return '☣️';
      case RecycleCategory.other: return '📦';
    }
  }
}

class RecycleItem {
  final String name;
  final String nameEn;
  final RecycleCategory category;
  final String description;
  final bool recyclable;
  final String instruction;
  final String? decomposeYears;
  final String emoji;

  const RecycleItem({
    required this.name,
    required this.nameEn,
    required this.category,
    required this.description,
    required this.recyclable,
    required this.instruction,
    this.decomposeYears,
    this.emoji = '🗑️',
  });

  String get categoryLabel => category.label;
  String get categoryEmoji => category.emoji;
}
