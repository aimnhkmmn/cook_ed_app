import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recipe.dart';
import '../../models/stock_status.dart';
import '../../widgets/portion_selector.dart';
import '../../widgets/stock_badge.dart';
import 'meal_confirmation_dialog.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().setCurrentRecipe(widget.recipe);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final recipe = provider.currentRecipe ?? widget.recipe;
    final stockStatusList = provider.currentStockStatus;
    final targetServings = provider.targetServings;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recipe Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              color: Theme.of(context).cardTheme.color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.accentOrange),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_rounded, size: 14, color: AppTheme.accentOrange),
                            const SizedBox(width: 4),
                            Text(
                              recipe.sourcePlatform,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.prepTimeMinutes + recipe.cookTimeMinutes} mins',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    recipe.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  if (recipe.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      recipe.description,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Portion Scaling Controller (Pax Stepper)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PortionSelector(
                servings: targetServings,
                onServingsChanged: (val) => provider.setTargetServings(val),
              ),
            ),
            const SizedBox(height: 16),

            // Ingredients Header with Stock Readiness Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Ingredients',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${recipe.ingredients.length})',
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  // Readiness indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: provider.areAllIngredientsAdequate
                          ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                          : AppTheme.accentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      provider.areAllIngredientsAdequate
                          ? '✓ 100% Stocked'
                          : '! Review Stock',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: provider.areAllIngredientsAdequate
                            ? AppTheme.primaryGreen
                            : AppTheme.accentAmber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Ingredients List with Dynamic Scaling and Visual Status Badges
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: stockStatusList.length,
              itemBuilder: (context, index) {
                final status = stockStatusList[index];
                return _IngredientStockCard(status: status);
              },
            ),
            const SizedBox(height: 24),

            // Sequential Cooking Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Step-by-Step Instructions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${recipe.instructions.length} steps)',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recipe.instructions.length,
              itemBuilder: (context, index) {
                final step = recipe.instructions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: CheckboxListTile(
                    activeColor: AppTheme.primaryGreen,
                    value: step.isCompleted,
                    onChanged: (val) {
                      setState(() => step.isCompleted = val ?? false);
                    },
                    secondary: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: step.isCompleted
                            ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${step.stepNumber}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: step.isCompleted ? AppTheme.primaryGreen : Colors.white70,
                        ),
                      ),
                    ),
                    title: Text(
                      step.instruction,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        decoration: step.isCompleted ? TextDecoration.lineThrough : null,
                        color: step.isCompleted ? Colors.grey : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          border: const Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            minimumSize: const Size.fromHeight(50),
          ),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => MealConfirmationDialog(
                recipe: recipe,
                targetServings: targetServings,
                stockStatusList: stockStatusList,
              ),
            );

            if (confirmed == true && context.mounted) {
              _showSuccessDialog(context, recipe, targetServings);
            }
          },
          icon: const Icon(Icons.restaurant_menu_rounded),
          label: Text(
            'Cook This Meal (Auto-Deduct Stock for $targetServings Pax)',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, Recipe recipe, int targetServings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.celebration_rounded, color: AppTheme.primaryGreen, size: 28),
            SizedBox(width: 8),
            Text('Bon Appétit!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Successfully logged cooking ${recipe.title} for $targetServings pax.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sync_rounded, color: AppTheme.primaryGreen, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pantry stock automatically updated in real-time.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: const Text('View Updated Pantry'),
          ),
        ],
      ),
    );
  }
}

class _IngredientStockCard extends StatelessWidget {
  final IngredientStockStatus status;

  const _IngredientStockCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Visual Status Badge: \u2713 (adequate), ! (insufficient), \u00d7 (missing)
            StockBadge(status: status, compact: true),
            const SizedBox(width: 12),

            // Scaled Ingredient Name & Amount
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.ingredientName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: status.badgeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Required Scaled Amount Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${status.requiredAmount} ${status.requiredUnit}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
