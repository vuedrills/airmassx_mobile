import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/browse/browse_bloc.dart';
import '../bloc/browse/browse_event.dart';
import '../bloc/browse/browse_state.dart';
import 'category_chip.dart';
import '../models/category.dart';

/// Horizontal scrolling category chips
class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowseBloc, BrowseState>(
      builder: (context, state) {
        if (state is! BrowseLoaded) {
          return const SizedBox.shrink();
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

        final filteredCategories = state.categories.where((c) {
          bool matches = c.type == state.taskType && c.parentId == null;
          if (state.tier != null && state.tier != 'all') {
            matches = matches && c.tier == state.tier;
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
              
              String? displayName;
              if (state.tier == 'project' && category.id != 'all') {
                displayName = category.name.replaceAll(RegExp(r'\b(services|service)\b', caseSensitive: false), '').trim();
              }

              // If 'all' is selected (represented by null or empty/all in state), 
              // or if specific category matches
              final isSelected = category.id == 'all' 
                  ? (state.selectedCategoryId == null || state.selectedCategoryId == 'all')
                  : category.id == state.selectedCategoryId;
              
              return CategoryChip(
                category: category,
                displayName: displayName,
                isSelected: isSelected,
                onTap: () {
                  context.read<BrowseBloc>().add(SelectCategory(
                    category.id == 'all' ? 'all' : category.id
                  ));
                },
              );
            },
          ),
        );
      },
    );
  }
}
