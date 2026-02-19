import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'create_task_event.dart';
import 'create_task_state.dart';

class CreateTaskBloc extends Bloc<CreateTaskEvent, CreateTaskState> {
  final ApiService _apiService;

  CreateTaskBloc(this._apiService) : super(const CreateTaskState()) {
    on<CreateTaskTitleChanged>(_onTitleChanged);
    on<CreateTaskDescriptionChanged>(_onDescriptionChanged);
    on<CreateTaskDateChanged>(_onDateChanged);
    on<CreateTaskFlexibleChanged>(_onFlexibleChanged);
    on<CreateTaskLocationChanged>(_onLocationChanged);
    on<CreateTaskBudgetChanged>(_onBudgetChanged);
    on<CreateTaskPhotoAdded>(_onPhotoAdded);
    on<CreateTaskPhotoRemoved>(_onPhotoRemoved);
    on<CreateTaskSubmitted>(_onSubmitted);
    on<CreateTaskDateTypeChanged>(_onDateTypeChanged);
    on<CreateTaskTimeOfDayChanged>(_onTimeOfDayChanged);
    on<CreateTaskSpecificTimeToggled>(_onSpecificTimeToggled);
    on<CreateTaskCategoryToggled>(_onCategoryToggled);
    // Equipment-specific event handlers
    on<CreateTaskTypeChanged>(_onTaskTypeChanged);
    on<CreateTaskHireDurationTypeChanged>(_onHireDurationTypeChanged);
    on<CreateTaskEstimatedHoursChanged>(_onEstimatedHoursChanged);
    on<CreateTaskEstimatedDurationChanged>(_onEstimatedDurationChanged);
    on<CreateTaskEquipmentUnitsChanged>(_onEquipmentUnitsChanged);
    on<CreateTaskNumberOfTripsChanged>(_onNumberOfTripsChanged);
    on<CreateTaskDistancePerTripChanged>(_onDistancePerTripChanged);
    on<CreateTaskOperatorPreferenceChanged>(_onOperatorPreferenceChanged);
    on<CreateTaskFuelIncludedChanged>(_onFuelIncludedChanged);
    on<CreateTaskRequiredCapacityChanged>(_onRequiredCapacityChanged);
    on<CreateTaskCapacityValueChanged>(_onCapacityValueChanged);
    on<CreateTaskCapacityUnitChanged>(_onCapacityUnitChanged);
    on<CreateTaskProvisionTypeChanged>(_onProvisionTypeChanged);
    on<CreateTaskCostingBasisChanged>(_onCostingBasisChanged);
    on<CreateTaskOtherEquipmentDescriptionChanged>(_onOtherEquipmentDescriptionChanged);
    on<CreateTaskAttachmentAdded>(_onAttachmentAdded);
    on<CreateTaskAttachmentRemoved>(_onAttachmentRemoved);
    on<CreateTaskReset>(_onReset);
    on<CreateTaskSiteVisitRequiredChanged>(_onSiteVisitRequiredChanged);
    on<CreateTaskBOQChanged>(_onBOQChanged);
    on<CreateTaskPlansAdded>(_onPlansAdded);
    on<CreateTaskPlansRemoved>(_onPlansRemoved);
    on<CreateTaskSiteReadinessChanged>(_onSiteReadinessChanged);
    on<CreateTaskProjectSizeChanged>(_onProjectSizeChanged);
    on<CreateTaskTimelineEndChanged>(_onTimelineEndChanged);
    on<CreateTaskSiteVisitDateChanged>(_onSiteVisitDateChanged);
    on<CreateTaskSiteVisitTimeChanged>(_onSiteVisitTimeChanged);
    on<CreateTaskSiteVisitLocationChanged>(_onSiteVisitLocationChanged);
    on<CreateTaskInitialize>(_onInitialize);
  }

