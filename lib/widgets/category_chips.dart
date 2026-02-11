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
          if (displayState.tier != null && displayState.tier != 'all') {
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
              
              String? displayName;
              if (displayState.tier == 'project' && category.id != 'all') {
                displayName = category.name.replaceAll(RegExp(r'\b(services|service)\b', caseSensitive: false), '').trim();
              }

              // If 'all' is selected (represented by null or empty/all in state), 
              // or if specific category matches
              final isSelected = category.id == 'all' 
                  ? (displayState.selectedCategoryId == 'all')
                  : category.id == displayState.selectedCategoryId;
              
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
                  displayName: displayName,
                  isSelected: isSelected,
                  onTap: () {
                    context.read<BrowseBloc>().add(SelectCategory(
                      category.id == 'all' ? 'all' : category.id
                    ));
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
