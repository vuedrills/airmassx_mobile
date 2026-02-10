import 'user.dart';

class TaskAttachment {
  final String id;
  final String url;
  final String type; // 'image', 'pdf', 'document'
  final String? name;

  TaskAttachment({
    required this.id,
    required this.url,
    required this.type,
    this.name,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String;
    String type = json['type'] as String? ?? '';
    
    if (type.isEmpty || type == 'image') {
      // Robust extension check ignoring query parameters
      final String cleanUrl = url.split('?').first.toLowerCase();
      if (cleanUrl.endsWith('.pdf')) {
        type = 'pdf';
      } else if (cleanUrl.endsWith('.doc') || cleanUrl.endsWith('.docx') || cleanUrl.endsWith('.xls') || cleanUrl.endsWith('.xlsx')) {
        type = 'document';
      } else if (cleanUrl.endsWith('.jpg') || cleanUrl.endsWith('.jpeg') || cleanUrl.endsWith('.png') || cleanUrl.endsWith('.webp')) {
        type = 'image';
      } else {
        type = type.isEmpty ? 'document' : type;
      }
    }

    return TaskAttachment(
      id: json['id'] as String,
      url: url,
      type: type,
      name: json['name'] as String?,
    );
  }
}

class Task {
  final String id;
  final String posterId;
  final String title;
  final String description;
  final String category;
  final String locationAddress;
  final double? locationLat;
  final double? locationLng;
  final String? city;
  final String? suburb;
  final String? addressDetails;
  final List<String> photos;
  final double budget;
  final DateTime? deadline;
  final String status;
  final String? assignedTo;
  final DateTime createdAt;
  final String taskType; // 'service', 'equipment'
  
  // Additional fields for UI
  final String? posterName;
  final String? posterImage;
  final bool? posterVerified;
  final double? posterRating;
  final int offersCount;
  final int questionsCount;
  final int views;
  final String? dateType; // 'on_date', 'before_date', 'flexible'
  final String? timeOfDay; // 'morning', 'midday', 'afternoon', 'evening'
  final bool hasSpecificTime;
  final String? conversationId;
  final String? assignedToName;
  final String? assignedToImage;
  final User? poster;
  final User? assignee;
  final double? capacityValue;
  final String? capacityUnit;

  // Equipment Fields
  final bool? fuelIncluded;
  final String? costingBasis;
  final String? hireDurationType;
  final double? estimatedHours;
  final double? estimatedDuration;
  final int? equipmentUnits;
  final int? numberOfTrips;
  final double? distancePerTrip;
  final List<TaskAttachment> attachments;
  final String? operatorPreference;
  final bool requiresSiteVisit;
  final String? boqUrl;
  final String? plansUrls;
  final DateTime? timelineStart;
  final DateTime? timelineEnd;
  final String? siteReadiness;
  final String? projectSize;

