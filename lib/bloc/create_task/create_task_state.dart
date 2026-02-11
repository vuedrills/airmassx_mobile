import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum CreateTaskStatus { initial, valid, invalid, submitting, success, failure }

class CreateTaskState extends Equatable {
  final String title;
  final String? dateType; // 'on_date', 'before_date', 'flexible'
  final String description;
  final DateTime? date;
  final TimeOfDay? time;
  final bool isFlexible;
  final bool hasSpecificTime;
  final String? timeOfDay; // 'morning', 'midday', 'afternoon', 'evening'
  final String location;
  final double? latitude;
  final double? longitude;
  final double budget;
  final String? city;
  final String? suburb;
  final String? addressDetails;
  final CreateTaskStatus status;
  final String? errorMessage;
  
  // Equipment-specific fields (V2)
  final String taskType; // 'service' or 'equipment'
  final String? costingBasis; // 'time', 'distance', 'per_load'
  final String? hireDurationType; // 'hourly', 'daily', 'weekly', 'monthly', 'kilometers', 'loads', 'trips'
  final double? estimatedHours; // For hourly hire
  final double? estimatedDuration; // For daily/weekly/monthly/km/loads
  final int? equipmentUnits; // Number of equipment units needed (e.g., 2 excavators)
  final int? numberOfTrips; // Number of trips/loads (for distance-based or per-load costing)
  final double? distancePerTrip; // Distance per trip in km (for context)
  final String? operatorPreference; // 'required', 'preferred', 'not_needed'
  final bool fuelIncluded;
  final String? requiredCapacityId; // Equipment capacity selection
  final double? capacityValue;      // Manual capacity value
  final String? capacityUnit;       // Manual capacity unit
  final List<String> categories;
  final List<String> photos;
  final List<String> attachments; // Document attachments (BOQs, plans, PDFs)
  
  // Artisanal-specific fields
  final String? provisionType; // 'labour_only', 'supply_and_fix'
  final bool requiresSiteVisit;
  final String? boqPath;
  final List<String> plansPaths;
  final String? siteReadiness;
  final String? projectSize;
  final DateTime? timelineEnd; // Entry for timelineEnd specifically

  // Site Visit Fields
  final DateTime? siteVisitDate;
  final TimeOfDay? siteVisitTime;
  final String? siteVisitAddress;
  final double? siteVisitLat;
  final double? siteVisitLng;
  final String? taskId; // Valid when editing

  const CreateTaskState({
    this.title = '',
    this.dateType,
    this.description = '',
    this.date,
    this.time,
    this.isFlexible = true,
    this.hasSpecificTime = false,
    this.timeOfDay,
    this.location = '',
    this.latitude,
    this.longitude,
    this.budget = 0,
    this.categories = const [],
    this.photos = const [],
    this.attachments = const [],
    this.city,
    this.suburb,
    this.addressDetails,
    this.status = CreateTaskStatus.initial,
    this.errorMessage,
    // Equipment defaults
    this.taskType = 'service',
    this.costingBasis = 'time',
    this.hireDurationType,
    this.estimatedHours,
    this.estimatedDuration,
    this.equipmentUnits,
    this.numberOfTrips,
    this.distancePerTrip,
    this.operatorPreference,
    this.fuelIncluded = false,
    this.requiredCapacityId,
    this.capacityValue,
    this.capacityUnit,
    this.provisionType,
    this.requiresSiteVisit = false,
    this.boqPath,
    this.plansPaths = const [],
    this.siteReadiness,
    this.projectSize,
    this.timelineEnd,
    this.siteVisitDate,
    this.siteVisitTime,
    this.siteVisitAddress,
    this.siteVisitLat,
    this.siteVisitLng,
    this.taskId,
  });

  bool get isEquipmentTask => taskType == 'equipment';
  bool get isEditing => taskId != null;

