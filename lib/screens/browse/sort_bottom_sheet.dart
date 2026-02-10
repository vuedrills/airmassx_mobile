import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/browse/browse_bloc.dart';
import '../../bloc/browse/browse_event.dart';
import '../../bloc/browse/browse_state.dart';
import '../../models/sort_option.dart';
import '../../config/theme.dart';

/// Sort bottom sheet with radio options
class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({super.key});

  static void show(BuildContext context, {BrowseBloc? browseBloc}) {
    final effectiveBrowseBloc = browseBloc ?? context.read<BrowseBloc>();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (newContext) => BlocProvider.value(
        value: effectiveBrowseBloc,
        child: const SortBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowseBloc, BrowseState>(
      builder: (context, state) {
        final currentSort = state is BrowseLoaded ? state.sortOption : SortOption.mostRelevant;
        
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.neutral200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Sort by',
                    style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                ...SortOption.values.map((option) {
                  final isSelected = currentSort == option;
                  return InkWell(
                    onTap: () {
                      context.read<BrowseBloc>().add(SetSortOption(option));
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Text(
                            option.label,
                            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                              color: isSelected ? AppTheme.primary : AppTheme.neutral800,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22)
                          else
                            Icon(Icons.circle_outlined, color: AppTheme.neutral200, size: 22),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
