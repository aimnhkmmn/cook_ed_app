import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/pantry_item.dart';
import '../../widgets/category_chip.dart';
import 'receipt_scanner_screen.dart';

class PantryScreen extends StatelessWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final items = provider.filteredPantryItems;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.kitchen_rounded, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('Kitchen Pantry'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Scan Receipt',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReceiptScannerScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => provider.refreshPantry(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Summary Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search pantry items...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: provider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => provider.setSearchQuery(''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (val) => provider.setSearchQuery(val),
            ),
          ),

          // Categories Filter
          CategoryChipList(
            categories: AppConstants.pantryCategories,
            selectedCategory: provider.selectedCategory,
            onSelected: (cat) => provider.setSelectedCategory(cat),
          ),
          const SizedBox(height: 8),

          // Inventory Summary Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: 'Total Items',
                    value: '${provider.pantryItems.length}',
                    icon: Icons.inventory_2_outlined,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: 'Low Stock (<2)',
                    value: '${provider.pantryItems.where((i) => i.quantity <= 2).length}',
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.accentAmber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Pantry Items List
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.kitchen_outlined, size: 64, color: Colors.grey[500]),
                        const SizedBox(height: 16),
                        Text(
                          provider.pantryItems.isEmpty
                              ? 'Your virtual pantry is empty!'
                              : 'No items match your filter.',
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scan a receipt or tap "+" to add groceries.',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _PantryItemCard(item: item);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Grocery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _AddPantryItemSheet(),
    );
  }
}

class _PantryItemCard extends StatelessWidget {
  final PantryItem item;

  const _PantryItemCard({required this.item});

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Meat & Seafood':
        return Icons.set_meal_rounded;
      case 'Produce':
        return Icons.eco_rounded;
      case 'Dairy & Eggs':
        return Icons.egg_outlined;
      case 'Spices & Seasonings':
        return Icons.grain_rounded;
      case 'Pantry & Dry Goods':
        return Icons.breakfast_dining_rounded;
      default:
        return Icons.shopping_basket_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Category Icon Badge
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(item.category),
                color: AppTheme.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Item Name & Category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),

            // Quick Quantity Stepper
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 22),
                  color: Colors.grey[400],
                  onPressed: item.quantity > 0
                      ? () {
                          final step = (item.unit == 'g' || item.unit == 'ml') ? 50.0 : 1.0;
                          final newQty = (item.quantity - step).clamp(0.0, double.infinity);
                          provider.updateItemQuantity(item.id, newQty);
                        }
                      : null,
                ),
                Text(
                  '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  color: AppTheme.primaryGreen,
                  onPressed: () {
                    final step = (item.unit == 'g' || item.unit == 'ml') ? 50.0 : 1.0;
                    provider.updateItemQuantity(item.id, item.quantity + step);
                  },
                ),
              ],
            ),

            // Delete
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400], size: 20),
              onSelected: (val) {
                if (val == 'delete') {
                  provider.deletePantryItem(item.id);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPantryItemSheet extends StatefulWidget {
  const _AddPantryItemSheet();

  @override
  State<_AddPantryItemSheet> createState() => _AddPantryItemSheetState();
}

class _AddPantryItemSheetState extends State<_AddPantryItemSheet> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  String _selectedUnit = 'pcs';
  String _selectedCategory = 'Produce';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add Grocery Item',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Item Name',
              hintText: 'e.g., Chicken Breast, Olive Oil',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedUnit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: AppConstants.standardUnits
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedUnit = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Category'),
            items: AppConstants.pantryCategories
                .where((c) => c != 'All')
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategory = val);
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              final qty = double.tryParse(_quantityController.text.trim()) ?? 1.0;
              if (name.isNotEmpty) {
                context.read<AppProvider>().addPantryItem(
                      name: name,
                      quantity: qty,
                      unit: _selectedUnit,
                      category: _selectedCategory,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Add to Pantry'),
          ),
        ],
      ),
    );
  }
}