  Task({
    required this.id,
    required this.posterId,
    required this.title,
    required this.description,
    required this.category,
    required this.locationAddress,
    this.locationLat,
    this.locationLng,
    this.photos = const [],
    this.attachments = const [],
    this.city,
    this.suburb,
    this.addressDetails,
    required this.budget,
    this.deadline,
    required this.status,
    this.assignedTo,
    required this.createdAt,
    this.taskType = 'service',
    this.posterName,
    this.posterImage,
    this.posterVerified,
    this.posterRating,
    this.offersCount = 0,
    this.questionsCount = 0,
    this.views = 0,
    this.dateType,
    this.timeOfDay,
    this.hasSpecificTime = false,
    this.conversationId,
    this.assignedToName,
    this.assignedToImage,
    this.poster,
    this.assignee,
    this.capacityValue,
    this.capacityUnit,
    this.fuelIncluded,
    this.costingBasis,
    this.hireDurationType,
    this.estimatedHours,
    this.estimatedDuration,
    this.equipmentUnits,
    this.numberOfTrips,
    this.distancePerTrip,
    this.operatorPreference,
    this.requiresSiteVisit = false,
    this.boqUrl,
    this.plansUrls,
    this.timelineStart,
    this.timelineEnd,
    this.siteReadiness,
    this.projectSize,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    // Extract assignee from accepted_offer.tasker if present
    User? assigneeUser;
    if (json['accepted_offer'] != null && json['accepted_offer']['tasker'] != null) {
      assigneeUser = User.fromJson(json['accepted_offer']['tasker']);
    }

    final attachments = (json['attachments'] as List<dynamic>?)
            ?.map((e) => TaskAttachment.fromJson(e))
            .toList() ?? [];

    return Task(
      id: json['id'] as String,
      posterId: json['poster_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      // Backend sends 'location', not 'location_address'
      locationAddress: (json['location'] ?? json['location_address'] ?? '') as String,
      // Backend sends 'lat'/'lng' directly
      locationLat: _parseDouble(json['lat']),
      locationLng: _parseDouble(json['lng']),
      attachments: attachments,
      photos: (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? 
              attachments.where((a) => a.type.toLowerCase() == 'image').map((a) => a.url).toList(),
      budget: (json['budget'] as num).toDouble(),
      // Backend sends 'date', not 'deadline'
      deadline: _parseDateTime(json['date'] ?? json['deadline']),
      status: json['status'] as String,
      assignedTo: json['assigned_to'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      taskType: json['task_type'] as String? ?? 'service',
      posterName: json['poster_name'] as String?,
      posterImage: json['poster_image'] as String?,
      posterVerified: json['poster_verified'] as bool?,
      posterRating: (json['poster_rating'] as num?)?.toDouble(),
      offersCount: json['offers_count'] ?? json['offer_count'] as int? ?? 0,
      questionsCount: json['questions_count'] ?? json['question_count'] as int? ?? 0,
      views: json['views'] as int? ?? 0,
      dateType: json['date_type'] as String?,
      timeOfDay: json['time_of_day'] as String?,
      hasSpecificTime: json['has_specific_time'] as bool? ?? false,
      conversationId: json['conversation_id'] as String?,
      assignedToName: json['assigned_to_name'] as String?,
      assignedToImage: json['assigned_to_image'] as String?,
      poster: json['poster'] != null ? User.fromJson(json['poster']) : null,
      assignee: assigneeUser,
      capacityValue: _parseDouble(json['capacity_value']),
      capacityUnit: json['capacity_unit'] as String?,
      fuelIncluded: json['fuel_included'] as bool?,
      costingBasis: json['costing_basis'] as String?,
      hireDurationType: json['hire_duration_type'] as String?,
      estimatedHours: _parseDouble(json['estimated_hours']),
      estimatedDuration: _parseDouble(json['estimated_duration']),
      equipmentUnits: json['equipment_units'] as int?,
      numberOfTrips: json['number_of_trips'] as int?,
      distancePerTrip: _parseDouble(json['distance_per_trip']),
      operatorPreference: json['operator_preference'] as String?,
      city: json['city'] as String?,
      suburb: json['suburb'] as String?,
      addressDetails: json['address_details'] as String?,
      requiresSiteVisit: json['requires_site_visit'] as bool? ?? false,
      boqUrl: json['boq_url'] as String?,
      plansUrls: json['plans_urls'] as String?,
      timelineStart: _parseDateTime(json['timeline_start']),
      timelineEnd: _parseDateTime(json['timeline_end']),
      siteReadiness: json['site_readiness'] as String?,
      projectSize: json['project_size'] as String?,
    );
  }

  // Helper to safely parse double from various formats
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is num) return value.toDouble();
    return null;
  }

  // Helper to safely parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poster_id': posterId,
      'title': title,
      'description': description,
      'category': category,
      'location_address': locationAddress,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'photos': photos,
      'budget': budget,
      'deadline': deadline?.toIso8601String(),
      'status': status,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'task_type': taskType,
      'poster_name': posterName,
      'poster_image': posterImage,
      'poster_verified': posterVerified,
      'poster_rating': posterRating,
      'offers_count': offersCount,
      'views': views,
      'date_type': dateType,
      'time_of_day': timeOfDay,
      'has_specific_time': hasSpecificTime,
      'conversation_id': conversationId,
      'assigned_to_name': assignedToName,
      'assigned_to_image': assignedToImage,
      'poster': poster?.toJson(),
      'assignee': assignee?.toJson(),
      'capacity_value': capacityValue,
      'capacity_unit': capacityUnit,
      'fuel_included': fuelIncluded,
      'costing_basis': costingBasis,
      'hire_duration_type': hireDurationType,
      'estimated_hours': estimatedHours,
      'estimated_duration': estimatedDuration,
      'equipment_units': equipmentUnits,
      'number_of_trips': numberOfTrips,
      'distance_per_trip': distancePerTrip,
      'operator_preference': operatorPreference,
      'city': city,
      'suburb': suburb,
      'address_details': addressDetails,
      'requires_site_visit': requiresSiteVisit,
      'boq_url': boqUrl,
      'plans_urls': plansUrls,
      'timeline_start': timelineStart?.toIso8601String(),
      'timeline_end': timelineEnd?.toIso8601String(),
      'site_readiness': siteReadiness,
      'project_size': projectSize,
    };
  }
}
