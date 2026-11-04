import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConstants {
  // App Info
  static const String appName = 'Cook-Ed';
  static const String appTagline = 'From Viral Videos to Zero-Waste Kitchens';

  // Supabase Configuration
  // Paste your Supabase project credentials here or set in the Settings screen
  static const String supabaseUrl = 'https://rrkucbkertnepjjmvdfj.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_yVVwW6e3TuX-PlRmY3pb9Q_8YWRQDqL';

  // FastAPI Backend URL
  // Android Emulator uses 10.0.2.2 to access host machine localhost.
  // Physical device or Web uses local machine IP (e.g., http://192.168.1.x:8000) or localhost.
  static String get defaultBackendUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://localhost:8000';
    }
  }

  // Pantry Categories
  static const List<String> pantryCategories = [
    'All',
    'Produce',
    'Meat & Seafood',
    'Dairy & Eggs',
    'Pantry & Dry Goods',
    'Spices & Seasonings',
    'Canned Goods',
    'Other',
  ];

  // Standard Units
  static const List<String> standardUnits = [
    'g',
    'kg',
    'ml',
    'l',
    'pcs',
    'cloves',
    'tbsp',
    'tsp',
    'cup',
    'pack',
  ];
}
