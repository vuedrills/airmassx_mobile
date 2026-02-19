import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';


abstract class CreateTaskEvent extends Equatable {
  const CreateTaskEvent();

  @override
  List<Object?> get props => [];
}

class CreateTaskTitleChanged extends CreateTaskEvent {
  final String title;
  const CreateTaskTitleChanged(this.title);
  @override
  List<Object?> get props => [title];
}

class CreateTaskDescriptionChanged extends CreateTaskEvent {
  final String description;
  const CreateTaskDescriptionChanged(this.description);
  @override
  List<Object?> get props => [description];
}

class CreateTaskDateChanged extends CreateTaskEvent {
  final DateTime? date;
  const CreateTaskDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class CreateTaskFlexibleChanged extends CreateTaskEvent {
  final bool isFlexible;
  const CreateTaskFlexibleChanged(this.isFlexible);
  @override
  List<Object?> get props => [isFlexible];
}

class CreateTaskLocationChanged extends CreateTaskEvent {
  final String location;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? suburb;
  final String? addressDetails;

  const CreateTaskLocationChanged(
    this.location, {
    this.latitude,
    this.longitude,
    this.city,
    this.suburb,
    this.addressDetails,
  });

  @override
  List<Object?> get props => [location, latitude, longitude, city, suburb, addressDetails];
}

class CreateTaskBudgetChanged extends CreateTaskEvent {
  final double budget;
  const CreateTaskBudgetChanged(this.budget);
  @override
  List<Object?> get props => [budget];
}

class CreateTaskPhotoAdded extends CreateTaskEvent {
  final String path;
  const CreateTaskPhotoAdded(this.path);
  @override
  List<Object?> get props => [path];
}

class CreateTaskPhotoRemoved extends CreateTaskEvent {
  final int index;
  const CreateTaskPhotoRemoved(this.index);
  @override
  List<Object?> get props => [index];
}

class CreateTaskSubmitted extends CreateTaskEvent {}

class CreateTaskSpecificTimeToggled extends CreateTaskEvent {
  final bool isEnabled;
  const CreateTaskSpecificTimeToggled(this.isEnabled);
  @override
  List<Object?> get props => [isEnabled];
}

class CreateTaskSpecificTimeChanged extends CreateTaskEvent {
  final TimeOfDay time;
  const CreateTaskSpecificTimeChanged(this.time);
  @override
  List<Object?> get props => [time];
}

class CreateTaskDateTypeChanged extends CreateTaskEvent {
  final String dateType; // 'on_date', 'before_date', 'flexible'
  const CreateTaskDateTypeChanged(this.dateType);
  @override
  List<Object?> get props => [dateType];
}

class CreateTaskTimeOfDayChanged extends CreateTaskEvent {
  final String? timeOfDay; // 'morning', 'midday', 'afternoon', 'evening'
  const CreateTaskTimeOfDayChanged(this.timeOfDay);
  @override
  List<Object?> get props => [timeOfDay];
}

class CreateTaskCategoryToggled extends CreateTaskEvent {
  final String category;
  const CreateTaskCategoryToggled(this.category);
  @override
  List<Object?> get props => [category];
}

class CreateTaskOtherEquipmentDescriptionChanged extends CreateTaskEvent {
  final String description;
  const CreateTaskOtherEquipmentDescriptionChanged(this.description);
  @override
  List<Object?> get props => [description];
}

// ============ EQUIPMENT-SPECIFIC EVENTS ============

/// Set the task type ('service' or 'equipment')
class CreateTaskTypeChanged extends CreateTaskEvent {
  final String taskType;
  const CreateTaskTypeChanged(this.taskType);
  @override
  List<Object?> get props => [taskType];
}

/// Set costing basis ('time', 'distance', 'quantity')
class CreateTaskCostingBasisChanged extends CreateTaskEvent {
  final String costingBasis;
  const CreateTaskCostingBasisChanged(this.costingBasis);
  @override
  List<Object?> get props => [costingBasis];
}

/// Set hire duration type ('hourly', 'daily', 'weekly', 'monthly')
class CreateTaskHireDurationTypeChanged extends CreateTaskEvent {
  final String hireDurationType;
  const CreateTaskHireDurationTypeChanged(this.hireDurationType);
  @override
  List<Object?> get props => [hireDurationType];
}

/// Set estimated hours (for hourly hire)
class CreateTaskEstimatedHoursChanged extends CreateTaskEvent {
  final double? estimatedHours;
  const CreateTaskEstimatedHoursChanged(this.estimatedHours);
  @override
  List<Object?> get props => [estimatedHours];
}

/// Set estimated duration (for daily/weekly/monthly hire)
class CreateTaskEstimatedDurationChanged extends CreateTaskEvent {
  final double? estimatedDuration;
  const CreateTaskEstimatedDurationChanged(this.estimatedDuration);
  @override
  List<Object?> get props => [estimatedDuration];
}

/// Set equipment units (number of machines needed)
class CreateTaskEquipmentUnitsChanged extends CreateTaskEvent {
  final int? equipmentUnits;
  const CreateTaskEquipmentUnitsChanged(this.equipmentUnits);
  @override
  List<Object?> get props => [equipmentUnits];
}

/// Set number of trips/loads
class CreateTaskNumberOfTripsChanged extends CreateTaskEvent {
  final int? numberOfTrips;
  const CreateTaskNumberOfTripsChanged(this.numberOfTrips);
  @override
  List<Object?> get props => [numberOfTrips];
}

/// Set distance per trip in km
class CreateTaskDistancePerTripChanged extends CreateTaskEvent {
  final double? distancePerTrip;
  const CreateTaskDistancePerTripChanged(this.distancePerTrip);
  @override
  List<Object?> get props => [distancePerTrip];
}

/// Set operator preference ('required', 'preferred', 'not_needed')
class CreateTaskOperatorPreferenceChanged extends CreateTaskEvent {
  final String operatorPreference;
  const CreateTaskOperatorPreferenceChanged(this.operatorPreference);
  @override
  List<Object?> get props => [operatorPreference];
}

/// Toggle fuel included option
class CreateTaskFuelIncludedChanged extends CreateTaskEvent {
  final bool fuelIncluded;
  const CreateTaskFuelIncludedChanged(this.fuelIncluded);
  @override
  List<Object?> get props => [fuelIncluded];
}

/// Set required capacity for equipment
class CreateTaskRequiredCapacityChanged extends CreateTaskEvent {
  final String? requiredCapacityId;
  const CreateTaskRequiredCapacityChanged(this.requiredCapacityId);
  @override
  List<Object?> get props => [requiredCapacityId];
}

class CreateTaskCapacityValueChanged extends CreateTaskEvent {
  final double? capacityValue;
  const CreateTaskCapacityValueChanged(this.capacityValue);
  @override
  List<Object?> get props => [capacityValue];
}

class CreateTaskCapacityUnitChanged extends CreateTaskEvent {
  final String? capacityUnit;
  const CreateTaskCapacityUnitChanged(this.capacityUnit);
  @override
  List<Object?> get props => [capacityUnit];
}

/// Reset the form to initial state
class CreateTaskReset extends CreateTaskEvent {
  final String? taskType;
  const CreateTaskReset({this.taskType});
  @override
  List<Object?> get props => [taskType];
}

/// Initialize the form with existing task data (for editing)
class CreateTaskInitialize extends CreateTaskEvent {
  final dynamic task; // Using dynamic to avoid circular import, should be Task model
  const CreateTaskInitialize(this.task);
  @override
  List<Object?> get props => [task];
}

class CreateTaskProvisionTypeChanged extends CreateTaskEvent {
  final String provisionType;
  const CreateTaskProvisionTypeChanged(this.provisionType);
  @override
  List<Object?> get props => [provisionType];
}

// ============ ATTACHMENT EVENTS ============

/// Add an attachment (BOQ, plan, PDF)
class CreateTaskAttachmentAdded extends CreateTaskEvent {
  final String path;
  const CreateTaskAttachmentAdded(this.path);
  @override
  List<Object?> get props => [path];
}

/// Remove an attachment by index
class CreateTaskAttachmentRemoved extends CreateTaskEvent {
  final int index;
  const CreateTaskAttachmentRemoved(this.index);
  @override
  List<Object?> get props => [index];
}

class CreateTaskSiteVisitRequiredChanged extends CreateTaskEvent {
  final bool requiresSiteVisit;
  const CreateTaskSiteVisitRequiredChanged(this.requiresSiteVisit);
  @override
  List<Object?> get props => [requiresSiteVisit];
}

// ============ PROJECT-SPECIFIC EVENTS ============

class CreateTaskBOQChanged extends CreateTaskEvent {
  final String? path;
  const CreateTaskBOQChanged(this.path);
  @override
  List<Object?> get props => [path];
}

class CreateTaskPlansAdded extends CreateTaskEvent {
  final String path;
  const CreateTaskPlansAdded(this.path);
  @override
  List<Object?> get props => [path];
}

class CreateTaskPlansRemoved extends CreateTaskEvent {
  final int index;
  const CreateTaskPlansRemoved(this.index);
  @override
  List<Object?> get props => [index];
}

class CreateTaskSiteReadinessChanged extends CreateTaskEvent {
  final String siteReadiness;
  const CreateTaskSiteReadinessChanged(this.siteReadiness);
  @override
  List<Object?> get props => [siteReadiness];
}

class CreateTaskProjectSizeChanged extends CreateTaskEvent {
  final String projectSize;
  const CreateTaskProjectSizeChanged(this.projectSize);
  @override
  List<Object?> get props => [projectSize];
}

class CreateTaskTimelineEndChanged extends CreateTaskEvent {
  final DateTime? date;
  const CreateTaskTimelineEndChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class CreateTaskSiteVisitDateChanged extends CreateTaskEvent {
  final DateTime? date;
  const CreateTaskSiteVisitDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class CreateTaskSiteVisitTimeChanged extends CreateTaskEvent {
  final TimeOfDay? time;
  const CreateTaskSiteVisitTimeChanged(this.time);
  @override
  List<Object?> get props => [time];
}

class CreateTaskSiteVisitLocationChanged extends CreateTaskEvent {
  final String location;
  final double? latitude;
  final double? longitude;

  const CreateTaskSiteVisitLocationChanged(
    this.location, {
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [location, latitude, longitude];
}
