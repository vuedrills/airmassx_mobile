import 'package:flutter/material.dart';
import '../models/category.dart';
import '../config/theme.dart';

class CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Separate top-level categories vs. flattened ones
    // If the backend returns a flat list (tier-based), we need to group them.
    // However, if the Category model has 'children', we should use that.
    
    // Filter out inactive categories
    final activeCategories = categories.where((c) => c.isActive).toList();

    // Group by Tier (as fallback if no parent/child structure)
    // The previous implementation hardcoded 'Trades', 'Professional', 'Equipment'.
    // We'll respect that if no true hierarchy exists.
    final trades = activeCategories.where((c) => c.tier == 'artisanal' || c.tier == 'automotive').toList();
    final professionals = activeCategories.where((c) => c.tier == 'professional').toList();
    final equipment = activeCategories.where((c) => c.tier == 'equipment').toList();
    
    // Helper to move 'Other' to end logic
    List<Category> _moveOtherToEnd(List<Category> list) {
      final normal = list.where((c) => c.name.toLowerCase() != 'other').toList();
      final other = list.where((c) => c.name.toLowerCase() == 'other').toList();
      return [...normal, ...other];
    }
    
    // Build logic:
    // We want a list of Expandable "Group" headers if we don't have true parent/child.
    // But user asked for "categories that when clicked expand to show the subcat".
    // This implies PARENT categories. 
    // If the backend returns everything flat, we'll treat the TIER as the parent.
    // "Trades" -> [List of Trade Categories]
    // "Professional" -> [List]
    
    final sortedTrades = _moveOtherToEnd(trades);
    final sortedPros = _moveOtherToEnd(professionals);
    final sortedEquipment = _moveOtherToEnd(equipment);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Filter by Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // "All Categories" Option
          ListTile(
            leading: const Icon(Icons.grid_view, color: AppTheme.navy),
            title: const Text('All Categories'),
            trailing: selectedCategory == null || selectedCategory == 'All'
                ? const Icon(Icons.check, color: AppTheme.primary)
                : null,
            onTap: () {
              onCategorySelected(null); // Clear filter
              Navigator.pop(context);
            },
          ),
          
          const Divider(height: 1),

          // Scrollable List
          Expanded(
            child: ListView(
              children: [
                if (sortedTrades.isNotEmpty)
                  _buildTierExpansionTile(context, 'Trades', Icons.handyman_outlined, sortedTrades),
                  
                if (sortedPros.isNotEmpty)
                  _buildTierExpansionTile(context, 'Services', Icons.business_center_outlined, sortedPros),
                  
                if (sortedEquipment.isNotEmpty)
                  _buildTierExpansionTile(context, 'Equipment', Icons.construction, sortedEquipment),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierExpansionTile(BuildContext context, String title, IconData icon, List<Category> subCategories) {
    // If a category inside this tier is selected, expand initially
    final isSelectedInGroup = subCategories.any((c) => c.name == selectedCategory);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isSelectedInGroup,
        leading: Icon(icon, color: AppTheme.navy),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.navy,
          ),
        ),
        children: subCategories.map((category) {
          final isSelected = category.name == selectedCategory;
          return ListTile(
            contentPadding: const EdgeInsets.only(left: 64, right: 16),
            title: Text(
              category.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primary : Colors.black87,
              ),
            ),
            trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primary, size: 20) : null,
            onTap: () {
              onCategorySelected(category.name);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }
}
