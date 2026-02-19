import 'package:equatable/equatable.dart';
import '../../models/task.dart';
import '../../models/category.dart';
import '../../models/sort_option.dart';
import '../../models/ad.dart';

/// Browse states
abstract class BrowseState extends Equatable {
  const BrowseState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class BrowseInitial extends BrowseState {}

/// Loading tasks
class BrowseLoading extends BrowseState {}



/// Tasks loaded
class BrowseLoaded extends BrowseState {
  final List<Task> tasks;
  final List<Category> categories;
  final List<Ad> ads;
  final String selectedCategoryId;
  final SortOption sortOption;
  final bool isMapView;
  final String? taskType;
  final String? tier;
  final bool hasReachedMax;
  final int page;
  final int adsFrequency;
  final bool isFetchingMore;
  final int totalFetched; // Tracks raw server offset (pre-filter count)

  const BrowseLoaded({
    required this.tasks,
    required this.categories,
    this.ads = const [],
    this.selectedCategoryId = 'all',
    this.sortOption = SortOption.mostRelevant,
    this.isMapView = false,
    this.taskType,
    this.tier,
    this.hasReachedMax = false,
    this.page = 0,
    this.adsFrequency = 3,
    this.isFetchingMore = false,
    this.totalFetched = 0,
  });

  BrowseLoaded copyWith({
    List<Task>? tasks,
    List<Category>? categories,
    List<Ad>? ads,
    String? selectedCategoryId,
    SortOption? sortOption,
    bool? isMapView,
    String? taskType,
    String? tier,
    bool? hasReachedMax,
    int? page,
    int? adsFrequency,
    bool? isFetchingMore,
    int? totalFetched,
  }) {
    return BrowseLoaded(
      tasks: tasks ?? this.tasks,
      categories: categories ?? this.categories,
      ads: ads ?? this.ads,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      sortOption: sortOption ?? this.sortOption,
      isMapView: isMapView ?? this.isMapView,
      taskType: taskType ?? this.taskType,
      tier: tier ?? this.tier,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      page: page ?? this.page,
      adsFrequency: adsFrequency ?? this.adsFrequency,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      totalFetched: totalFetched ?? this.totalFetched,
    );
  }

  @override
  List<Object?> get props => [tasks, categories, ads, selectedCategoryId, sortOption, isMapView, taskType, tier, hasReachedMax, page, isFetchingMore, totalFetched];
}

/// Error state
class BrowseError extends BrowseState {
  final String message;

  const BrowseError(this.message);

  @override
  List<Object?> get props => [message];
}
