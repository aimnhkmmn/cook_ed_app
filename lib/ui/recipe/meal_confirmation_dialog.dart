import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/recipe.dart';
import '../../models/stock_status.dart';

class MealConfirmationDialog extends StatefulWidget {
  final Recipe recipe;
  final int targetServings;
  final List<IngredientStockStatus> stockStatusList;

  const MealConfirmationDialog({
    super.key,
    required this.recipe,
    required this.targetServings,
    required this.stockStatusList,
  });

  @override
  State<MealConfirmationDialog> createState() => _MealConfirmationDialogState();
}

class _MealConfirmationDialogState extends State<MealConfirmationDialog> {
  bool _isDeducting = false;

  Future<void> _executeDeduction() async {
    setState(() => _isDeducting = true);
    final provider = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      final result = await provider.confirmMealAndDeductStock(
        recipe: widget.recipe,
        servings: widget.targetServings,
      );

      if (!mounted) return;
      setState(() => _isDeducting = false);

      if (result['success'] == true) {
        nav.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[700],
            content: Text(result['message']?.toString() ?? 'Failed to deduct pantry stock'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeducting = false);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Text('Error: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final missingCount = widget.stockStatusList.where((s) => s.badgeType == StockBadgeType.missing).length;
    final insufficientCount = widget.stockStatusList.where((s) => s.badgeType == StockBadgeType.insufficient).length;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 10),
          const Text('Confirm Cooking Meal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cooking for: ${widget.targetServings} Pax',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Cook-Ed will automatically deduct the following ingredient amounts from your virtual pantry:',
              style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.3),
            ),
            const SizedBox(height: 12),

            // Shortage Warning if applicable
            if (missingCount > 0 || insufficientCount > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppTheme.accentAmber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: $insufficientCount items are low in stock, and $missingCount items are missing.',
                        style: const TextStyle(fontSize: 12, color: AppTheme.accentAmber),
                      ),
                    ),
                  ],
                ),
              ),

            // Item Deductions List
            if (widget.stockStatusList.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < widget.stockStatusList.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.stockStatusList[i].ingredientName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              '-${widget.stockStatusList[i].requiredAmount} ${widget.stockStatusList[i].requiredUnit}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeducting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isDeducting ? null : _executeDeduction,
          child: _isDeducting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Confirm & Deduct Stock'),
        ),
      ],
    );
  }
}
