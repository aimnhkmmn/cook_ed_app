import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PortionSelector extends StatelessWidget {
  final int servings;
  final ValueChanged<int> onServingsChanged;

  const PortionSelector({
    super.key,
    required this.servings,
    required this.onServingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Serving Size (Pax)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Auto-scales all ingredients',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: servings > 1 ? () => onServingsChanged(servings - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: servings > 1 ? AppTheme.primaryGreen : Colors.grey[600],
                iconSize: 28,
              ),
              Container(
                constraints: const Duration(milliseconds: 100).inMilliseconds > 0
                    ? const BoxConstraints(minWidth: 36)
                    : null,
                alignment: Alignment.center,
                child: Text(
                  '$servings',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: servings < 30 ? () => onServingsChanged(servings + 1) : null,
                icon: const Icon(Icons.add_circle_outline),
                color: servings < 30 ? AppTheme.primaryGreen : Colors.grey[600],
                iconSize: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
