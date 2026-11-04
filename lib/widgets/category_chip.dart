import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CategoryChipList extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const CategoryChipList({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selectedCategory;

          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (_) => onSelected(cat),
            selectedColor: AppTheme.primaryGreen,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[400],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryGreen : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            backgroundColor: Theme.of(context).cardTheme.color,
          );
        },
      ),
    );
  }
}
