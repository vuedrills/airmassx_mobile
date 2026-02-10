import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/category.dart';

/// Category chip widget for browse filtering
class CategoryChip extends StatelessWidget {
  final Category category;
  final String? displayName;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.displayName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.neutral100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: null,
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.neutral200,
            width: 1,
          ),
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 11,
              height: 1.0, // Removes extra leading/line-height space
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textPrimary,
            ),
            child: Text(
              displayName ?? category.name,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
