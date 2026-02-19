import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../bloc/browse/browse_bloc.dart';
import '../bloc/browse/browse_event.dart';
import '../bloc/browse/browse_state.dart';
import 'category_chip.dart';
import '../models/category.dart';

/// Horizontal scrolling category chips
class CategoryChips extends StatefulWidget {
  const CategoryChips({super.key});

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  BrowseLoaded? _lastLoadedState;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowseBloc, BrowseState>(
      builder: (context, state) {
        // Cache the latest loaded state to prevent layout collapse/rebuilds during loading
        if (state is BrowseLoaded) {
          _lastLoadedState = state;
        }

        // Use current loaded state, or fallback to cached state if loading, 
        // effectively ignoring the momentary 'BrowseLoading' state which causes the "pop"
        final displayState = (state is BrowseLoaded) ? state : _lastLoadedState;

        if (displayState == null) {
          return const SizedBox(height: 26);
        }

        // Create 'All' category
        const allCategory = Category(
          id: 'all',
          slug: 'all',
          name: 'All Posts',
          iconName: 'apps-outline',
          type: 'service',
          tier: 'all',
          verificationLevel: 'basic',
        );

        final filteredCategories = displayState.categories.where((c) {
          bool matches = c.type == displayState.taskType && c.parentId == null;
          
          // Only filter by tier if not 'all' and not an equipment request 
          // (equipment categories sometimes have inconsistent tier metadata)
          if (displayState.tier != null && displayState.tier != 'all' && displayState.taskType != 'equipment') {
            matches = matches && c.tier == displayState.tier;
          }
          return matches;
        }).toList();

        // Sort to put 'Other' at the end
        final normalCategories = filteredCategories.where((c) => c.name.toLowerCase() != 'other').toList();
        final otherCategories = filteredCategories.where((c) => c.name.toLowerCase() == 'other').toList();

        final categories = [
          allCategory,
          ...normalCategories,
          ...otherCategories,
        ];

        return SizedBox(
          height: 26,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              
              String? computedDisplayName;
              if (displayState.tier == 'project' && category.id != 'all') {
                computedDisplayName = category.name.replaceAll(RegExp(r'\b(services|service)\b', caseSensitive: false), '').trim();
              }

              final isOtherChip = category.name.toLowerCase() == 'other';
              String chipLabel = computedDisplayName ?? category.name;
              
              // If 'all' is selected (represented by null or empty/all in state), 
              // or if specific category matches
              bool isSelected = category.id == 'all' 
                  ? (displayState.selectedCategoryId == 'all')
                  : category.id == displayState.selectedCategoryId;

              // If it's the 'Other' container chip, check if one of its children is selected
              if (isOtherChip && !isSelected) {
                final selectedChild = displayState.categories.firstWhere(
                  (c) => c.id == displayState.selectedCategoryId && c.parentId == category.id,
                  orElse: () => const Category(id: '', slug: '', name: '', iconName: '', tier: '', verificationLevel: ''),
                );
                if (selectedChild.id.isNotEmpty) {
                  isSelected = true;
                  chipLabel = 'Other (${selectedChild.name})';
                }
              }
              
              return Animate(
                // Use a stable key for 'All Posts' so it doesn't re-animate on tab changes
                // This prevents the "pop pop" visual glitch for the anchor chip.
                // For other chips, we want them to slide in when the tab data changes.
                key: category.id == 'all' 
                    ? const ValueKey('category_all') 
                    : ValueKey('chip_${displayState.taskType}_${displayState.tier}_${category.id}'),
                effects: [
                  FadeEffect(duration: 400.ms, delay: (50 * index).ms),
                  SlideEffect(begin: const Offset(0.1, 0), end: Offset.zero, curve: Curves.easeOutQuad, duration: 400.ms),
                ],
                child: CategoryChip(
                  category: category,
                  displayName: chipLabel,
                  isSelected: isSelected,
                  onTap: () {
                    if (isOtherChip) {
                      final hasSubCategories = displayState.categories.any((c) => c.parentId == category.id);
                      if (hasSubCategories) {
                        _showOtherSubcategories(context, category, displayState);
                      } else {
                        context.read<BrowseBloc>().add(SelectCategory(category.id));
                      }
                    } else {
                      context.read<BrowseBloc>().add(SelectCategory(
                        category.id == 'all' ? 'all' : category.id
                      ));
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showOtherSubcategories(BuildContext context, Category parentCategory, BrowseLoaded state) {
    final subCategories = state.categories.where((c) => c.parentId == parentCategory.id).toList();
    
    // Sort to put any 'Other' sub-category at the end
    subCategories.sort((a, b) {
      bool aIsOther = a.name.toLowerCase().contains('other');
      bool bIsOther = b.name.toLowerCase().contains('other');
      if (aIsOther && !bIsOther) return 1;
      if (!aIsOther && bIsOther) return -1;
      return a.name.compareTo(b.name);
    });

    String groupName = 'Categories';
    if (state.tier == 'artisanal') groupName = 'Trades';
    else if (state.tier == 'professional') groupName = 'Services';
    else if (state.taskType == 'equipment') groupName = 'Equipment';
    else if (state.tier == 'project') groupName = 'Projects';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'More $groupName',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2A4E), // AppTheme.navy
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  if (subCategories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No additional categories available.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: subCategories.map((cat) {
                        final isSelected = state.selectedCategoryId == cat.id;
                        return FilterChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            context.read<BrowseBloc>().add(SelectCategory(
                              selected ? cat.id : 'all'
                            ));
                            Navigator.pop(sheetContext);
                          },
                          selectedColor: const Color(0xFFCC3333).withOpacity(0.1), // AppTheme.primary
                          checkmarkColor: const Color(0xFFCC3333),
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFFCC3333) : const Color(0xFF4B5563),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFFCC3333) : Colors.grey[200]!,
                            ),
                          ),
                          backgroundColor: Colors.white,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
