import 'ingredient.dart';
import 'cooking_step.dart';

class Recipe {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String videoUrl;
  final String sourcePlatform;
  final int defaultServings;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final List<Ingredient> ingredients;
  final List<CookingStep> instructions;
  final DateTime? createdAt;

  Recipe({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.videoUrl = '',
    this.sourcePlatform = 'Social Video',
    this.defaultServings = 2,
    this.prepTimeMinutes = 15,
    this.cookTimeMinutes = 20,
    required this.ingredients,
    required this.instructions,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'source_platform': sourcePlatform,
      'default_servings': defaultServings,
      'prep_time_minutes': prepTimeMinutes,
      'cook_time_minutes': cookTimeMinutes,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
      'instructions': instructions.map((s) => s.toMap()).toList(),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    var rawIngredients = map['ingredients'];
    List<Ingredient> parsedIngredients = [];
    if (rawIngredients is List) {
      parsedIngredients = rawIngredients
          .map((i) => Ingredient.fromMap(Map<String, dynamic>.from(i)))
          .toList();
    }

    var rawInstructions = map['instructions'];
    List<CookingStep> parsedInstructions = [];
    if (rawInstructions is List) {
      parsedInstructions = rawInstructions
          .map((s) => CookingStep.fromMap(Map<String, dynamic>.from(s)))
          .toList();
    }

    return Recipe(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled Recipe',
      description: map['description']?.toString() ?? '',
      videoUrl: map['video_url']?.toString() ?? '',
      sourcePlatform: map['source_platform']?.toString() ?? 'Social Video',
      defaultServings: (map['default_servings'] is int)
          ? map['default_servings']
          : int.tryParse(map['default_servings']?.toString() ?? '2') ?? 2,
      prepTimeMinutes: (map['prep_time_minutes'] is int)
          ? map['prep_time_minutes']
          : int.tryParse(map['prep_time_minutes']?.toString() ?? '15') ?? 15,
      cookTimeMinutes: (map['cook_time_minutes'] is int)
          ? map['cook_time_minutes']
          : int.tryParse(map['cook_time_minutes']?.toString() ?? '20') ?? 20,
      ingredients: parsedIngredients,
      instructions: parsedInstructions,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }
}
