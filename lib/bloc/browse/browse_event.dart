import 'package:equatable/equatable.dart';
import '../../models/sort_option.dart';
import '../../models/filter_criteria.dart';

/// Browse events
abstract class BrowseEvent extends Equatable {
  const BrowseEvent();

  @override
  List<Object?> get props => [];
}

/// Load tasks for browsing
class LoadBrowseTasks extends BrowseEvent {
  final FilterCriteria? criteria;

  const LoadBrowseTasks({this.criteria});

  @override
  List<Object?> get props => [criteria];
}

/// Load next page of tasks
class LoadMoreTasks extends BrowseEvent {}

/// Select a category filter
class SelectCategory extends BrowseEvent {
  final String? categoryId;

  const SelectCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

/// Set sort option
class SetSortOption extends BrowseEvent {
  final SortOption sortOption;

  const SetSortOption(this.sortOption);

  @override
  List<Object?> get props => [sortOption];
}

/// Toggle between list and map view
class ToggleView extends BrowseEvent {
  final bool isMapView;

  const ToggleView(this.isMapView);

  @override
  List<Object?> get props => [isMapView];
}

/// Load tasks with specific filters (for equipment vs service)
class LoadBrowseTasksWithFilter extends BrowseEvent {
  final String? taskType;
  final String? category;
  final String? location;
  final String? tier;

  const LoadBrowseTasksWithFilter({
    this.taskType,
    this.category,
    this.location,
    this.tier,
  });

  @override
  List<Object?> get props => [taskType, category, location, tier];
}
