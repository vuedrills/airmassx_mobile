import 'package:flutter/material.dart';
import '../models/filter_criteria.dart';
import 'filter_chip.dart';
import 'package:intl/intl.dart';

class ActiveFiltersList extends StatelessWidget {
  final FilterCriteria criteria;
  final Function(FilterCriteria) onUpdate;

  const ActiveFiltersList({
    super.key,
    required this.criteria,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    if (!criteria.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    final chips = <Widget>[];

    // Price filter chip
    if (criteria.minPrice != null || criteria.maxPrice != null) {
      String label = 'USD ';
      if (criteria.minPrice != null && criteria.maxPrice != null) {
        label += '\$${criteria.minPrice!.toInt()}-\$${criteria.maxPrice!.toInt()}';
      } else if (criteria.minPrice != null) {
        label += '>\$${criteria.minPrice!.toInt()}';
      } else {
        label += '<\$${criteria.maxPrice!.toInt()}';
      }

      chips.add(FilterChipWidget(
        label: label,
        onRemove: () {
          onUpdate(criteria.copyWith(
            minPrice: () => null,
            maxPrice: () => null,
          ));
        },
      ));
    }

    // Distance filter chip
    if (criteria.distanceKm != null && criteria.distanceKm! > 0) {
      String label = 'Within ${criteria.distanceKm!.toInt()}km';
      if (criteria.locationName != null) {
        label += ' of ${criteria.locationName}';
      }
      
      chips.add(FilterChipWidget(
        label: label,
        onRemove: () {
          onUpdate(criteria.copyWith(
            distanceKm: () => null,
            latitude: () => null,
            longitude: () => null,
            locationName: () => null,
          ));
        },
      ));
    }

    // Date filter chip
    if (criteria.fromDate != null || criteria.toDate != null) {
      String label = '';
      if (criteria.fromDate != null && criteria.toDate != null) {
        label = 'Next 7 days'; // Simplified for now
      } else if (criteria.fromDate != null) {
        label = 'After ${DateFormat('MMM d').format(criteria.fromDate!)}';
      } else {
        label = 'Before ${DateFormat('MMM d').format(criteria.toDate!)}';
      }

      chips.add(FilterChipWidget(
        label: label,
        onRemove: () {
          onUpdate(criteria.copyWith(
            fromDate: () => null,
            toDate: () => null,
          ));
        },
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: chips.map((chip) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: chip,
        )).toList(),
      ),
    );
  }
}
