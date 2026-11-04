import 'package:flutter/material.dart';

enum StockBadgeType {
  adequate,     // \u2713 Checkmark (Green)
  insufficient, // ! Exclamation (Amber)
  missing       // \u00d7 Cross (Red)
}

class IngredientStockStatus {
  final String ingredientName;
  final double requiredAmount;
  final String requiredUnit;
  final double pantryAmount;
  final String pantryUnit;
  final StockBadgeType badgeType;
  final double difference; // positive = surplus, negative = deficit

  IngredientStockStatus({
    required this.ingredientName,
    required this.requiredAmount,
    required this.requiredUnit,
    required this.pantryAmount,
    required this.pantryUnit,
    required this.badgeType,
    required this.difference,
  });

  String get badgeSymbol {
    switch (badgeType) {
      case StockBadgeType.adequate:
        return '✓';
      case StockBadgeType.insufficient:
        return '!';
      case StockBadgeType.missing:
        return '×';
    }
  }

  Color get badgeColor {
    switch (badgeType) {
      case StockBadgeType.adequate:
        return const Color(0xFF10B981); // Emerald Green
      case StockBadgeType.insufficient:
        return const Color(0xFFF59E0B); // Amber
      case StockBadgeType.missing:
        return const Color(0xFFEF4444); // Red
    }
  }

  String get label {
    switch (badgeType) {
      case StockBadgeType.adequate:
        return 'Adequate';
      case StockBadgeType.insufficient:
        return 'Insufficient';
      case StockBadgeType.missing:
        return 'Missing';
    }
  }

  String get description {
    switch (badgeType) {
      case StockBadgeType.adequate:
        return 'In stock: $pantryAmount $pantryUnit (Needs $requiredAmount $requiredUnit)';
      case StockBadgeType.insufficient:
        return 'Only $pantryAmount $pantryUnit in stock (Short by ${(-difference).toStringAsFixed(1)} $requiredUnit)';
      case StockBadgeType.missing:
        return '0 in pantry (Needs $requiredAmount $requiredUnit)';
    }
  }
}