  void _onTitleChanged(
    CreateTaskTitleChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(title: event.title));
  }

  void _onDescriptionChanged(
    CreateTaskDescriptionChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _onDateChanged(
    CreateTaskDateChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(date: event.date));
  }

  void _onFlexibleChanged(
    CreateTaskFlexibleChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(isFlexible: event.isFlexible));
  }

  void _onLocationChanged(
    CreateTaskLocationChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(
      location: event.location,
      latitude: event.latitude,
      longitude: event.longitude,
      city: event.city,
      suburb: event.suburb,
      addressDetails: event.addressDetails,
    ));
  }

  void _onBudgetChanged(
    CreateTaskBudgetChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(budget: event.budget));
  }

  void _onPhotoAdded(
    CreateTaskPhotoAdded event,
    Emitter<CreateTaskState> emit,
  ) {
    final updatedPhotos = List<String>.from(state.photos)..add(event.path);
    emit(state.copyWith(photos: updatedPhotos));
  }

  void _onPhotoRemoved(
    CreateTaskPhotoRemoved event,
    Emitter<CreateTaskState> emit,
  ) {
    final updatedPhotos = List<String>.from(state.photos)..removeAt(event.index);
    emit(state.copyWith(photos: updatedPhotos));
  }

  void _onCategoryToggled(
    CreateTaskCategoryToggled event,
    Emitter<CreateTaskState> emit,
  ) {
    if (state.isEquipmentTask) {
      // Equipment tasks generally only have one machine type
      final isOtherEquipment = event.category.toLowerCase().contains('other equipment');
      
      emit(state.copyWith(
        categories: [event.category],
        title: isOtherEquipment ? 'Other Equipment' : event.category,
        requiredCapacityId: null,
        otherEquipmentDescription: isOtherEquipment ? state.otherEquipmentDescription : null,
      ));
      return;
    }

    final currentCategories = List<String>.from(state.categories);
    
    if (currentCategories.contains(event.category)) {
      currentCategories.remove(event.category);
    } else {
      if (currentCategories.length < 3) {
        currentCategories.add(event.category);
      } else {
        return;
      }
    }

    emit(state.copyWith(categories: currentCategories));
  }

  void _onCostingBasisChanged(
    CreateTaskCostingBasisChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    // Determine default duration type based on basis
    String? defaultDurationType;
    if (event.costingBasis == 'time') {
      defaultDurationType = 'daily';
    } else if (event.costingBasis == 'distance') {
      defaultDurationType = 'kilometers';
    } else if (event.costingBasis == 'per_load') {
      defaultDurationType = 'loads';
    }

    emit(state.copyWith(
      costingBasis: event.costingBasis,
      hireDurationType: defaultDurationType,
      estimatedHours: null,
      estimatedDuration: null,
    ));
  }

  void _onOtherEquipmentDescriptionChanged(
    CreateTaskOtherEquipmentDescriptionChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(
      otherEquipmentDescription: event.description,
      title: event.description.isNotEmpty ? event.description : 'Other Equipment',
    ));
  }

  // ============ EQUIPMENT-SPECIFIC HANDLERS ============

  void _onTaskTypeChanged(
    CreateTaskTypeChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(taskType: event.taskType));
  }

  void _onHireDurationTypeChanged(
    CreateTaskHireDurationTypeChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    // Reset hours/duration when type changes
    emit(state.copyWith(
      hireDurationType: event.hireDurationType,
      estimatedHours: null,
      estimatedDuration: null,
    ));
  }

  void _onEstimatedHoursChanged(
    CreateTaskEstimatedHoursChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(estimatedHours: event.estimatedHours));
  }

  void _onEstimatedDurationChanged(
    CreateTaskEstimatedDurationChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(estimatedDuration: event.estimatedDuration));
  }

  void _onEquipmentUnitsChanged(
    CreateTaskEquipmentUnitsChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(equipmentUnits: event.equipmentUnits));
  }

  void _onNumberOfTripsChanged(
    CreateTaskNumberOfTripsChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(numberOfTrips: event.numberOfTrips));
  }

  void _onDistancePerTripChanged(
    CreateTaskDistancePerTripChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(distancePerTrip: event.distancePerTrip));
  }

  void _onOperatorPreferenceChanged(
    CreateTaskOperatorPreferenceChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(operatorPreference: event.operatorPreference));
  }

  void _onFuelIncludedChanged(
    CreateTaskFuelIncludedChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(fuelIncluded: event.fuelIncluded));
  }

  void _onRequiredCapacityChanged(
    CreateTaskRequiredCapacityChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(requiredCapacityId: event.requiredCapacityId));
  }
  
  void _onCapacityValueChanged(
    CreateTaskCapacityValueChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(capacityValue: event.capacityValue));
  }

  void _onCapacityUnitChanged(
    CreateTaskCapacityUnitChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(capacityUnit: event.capacityUnit));
  }

  void _onProvisionTypeChanged(
    CreateTaskProvisionTypeChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(provisionType: event.provisionType));
  }

  void _onAttachmentAdded(
    CreateTaskAttachmentAdded event,
    Emitter<CreateTaskState> emit,
  ) {
    // Limit to 5 attachments
    if (state.attachments.length < 5) {
      emit(state.copyWith(attachments: [...state.attachments, event.path]));
    }
  }

  void _onAttachmentRemoved(
    CreateTaskAttachmentRemoved event,
    Emitter<CreateTaskState> emit,
  ) {
    final updatedAttachments = List<String>.from(state.attachments)
      ..removeAt(event.index);
    emit(state.copyWith(attachments: updatedAttachments));
  }

  void _onReset(
    CreateTaskReset event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(CreateTaskState(taskType: event.taskType ?? 'service'));
  }

  Future<void> _onSubmitted(
    CreateTaskSubmitted event,
    Emitter<CreateTaskState> emit,
  ) async {
    emit(state.copyWith(status: CreateTaskStatus.submitting));
    try {
      // Build task data for API
      final taskData = <String, dynamic>{
        'title': state.title,
        'description': state.description,
        'category': state.categories.isNotEmpty ? state.categories.join(', ') : 'General',
        'budget': state.budget,
        'location': state.location,
        'date_type': state.dateType ?? 'flexible',
        'status': 'open',
        'task_type': state.taskType,
      };

      // Add optional fields
      if (state.date != null) {
        // Backend expects YYYY-MM-DD format
        final d = state.date!;
        taskData['date'] = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }
      if (state.latitude != null) {
        taskData['lat'] = state.latitude!;
      }
      if (state.longitude != null) {
        taskData['lng'] = state.longitude!;
      }
      if (state.timeOfDay != null) {
        taskData['time_of_day'] = state.timeOfDay!;
      }
      if (state.hasSpecificTime) {
        taskData['has_specific_time'] = true;
      }
      if (state.provisionType != null) {
        taskData['provision_type'] = state.provisionType;
      }
      
      // Detailed location
      if (state.city != null) {
        taskData['city'] = state.city;
      }
      if (state.suburb != null) {
        taskData['suburb'] = state.suburb;
      }
      if (state.addressDetails != null) {
        taskData['address_details'] = state.addressDetails;
      }

      // Equipment-specific fields
      if (state.isEquipmentTask) {
        if (state.costingBasis != null) {
          taskData['costing_basis'] = state.costingBasis;
        }
        if (state.hireDurationType != null) {
          taskData['hire_duration_type'] = state.hireDurationType;
        }
        if (state.estimatedHours != null) {
          taskData['estimated_hours'] = state.estimatedHours;
        }
        if (state.estimatedDuration != null) {
          taskData['estimated_duration'] = state.estimatedDuration;
        }
        if (state.equipmentUnits != null) {
          taskData['equipment_units'] = state.equipmentUnits;
        }
        if (state.numberOfTrips != null) {
          taskData['number_of_trips'] = state.numberOfTrips;
        }
        if (state.distancePerTrip != null) {
          taskData['distance_per_trip'] = state.distancePerTrip;
        }
        if (state.operatorPreference != null) {
          taskData['operator_preference'] = state.operatorPreference;
        }
        taskData['fuel_included'] = state.fuelIncluded;
        if (state.requiredCapacityId != null) {
          taskData['required_capacity_id'] = state.requiredCapacityId;
        }
        if (state.capacityValue != null) {
          taskData['capacity_value'] = state.capacityValue;
        }
        if (state.capacityUnit != null) {
          taskData['capacity_unit'] = state.capacityUnit;
        }
        if (state.otherEquipmentDescription != null) {
          taskData['other_equipment_description'] = state.otherEquipmentDescription;
        }
      }

      // Project-specific fields
      if (state.taskType == 'project') {
        taskData['requires_site_visit'] = state.requiresSiteVisit;
        if (state.siteReadiness != null) taskData['site_readiness'] = state.siteReadiness;
        if (state.projectSize != null) taskData['project_size'] = state.projectSize;
        if (state.timelineEnd != null) {
          final d = state.timelineEnd!;
          taskData['timeline_end'] = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        }
        if (state.date != null) {
          final d = state.date!;
          taskData['timeline_start'] = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        }
        if (state.requiresSiteVisit) {
          if (state.siteVisitDate != null) {
            final d = state.siteVisitDate!;
            taskData['site_visit_date'] = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          }
          if (state.siteVisitTime != null) {
            final t = state.siteVisitTime!;
            taskData['site_visit_time'] = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
          }
          if (state.siteVisitAddress != null) {
            taskData['site_visit_address'] = state.siteVisitAddress;
            if (state.siteVisitLat != null) taskData['site_visit_lat'] = state.siteVisitLat;
            if (state.siteVisitLng != null) taskData['site_visit_lng'] = state.siteVisitLng;
          }
        }
      }

      // Update or Create task
      String taskId;
      if (state.taskId != null) {
        // Update existing task
        await _apiService.updateTask(state.taskId!, taskData);
        taskId = state.taskId!;
      } else {
        // Create new task
        taskId = await _apiService.createTask(taskData);
      }
      
      if (taskId.isNotEmpty) {
        // Upload photos if any (only new ones if editing? current implementation re-uploads all if paths are local)
        // For editing, we might need to handle existing URLs vs new local paths.
        // Assuming _apiService handles mixed lists or we filter.
        // However, state.photos might contain URLs now.
        final localPhotos = state.photos.where((p) => !p.startsWith('http')).toList();
        
        if (localPhotos.isNotEmpty) {
          try {
            await _apiService.uploadTaskImages(taskId, localPhotos);
          } catch (e) {
            debugPrint('Error uploading task images: $e');
          }
        }

        // Upload attachments
        final localAttachments = state.attachments.where((p) => !p.startsWith('http')).toList();
        if (localAttachments.isNotEmpty) {
          try {
            await _apiService.uploadTaskAttachments(taskId, localAttachments);
          } catch (e) {
            debugPrint('Error uploading task attachments: $e');
          }
        }

        // Upload project specific files
        if (state.taskType == 'project') {
          if (state.boqPath != null && !state.boqPath!.startsWith('http')) {
            try {
              await _apiService.uploadProjectBOQ(taskId, state.boqPath!);
            } catch (e) {
              debugPrint('Error uploading project BOQ: $e');
            }
          }
          final localPlans = state.plansPaths.where((p) => !p.startsWith('http')).toList();
          if (localPlans.isNotEmpty) {
            try {
              await _apiService.uploadProjectPlans(taskId, localPlans);
            } catch (e) {
              debugPrint('Error uploading project plans: $e');
            }
          }
        }

        emit(state.copyWith(status: CreateTaskStatus.success));
      } else {
        emit(state.copyWith(
          status: CreateTaskStatus.failure,
          errorMessage: 'Failed to save task',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CreateTaskStatus.failure,
        errorMessage: 'Failed to save task: ${e.toString()}',
      ));
    }
  }

  void _onDateTypeChanged(
    CreateTaskDateTypeChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(dateType: event.dateType));
  }

  void _onTimeOfDayChanged(
    CreateTaskTimeOfDayChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(timeOfDay: event.timeOfDay));
  }

  void _onSpecificTimeToggled(
    CreateTaskSpecificTimeToggled event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(hasSpecificTime: event.isEnabled));
  }

  void _onSiteVisitRequiredChanged(
    CreateTaskSiteVisitRequiredChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(requiresSiteVisit: event.requiresSiteVisit));
  }

  void _onBOQChanged(
    CreateTaskBOQChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(boqPath: event.path));
  }

  void _onPlansAdded(
    CreateTaskPlansAdded event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(plansPaths: [...state.plansPaths, event.path]));
  }

  void _onPlansRemoved(
    CreateTaskPlansRemoved event,
    Emitter<CreateTaskState> emit,
  ) {
    final updated = List<String>.from(state.plansPaths)..removeAt(event.index);
    emit(state.copyWith(plansPaths: updated));
  }

  void _onSiteReadinessChanged(
    CreateTaskSiteReadinessChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(siteReadiness: event.siteReadiness));
  }

  void _onProjectSizeChanged(
    CreateTaskProjectSizeChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(projectSize: event.projectSize));
  }

  void _onTimelineEndChanged(
    CreateTaskTimelineEndChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(timelineEnd: event.date));
  }

  void _onSiteVisitDateChanged(
    CreateTaskSiteVisitDateChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(siteVisitDate: event.date));
  }

  void _onSiteVisitTimeChanged(
    CreateTaskSiteVisitTimeChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(siteVisitTime: event.time));
  }

  void _onSiteVisitLocationChanged(
    CreateTaskSiteVisitLocationChanged event,
    Emitter<CreateTaskState> emit,
  ) {
    emit(state.copyWith(
      siteVisitAddress: event.location,
      siteVisitLat: event.latitude,
      siteVisitLng: event.longitude,
    ));
  }

  void _onInitialize(
    CreateTaskInitialize event,
    Emitter<CreateTaskState> emit,
  ) {
    final task = event.task; // Assumed to be Task model
    
    // Determine date type
    String? dateType = 'flexible';
    if (task.date != null) {
      dateType = 'on_date';
    } else if (task.timelineEnd != null) {
      dateType = 'before_date';
    }

    emit(state.copyWith(
      taskId: task.id, // Set taskId for updates
      title: task.title,
      description: task.description,
      categories: [task.category], // Assuming single category for now or parse if comma separated
      budget: task.budget,
      location: task.locationAddress,
      latitude: task.locationCoordinates?.latitude,
      longitude: task.locationCoordinates?.longitude,
      city: task.city,
      suburb: task.suburb,
      photos: task.photos,
      date: task.date,
      dateType: dateType,
      taskType: task.taskType,
      isFlexible: task.date == null,
      // Equipment fields
      equipmentUnits: task.equipmentUnits,
      numberOfTrips: task.numberOfTrips,
      distancePerTrip: task.distancePerTrip,
      otherEquipmentDescription: task.otherEquipmentDescription,
      // Project fields
      requiresSiteVisit: task.requiresSiteVisit ?? false,
      siteReadiness: task.siteReadiness,
      projectSize: task.projectSize,
      timelineEnd: task.timelineEnd,
    ));
  }
}