  CreateTaskState copyWith({
    String? title,
    String? dateType,
    String? description,
    DateTime? date,
    TimeOfDay? time,
    bool? isFlexible,
    bool? hasSpecificTime,
    String? timeOfDay,
    String? location,
    double? latitude,
    double? longitude,
    double? budget,
    List<String>? categories,
    List<String>? photos,
    String? city,
    String? suburb,
    String? addressDetails,
    CreateTaskStatus? status,
    String? errorMessage,
    // Equipment fields
    String? taskType,
    String? costingBasis,
    String? hireDurationType,
    double? estimatedHours,
    double? estimatedDuration,
    int? equipmentUnits,
    int? numberOfTrips,
    double? distancePerTrip,
    String? operatorPreference,
    bool? fuelIncluded,
    String? requiredCapacityId,
    double? capacityValue,
    String? capacityUnit,
    String? provisionType,
    List<String>? attachments,
    bool? requiresSiteVisit,
    String? boqPath,
    List<String>? plansPaths,
    String? siteReadiness,
    String? projectSize,
    DateTime? timelineEnd,
    DateTime? siteVisitDate,
    TimeOfDay? siteVisitTime,
    String? siteVisitAddress,
    double? siteVisitLat,
    double? siteVisitLng,
    String? taskId,
  }) {
    return CreateTaskState(
      title: title ?? this.title,
      dateType: dateType ?? this.dateType,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      isFlexible: isFlexible ?? this.isFlexible,
      hasSpecificTime: hasSpecificTime ?? this.hasSpecificTime,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      budget: budget ?? this.budget,
      categories: categories ?? this.categories,
      photos: photos ?? this.photos,
      city: city ?? this.city,
      suburb: suburb ?? this.suburb,
      addressDetails: addressDetails ?? this.addressDetails,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      // Equipment fields
      taskType: taskType ?? this.taskType,
      costingBasis: costingBasis ?? this.costingBasis,
      hireDurationType: hireDurationType ?? this.hireDurationType,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      equipmentUnits: equipmentUnits ?? this.equipmentUnits,
      numberOfTrips: numberOfTrips ?? this.numberOfTrips,
      distancePerTrip: distancePerTrip ?? this.distancePerTrip,
      operatorPreference: operatorPreference ?? this.operatorPreference,
      fuelIncluded: fuelIncluded ?? this.fuelIncluded,
      requiredCapacityId: requiredCapacityId ?? this.requiredCapacityId,
      capacityValue: capacityValue ?? this.capacityValue,
      capacityUnit: capacityUnit ?? this.capacityUnit,
      provisionType: provisionType ?? this.provisionType,
      attachments: attachments ?? this.attachments,
      requiresSiteVisit: requiresSiteVisit ?? this.requiresSiteVisit,
      boqPath: boqPath ?? this.boqPath,
      plansPaths: plansPaths ?? this.plansPaths,
      siteReadiness: siteReadiness ?? this.siteReadiness,
      projectSize: projectSize ?? this.projectSize,
      timelineEnd: timelineEnd ?? this.timelineEnd,
      siteVisitDate: siteVisitDate ?? this.siteVisitDate,
      siteVisitTime: siteVisitTime ?? this.siteVisitTime,
      siteVisitAddress: siteVisitAddress ?? this.siteVisitAddress,
      siteVisitLat: siteVisitLat ?? this.siteVisitLat,
      siteVisitLng: siteVisitLng ?? this.siteVisitLng,
      taskId: taskId ?? this.taskId,
    );
  }

  @override
  List<Object?> get props => [
        title,
        dateType,
        description,
        date,
        time,
        isFlexible,
        hasSpecificTime,
        timeOfDay,
        location,
        latitude,
        longitude,
        budget,
        categories,
        photos,
        city,
        suburb,
        addressDetails,
        status,
        errorMessage,
        // Equipment fields
        taskType,
        costingBasis,
        hireDurationType,
        estimatedHours,
        estimatedDuration,
        equipmentUnits,
        numberOfTrips,
        distancePerTrip,
        operatorPreference,
        fuelIncluded,
        requiredCapacityId,
        capacityValue,
        capacityUnit,
        provisionType,
        attachments,
        requiresSiteVisit,
        boqPath,
        plansPaths,
        siteReadiness,
        projectSize,
        timelineEnd,
        siteVisitDate,
        siteVisitTime,
        siteVisitAddress,
        siteVisitLat,
        siteVisitLng,
        taskId,
      ];
}
