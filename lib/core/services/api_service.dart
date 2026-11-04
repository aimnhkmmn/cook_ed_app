import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../../models/recipe.dart';
import '../../models/ingredient.dart';
import '../../models/cooking_step.dart';
import '../../models/receipt_item.dart';
import '../../models/pantry_item.dart';
import '../../models/stock_status.dart';

class ApiService {
  String _baseUrl = AppConstants.defaultBackendUrl;

  String get baseUrl => _baseUrl;
  set baseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // --- Video Recipe Ingestion ---
  Future<Recipe> ingestVideo(String url) async {
    final endpoint = Uri.parse('$_baseUrl/api/recipe/ingest-video');
    try {
      final response = await http
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'url': url}),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Recipe.fromMap(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Video ingestion failed');
      }
    } catch (e) {
      debugPrint(
        '[ApiService] Backend call failed: $e. Falling back to realistic simulation.',
      );
      // Graceful realistic fallback if backend is not running yet
      return _generateSimulatedRecipe(url);
    }
  }

  // --- Receipt OCR Scanning ---
  Future<List<ReceiptScannedItem>> scanReceipt({
    required Uint8List imageBytes,
    String filename = 'receipt.jpg',
  }) async {
    final endpoint = Uri.parse('$_baseUrl/api/receipt/scan');
    try {
      final request = http.MultipartRequest('POST', endpoint);
      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 35),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List rawItems = data['items'] ?? [];
        return rawItems
            .map((item) => ReceiptScannedItem.fromMap(item))
            .toList();
      } else {
        throw Exception('Receipt OCR failed with code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(
        '[ApiService] Backend receipt OCR failed: $e. Using simulated receipt items.',
      );
      return _generateSimulatedReceiptItems();
    }
  }

  // --- Clientside & Serverside Portion Scaling & Stock Checking ---
  List<IngredientStockStatus> checkStock({
    required Recipe recipe,
    required int targetServings,
    required List<PantryItem> pantryItems,
  }) {
    final scaleFactor =
        targetServings /
        (recipe.defaultServings > 0 ? recipe.defaultServings : 2);
    final List<IngredientStockStatus> results = [];

    // Map pantry for fast case-insensitive lookup
    final Map<String, PantryItem> pantryMap = {};
    for (final p in pantryItems) {
      pantryMap[p.normalizedName] = p;
    }

    for (final ing in recipe.ingredients) {
      final scaledAmount = double.parse(
        (ing.amount * scaleFactor).toStringAsFixed(1),
      );
      final normName = ing.name.toLowerCase().trim();

      // Find matching item
      PantryItem? match;
      if (pantryMap.containsKey(normName)) {
        match = pantryMap[normName];
      } else {
        for (final entry in pantryMap.entries) {
          if (entry.key.contains(normName) || normName.contains(entry.key)) {
            match = entry.value;
            break;
          }
        }
      }

      if (match == null) {
        // Missing entirely \u00d7
        results.add(
          IngredientStockStatus(
            ingredientName: ing.name,
            requiredAmount: scaledAmount,
            requiredUnit: ing.unit,
            pantryAmount: 0.0,
            pantryUnit: ing.unit,
            badgeType: StockBadgeType.missing,
            difference: -scaledAmount,
          ),
        );
      } else {
        final pQty = match.quantity;
        final diff = double.parse((pQty - scaledAmount).toStringAsFixed(1));

        StockBadgeType badge;
        if (pQty >= scaledAmount) {
          badge = StockBadgeType.adequate; // \u2713
        } else if (pQty > 0) {
          badge = StockBadgeType.insufficient; // !
        } else {
          badge = StockBadgeType.missing; // \u00d7
        }

        results.add(
          IngredientStockStatus(
            ingredientName: ing.name,
            requiredAmount: scaledAmount,
            requiredUnit: ing.unit,
            pantryAmount: pQty,
            pantryUnit: match.unit,
            badgeType: badge,
            difference: diff,
          ),
        );
      }
    }

    return results;
  }

  // Realistic mock data if testing without live server
  Recipe _generateSimulatedRecipe(String url) {
    final isPasta =
        url.toLowerCase().contains('pasta') ||
        url.toLowerCase().contains('spaghetti');
    return Recipe(
      id: const Uuid().v4(),
      userId: 'user',
      title: isPasta
          ? 'Garlic Butter Spaghetti Aglio e Olio'
          : 'Crispy Garlic Honey Glazed Chicken',
      description:
          'Ingested from short-form video. Parsed audio and dialogue into standardized proportions.',
      videoUrl: url,
      sourcePlatform: url.contains('tiktok')
          ? 'TikTok'
          : url.contains('instagram')
          ? 'Instagram Reels'
          : 'YouTube Shorts',
      defaultServings: 2,
      prepTimeMinutes: 10,
      cookTimeMinutes: 15,
      ingredients: isPasta
          ? [
              Ingredient(
                name: 'Spaghetti Pasta',
                amount: 300.0,
                unit: 'g',
                category: 'Pantry & Dry Goods',
              ),
              Ingredient(
                name: 'Garlic',
                amount: 6.0,
                unit: 'cloves',
                category: 'Produce',
              ),
              Ingredient(
                name: 'Olive Oil',
                amount: 60.0,
                unit: 'ml',
                category: 'Pantry & Dry Goods',
              ),
              Ingredient(
                name: 'Red Pepper Flakes',
                amount: 1.0,
                unit: 'tsp',
                category: 'Spices & Seasonings',
              ),
              Ingredient(
                name: 'Parsley',
                amount: 20.0,
                unit: 'g',
                category: 'Produce',
              ),
            ]
          : [
              Ingredient(
                name: 'Chicken Breast',
                amount: 500.0,
                unit: 'g',
                category: 'Meat & Seafood',
              ),
              Ingredient(
                name: 'Garlic',
                amount: 5.0,
                unit: 'cloves',
                category: 'Produce',
              ),
              Ingredient(
                name: 'Soy Sauce',
                amount: 45.0,
                unit: 'ml',
                category: 'Pantry & Dry Goods',
              ),
              Ingredient(
                name: 'Honey',
                amount: 30.0,
                unit: 'ml',
                category: 'Pantry & Dry Goods',
              ),
              Ingredient(
                name: 'Olive Oil',
                amount: 20.0,
                unit: 'ml',
                category: 'Pantry & Dry Goods',
              ),
            ],
      instructions: [
        CookingStep(
          stepNumber: 1,
          instruction: 'Prep all fresh ingredients and measure seasonings.',
        ),
        CookingStep(
          stepNumber: 2,
          instruction:
              'Heat oil in a pan over medium heat and gently sauté minced garlic until fragrant.',
        ),
        CookingStep(
          stepNumber: 3,
          instruction:
              'Combine main protein/pasta into the aromatics and toss thoroughly.',
        ),
        CookingStep(
          stepNumber: 4,
          instruction:
              'Simmer on low for 3 minutes until sauce is glossy and coats everything evenly.',
        ),
        CookingStep(
          stepNumber: 5,
          instruction:
              'Garnish with freshly chopped herbs and serve immediately.',
        ),
      ],
      createdAt: DateTime.now(),
    );
  }

  List<ReceiptScannedItem> _generateSimulatedReceiptItems() {
    return [
      ReceiptScannedItem(
        name: 'Chicken Breast Fillet',
        quantity: 600.0,
        unit: 'g',
        category: 'Meat & Seafood',
        estimatedPrice: 12.90,
      ),
      ReceiptScannedItem(
        name: 'Fresh Garlic Bulb',
        quantity: 5.0,
        unit: 'cloves',
        category: 'Produce',
        estimatedPrice: 2.50,
      ),
      ReceiptScannedItem(
        name: 'Yellow Onions (Net)',
        quantity: 3.0,
        unit: 'pcs',
        category: 'Produce',
        estimatedPrice: 3.20,
      ),
      ReceiptScannedItem(
        name: 'Extra Virgin Olive Oil 500ml',
        quantity: 500.0,
        unit: 'ml',
        category: 'Pantry & Dry Goods',
        estimatedPrice: 22.00,
      ),
      ReceiptScannedItem(
        name: 'Farm Fresh Eggs (10s)',
        quantity: 10.0,
        unit: 'pcs',
        category: 'Dairy & Eggs',
        estimatedPrice: 7.50,
      ),
    ];
  }
}
