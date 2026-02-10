import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/browse/browse_bloc.dart';
import '../../bloc/browse/browse_event.dart';
import '../../models/category.dart';
import '../../config/theme.dart';

/// Full-screen category grid view
class CategoryGridView extends StatelessWidget {
  final List<Category> categories;

  const CategoryGridView({super.key, required this.categories});

  static Future<void> show(BuildContext context, List<Category> categories) {
    final browseBloc = context.read<BrowseBloc>();
    
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (newContext) => BlocProvider.value(
          value: browseBloc,
          child: CategoryGridView(categories: categories),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter out 'All' from the grid
    final filtered = categories.where((c) => c.id != 'all').toList();
    final normal = filtered.where((c) => c.name.toLowerCase() != 'other').toList();
    final other = filtered.where((c) => c.name.toLowerCase() == 'other').toList();
    final displayCategories = [...normal, ...other];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse by category'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: displayCategories.length,
        itemBuilder: (context, index) {
          final category = displayCategories[index];
          return _CategoryGridTile(category: category);
        },
      ),
    );
  }
}

class _CategoryGridTile extends StatelessWidget {
  final Category category;

  const _CategoryGridTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<BrowseBloc>().add(SelectCategory(category.id));
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category.icon,
                  size: constraints.maxHeight * 0.35,
                  color: AppTheme.accentTeal,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Center(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Text(
                  category.tier,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
