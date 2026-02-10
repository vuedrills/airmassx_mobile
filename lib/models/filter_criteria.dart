import 'package:equatable/equatable.dart';

/// Filter criteria for browsing tasks
class FilterCriteria extends Equatable {
  final double? minPrice;
  final double? maxPrice;
  final double? distanceKm;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<String> taskStatus; // 'open', 'assigned', 'completed'

  const FilterCriteria({
    this.minPrice,
    this.maxPrice,
    this.distanceKm,
    this.latitude,
    this.longitude,
    this.locationName,
    this.fromDate,
    this.toDate,
    this.taskStatus = const ['open'],
  });

  FilterCriteria copyWith({
    double? Function()? minPrice,
    double? Function()? maxPrice,
    double? Function()? distanceKm,
    double? Function()? latitude,
    double? Function()? longitude,
    String? Function()? locationName,
    DateTime? Function()? fromDate,
    DateTime? Function()? toDate,
    List<String>? taskStatus,
  }) {
    return FilterCriteria(
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
      distanceKm: distanceKm != null ? distanceKm() : this.distanceKm,
      latitude: latitude != null ? latitude() : this.latitude,
      longitude: longitude != null ? longitude() : this.longitude,
      locationName: locationName != null ? locationName() : this.locationName,
      fromDate: fromDate != null ? fromDate() : this.fromDate,
      toDate: toDate != null ? toDate() : this.toDate,
      taskStatus: taskStatus ?? this.taskStatus,
    );
  }

  bool get hasActiveFilters {
    return minPrice != null ||
        maxPrice != null ||
        distanceKm != null ||
        fromDate != null ||
        toDate != null ||
        taskStatus.length > 1 ||
        (taskStatus.length == 1 && taskStatus.first != 'open');
  }

  int get activeFilterCount {
    int count = 0;
    if (minPrice != null || maxPrice != null) count++;
    if (distanceKm != null) count++;
    if (fromDate != null || toDate != null) count++;
    if (taskStatus.length > 1 || (taskStatus.length == 1 && taskStatus.first != 'open')) count++;
    return count;
  }

  Map<String, dynamic> toJson() {
    return {
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'distanceKm': distanceKm,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'fromDate': fromDate?.toIso8601String(),
      'toDate': toDate?.toIso8601String(),
      'taskStatus': taskStatus,
    };
  }

  factory FilterCriteria.fromJson(Map<String, dynamic> json) {
    return FilterCriteria(
      minPrice: json['minPrice'] as double?,
      maxPrice: json['maxPrice'] as double?,
      distanceKm: json['distanceKm'] as double?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      locationName: json['locationName'] as String?,
      fromDate: json['fromDate'] != null ? DateTime.parse(json['fromDate'] as String) : null,
      toDate: json['toDate'] != null ? DateTime.parse(json['toDate'] as String) : null,
      taskStatus: (json['taskStatus'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const ['open'],
    );
  }

  @override
  List<Object?> get props => [minPrice, maxPrice, distanceKm, latitude, longitude, locationName, fromDate, toDate, taskStatus];
}
