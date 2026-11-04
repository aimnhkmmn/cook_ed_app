import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../../models/pantry_item.dart';
import '../../models/recipe.dart';
import '../../models/ingredient.dart';
import '../../models/cooking_step.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  bool _isInitialized = false;

  // In-memory demo store for testing without live Supabase credentials
  final List<PantryItem> _mockPantry = [];
  final List<Recipe> _mockRecipes = [];
  String? _demoUserId = 'demo-user-123';
  String? _demoEmail = 'chef@cook-ed.app';

  bool get isLiveSupabase => _isInitialized && _client != null;
  String? get currentUserId => isLiveSupabase ? _client?.auth.currentUser?.id : _demoUserId;
  String? get currentUserEmail => isLiveSupabase ? _client?.auth.currentUser?.email : _demoEmail;

  Future<void> initialize({String? customUrl, String? customKey}) async {
    final url = customUrl ?? AppConstants.supabaseUrl;
    final anonKey = customKey ?? AppConstants.supabaseAnonKey;

    if (url.contains('your-project') || anonKey.contains('your-anon-key')) {
      debugPrint('[SupabaseService] Using Mock / Offline Demo Mode.');
      _initMockData();
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      debugPrint('[SupabaseService] Connected to live Supabase project: $url');
    } catch (e) {
      debugPrint('[SupabaseService] Live connection failed ($e). Falling back to Offline Demo Mode.');
      _initMockData();
    }
  }

  void _initMockData() {
    if (_mockPantry.isNotEmpty) return;
    final now = DateTime.now();
    _mockPantry.addAll([
      PantryItem(
        id: const Uuid().v4(),
        userId: _demoUserId!,
        name: 'Chicken Breast',
        category: 'Meat & Seafood',
        quantity: 800.0,
        unit: 'g',
        createdAt: now,
      ),
      PantryItem(
        id: const Uuid().v4(),
        userId: _demoUserId!,
        name: 'Garlic',
        category: 'Produce',
        quantity: 10.0,
        unit: 'cloves',
        createdAt: now,
      ),
      PantryItem(
        id: const Uuid().v4(),
        userId: _demoUserId!,
        name: 'Yellow Onion',
        category: 'Produce',
        quantity: 3.0,
        unit: 'pcs',
        createdAt: now,
      ),
      PantryItem(
        id: const Uuid().v4(),
        userId: _demoUserId!,
        name: 'Olive Oil',
        category: 'Pantry & Dry Goods',
        quantity: 500.0,
        unit: 'ml',
        createdAt: now,
      ),
      PantryItem(
        id: const Uuid().v4(),
        userId: _demoUserId!,
        name: 'Soy Sauce',
        category: 'Pantry & Dry Goods',
        quantity: 300.0,
        unit: 'ml',
        createdAt: now,
      ),
      PantryItem(
        id: const Uuid().v4(),
        userId: _demoUserId!,
        name: 'Eggs',
        category: 'Dairy & Eggs',
        quantity: 12.0,
        unit: 'pcs',
        createdAt: now,
      ),
      PantryItem(
        id: const Uuid().v4(),
        userId: _demoUserId!,
        name: 'Heavy Cream',
        category: 'Dairy & Eggs',
        quantity: 150.0,
        unit: 'ml',
        createdAt: now,
      ),
      PantryItem(
        id: const Uuid().v4(),
        userId: _demoUserId!,
        name: 'Black Pepper',
        category: 'Spices & Seasonings',
        quantity: 50.0,
        unit: 'g',
        createdAt: now,
      ),
    ]);

    // Seed sample ingested recipe
    _mockRecipes.add(Recipe(
      id: const Uuid().v4(),
      userId: _demoUserId!,
      title: 'Creamy Garlic Butter Chicken',
      description: 'Quick viral TikTok weeknight skillet dinner with rich garlic sauce.',
      videoUrl: 'https://www.tiktok.com/@quickcooking/video/723456789',
      sourcePlatform: 'TikTok',
      defaultServings: 2,
      prepTimeMinutes: 10,
      cookTimeMinutes: 15,
      ingredients: [
        Ingredient(name: 'Chicken Breast', amount: 400.0, unit: 'g', category: 'Meat & Seafood'),
        Ingredient(name: 'Garlic', amount: 4.0, unit: 'cloves', category: 'Produce'),
        Ingredient(name: 'Olive Oil', amount: 30.0, unit: 'ml', category: 'Pantry & Dry Goods'),
        Ingredient(name: 'Heavy Cream', amount: 200.0, unit: 'ml', category: 'Dairy & Eggs'),
        Ingredient(name: 'Parmesan Cheese', amount: 50.0, unit: 'g', category: 'Dairy & Eggs'),
      ],
      instructions: [
        CookingStep(stepNumber: 1, instruction: 'Slice chicken breasts into cutlets and season with salt and pepper.'),
        CookingStep(stepNumber: 2, instruction: 'Heat olive oil in a skillet over medium-high heat and sear chicken for 5 minutes per side until golden.'),
        CookingStep(stepNumber: 3, instruction: 'Add minced garlic and sauté for 1 minute until fragrant.'),
        CookingStep(stepNumber: 4, instruction: 'Pour in heavy cream and grated parmesan. Simmer for 3 minutes until thickened.'),
        CookingStep(stepNumber: 5, instruction: 'Return chicken to sauce, spoon sauce over cutlets, and serve warm!'),
      ],
      createdAt: now,
    ));
  }

  // --- Auth Operations ---
  Future<void> signIn({required String email, required String password}) async {
    if (isLiveSupabase) {
      await _client!.auth.signInWithPassword(email: email, password: password);
    } else {
      _demoEmail = email;
      _demoUserId = 'user_${email.hashCode}';
    }
  }

  Future<void> signUp({required String email, required String password, String? fullName}) async {
    if (isLiveSupabase) {
      await _client!.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName ?? email.split('@').first},
      );
    } else {
      _demoEmail = email;
      _demoUserId = 'user_${email.hashCode}';
    }
  }

  Future<void> signOut() async {
    if (isLiveSupabase) {
      await _client!.auth.signOut();
    } else {
      _demoUserId = null;
      _demoEmail = null;
    }
  }

  // --- Pantry CRUD Operations ---
  Future<List<PantryItem>> fetchPantryItems() async {
    if (isLiveSupabase) {
      final res = await _client!
          .from('pantry_items')
          .select()
          .order('name', ascending: true);
      return (res as List).map((map) => PantryItem.fromMap(map)).toList();
    } else {
      return List.unmodifiable(_mockPantry);
    }
  }

  Future<void> addPantryItem(PantryItem item) async {
    if (isLiveSupabase) {
      await _client!.from('pantry_items').insert(item.toMap());
    } else {
      _mockPantry.add(item);
    }
  }

  Future<void> updatePantryQuantity(String itemId, double newQuantity) async {
    if (isLiveSupabase) {
      await _client!.from('pantry_items').update({
        'quantity': newQuantity,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', itemId);
    } else {
      final index = _mockPantry.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        _mockPantry[index] = _mockPantry[index].copyWith(quantity: newQuantity);
      }
    }
  }

  Future<void> deletePantryItem(String itemId) async {
    if (isLiveSupabase) {
      await _client!.from('pantry_items').delete().eq('id', itemId);
    } else {
      _mockPantry.removeWhere((i) => i.id == itemId);
    }
  }

  Future<void> batchAddPantryItems(List<PantryItem> items) async {
    if (isLiveSupabase) {
      await _client!.from('pantry_items').insert(items.map((i) => i.toMap()).toList());
    } else {
      _mockPantry.addAll(items);
    }
  }

  // --- Recipe Operations ---
  Future<List<Recipe>> fetchSavedRecipes() async {
    if (isLiveSupabase) {
      final res = await _client!
          .from('recipes')
          .select()
          .order('created_at', ascending: false);
      return (res as List).map((map) => Recipe.fromMap(map)).toList();
    } else {
      return List.unmodifiable(_mockRecipes);
    }
  }

  Future<void> saveRecipe(Recipe recipe) async {
    if (isLiveSupabase) {
      await _client!.from('recipes').insert(recipe.toMap());
    } else {
      _mockRecipes.insert(0, recipe);
    }
  }

  // --- Meal Confirmation & Atomic Stock Deduction ---
  Future<Map<String, dynamic>> deductPantryStock({
    required String recipeTitle,
    String? recipeId,
    required int servings,
    required List<Map<String, dynamic>> items,
  }) async {
    if (isLiveSupabase) {
      final res = await _client!.rpc('deduct_pantry_stock', params: {
        'p_user_id': currentUserId,
        'p_recipe_id': recipeId,
        'p_recipe_title': recipeTitle,
        'p_servings': servings,
        'p_items': items,
      });
      return Map<String, dynamic>.from(res);
    } else {
      // Local Mock atomic transaction
      int deductedCount = 0;
      for (final item in items) {
        final name = (item['name']?.toString() ?? '').toLowerCase().trim();
        final amount = (item['amount'] is num) ? (item['amount'] as num).toDouble() : 0.0;
        if (name.isEmpty || amount <= 0) continue;

        final matchIndex = _mockPantry.indexWhere((p) =>
            p.normalizedName == name ||
            name.contains(p.normalizedName) ||
            p.normalizedName.contains(name));

        if (matchIndex != -1) {
          final existing = _mockPantry[matchIndex];
          final newQty = (existing.quantity - amount).clamp(0.0, double.infinity);
          _mockPantry[matchIndex] = existing.copyWith(quantity: newQty);
          deductedCount++;
        }
      }
      return {
        'success': true,
        'deducted_items_count': deductedCount,
        'details': 'Deducted $deductedCount items from virtual pantry.'
      };
    }
  }
}
