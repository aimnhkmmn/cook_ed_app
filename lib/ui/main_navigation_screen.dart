import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'pantry/pantry_screen.dart';
import 'recipe/video_ingest_screen.dart';
import 'recipe/saved_recipes_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PantryScreen(),
    VideoIngestScreen(),
    SavedRecipesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        indicatorColor: AppTheme.primaryGreen.withValues(alpha: 0.25),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen_rounded, color: AppTheme.primaryGreen),
            label: 'Pantry',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library_rounded, color: AppTheme.primaryGreen),
            label: 'Ingest Video',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded, color: AppTheme.primaryGreen),
            label: 'Saved Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded, color: AppTheme.primaryGreen),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
