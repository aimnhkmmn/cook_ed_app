import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import 'recipe_detail_screen.dart';

class SavedRecipesScreen extends StatelessWidget {
  const SavedRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final recipes = provider.savedRecipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Recipes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.refreshRecipes(),
          ),
        ],
      ),
      body: recipes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[500]),
                  const SizedBox(height: 16),
                  Text(
                    'No saved recipes yet!',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paste a TikTok, Reels, or Shorts link to ingest recipes.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      provider.setCurrentRecipe(recipe);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(recipe: recipe),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentOrange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  recipe.sourcePlatform,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentOrange,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.people_alt_outlined, size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                '${recipe.defaultServings} Pax',
                                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.timer_outlined, size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                '${recipe.prepTimeMinutes + recipe.cookTimeMinutes}m',
                                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            recipe.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${recipe.ingredients.length} ingredients • ${recipe.instructions.length} steps',
                            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
