import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/services/supabase_service.dart';
import '../core/services/api_service.dart';
import '../models/pantry_item.dart';
import '../models/recipe.dart';
import '../models/stock_status.dart';
import '../models/receipt_item.dart';

class AppProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  final ApiService _api = ApiService();

  // State Variables
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<PantryItem> _pantryItems = [];
  List<Recipe> _savedRecipes = [];
  Recipe? _currentRecipe;
  int _targetServings = 2;

  // Video ingestion pipeline states
  String _ingestStatusText = '';
  double _ingestProgress = 0.0;
  bool _isIngesting = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  List<PantryItem> get pantryItems => _pantryItems;
  List<Recipe> get savedRecipes => _savedRecipes;
  Recipe? get currentRecipe => _currentRecipe;
  int get targetServings => _targetServings;
  bool get isIngesting => _isIngesting;
  String get ingestStatusText => _ingestStatusText;
  double get ingestProgress => _ingestProgress;
  String get backendUrl => _api.baseUrl;
  bool get isLiveSupabase => _supabase.isLiveSupabase;
  String? get currentUserEmail => _supabase.currentUserEmail;

  set backendUrl(String url) {
    _api.baseUrl = url;
    notifyListeners();
  }

  // Filtered Pantry Items
  List<PantryItem> get filteredPantryItems {
    return _pantryItems.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Current Stock Status Breakdown for Current Recipe
  List<IngredientStockStatus> get currentStockStatus {
    if (_currentRecipe == null) return [];
    return _api.checkStock(
      recipe: _currentRecipe!,
      targetServings: _targetServings,
      pantryItems: _pantryItems,
    );
  }

  bool get areAllIngredientsAdequate {
    final statusList = currentStockStatus;
    if (statusList.isEmpty) return false;
    return statusList.every((s) => s.badgeType == StockBadgeType.adequate);
  }

  // --- Initializer ---
  Future<void> initialize() async {
    _setLoading(true);
    await _supabase.initialize();
    await refreshPantry();
    await refreshRecipes();
    _setLoading(false);
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTargetServings(int servings) {
    if (servings > 0 && servings <= 50) {
      _targetServings = servings;
      notifyListeners();
    }
  }

  void setCurrentRecipe(Recipe recipe) {
    _currentRecipe = recipe;
    _targetServings = recipe.defaultServings;
    notifyListeners();
  }

  // --- Pantry Actions ---
  Future<void> refreshPantry() async {
    try {
      _pantryItems = await _supabase.fetchPantryItems();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load pantry: $e';
      notifyListeners();
    }
  }

  Future<void> addPantryItem({
    required String name,
    required double quantity,
    required String unit,
    String category = 'Other',
  }) async {
    final newItem = PantryItem(
      id: const Uuid().v4(),
      userId: _supabase.currentUserId ?? 'user',
      name: name,
      quantity: quantity,
      unit: unit,
      category: category,
      createdAt: DateTime.now(),
    );
    await _supabase.addPantryItem(newItem);
    await refreshPantry();
  }

  Future<void> updateItemQuantity(String itemId, double newQuantity) async {
    await _supabase.updatePantryQuantity(itemId, newQuantity);
    await refreshPantry();
  }

  Future<void> deletePantryItem(String itemId) async {
    await _supabase.deletePantryItem(itemId);
    await refreshPantry();
  }

  Future<void> addReceiptItems(List<ReceiptScannedItem> items) async {
    final List<PantryItem> toAdd = [];
    final now = DateTime.now();

    for (final scanned in items) {
      if (scanned.isSelected) {
        toAdd.add(PantryItem(
          id: const Uuid().v4(),
          userId: _supabase.currentUserId ?? 'user',
          name: scanned.name,
          quantity: scanned.quantity,
          unit: scanned.unit,
          category: scanned.category,
          createdAt: now,
        ));
      }
    }

    if (toAdd.isNotEmpty) {
      await _supabase.batchAddPantryItems(toAdd);
      await refreshPantry();
    }
  }

  // --- Receipt OCR Action ---
  Future<List<ReceiptScannedItem>> scanReceiptImage(Uint8List bytes) async {
    _setLoading(true);
    try {
      final items = await _api.scanReceipt(imageBytes: bytes);
      _setLoading(false);
      return items;
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Receipt scan error: $e';
      notifyListeners();
      return [];
    }
  }

  // --- Video Recipe Ingestion Action ---
  Future<Recipe?> ingestVideoUrl(String url) async {
    _isIngesting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Downloading Audio
      _ingestStatusText = 'Extracting audio from video (yt-dlp)...';
      _ingestProgress = 0.3;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 600));

      // Step 2: Speech-to-Text
      _ingestStatusText = 'Transcribing spoken dialogue (Whisper AI)...';
      _ingestProgress = 0.65;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 600));

      // Step 3: Structuring with Gemini Flash
      _ingestStatusText = 'Structuring ingredients & steps (Gemini Flash)...';
      _ingestProgress = 0.9;
      notifyListeners();

      final recipe = await _api.ingestVideo(url);
      _currentRecipe = recipe;
      _targetServings = recipe.defaultServings;

      // Automatically add to saved recipes
      await _supabase.saveRecipe(recipe);
      await refreshRecipes();

      _ingestStatusText = 'Recipe ready!';
      _ingestProgress = 1.0;
      _isIngesting = false;
      notifyListeners();
      return recipe;
    } catch (e) {
      _isIngesting = false;
      _errorMessage = 'Failed to ingest video: $e';
      notifyListeners();
      return null;
    }
  }

  // --- Saved Recipes Actions ---
  Future<void> refreshRecipes() async {
    try {
      _savedRecipes = await _supabase.fetchSavedRecipes();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching recipes: $e');
    }
  }

  // --- Meal Confirmation & Atomic Stock Deduction ---
  Future<Map<String, dynamic>> confirmMealAndDeductStock({Recipe? recipe, int? servings}) async {
    final targetRecipe = recipe ?? _currentRecipe;
    final targetCount = servings ?? _targetServings;

    if (targetRecipe == null) {
      return {'success': false, 'message': 'No recipe selected'};
    }

    _setLoading(true);
    try {
      final defaultServings = targetRecipe.defaultServings > 0 ? targetRecipe.defaultServings : 2;
      final scaleFactor = targetCount / defaultServings;
      final deductionItems = targetRecipe.ingredients.map((ing) {
        return {
          'name': ing.name,
          'amount': double.parse((ing.amount * scaleFactor).toStringAsFixed(1)),
          'unit': ing.unit,
        };
      }).toList();

      final result = await _supabase.deductPantryStock(
        recipeTitle: targetRecipe.title,
        recipeId: targetRecipe.id,
        servings: targetCount,
        items: deductionItems,
      );

      // Refresh pantry inventory immediately to reflect new balances
      await refreshPantry();
      _setLoading(false);
      return result;
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'message': 'Deduction failed: $e'};
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
