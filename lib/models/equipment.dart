import 'package:equatable/equatable.dart';

/// Equipment model for rental items
class Equipment extends Equatable {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerImage;
  final String title;
  final String description;
  final String category;
  final double pricePerDay;
  final double pricePerWeek;
  final String? location;
  final List<String> photos;
  final String status; // available, rented, unavailable
  final double rating;
  final int reviewCount;
  final DateTime createdAt;

  const Equipment({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerImage,
    required this.title,
    required this.description,
    required this.category,
    required this.pricePerDay,
    this.pricePerWeek = 0,
    this.location,
    this.photos = const [],
    this.status = 'available',
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
  });

  Equipment copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? ownerImage,
    String? title,
    String? description,
    String? category,
    double? pricePerDay,
    double? pricePerWeek,
    String? location,
    List<String>? photos,
    String? status,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerImage: ownerImage ?? this.ownerImage,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      pricePerWeek: pricePerWeek ?? this.pricePerWeek,
      location: location ?? this.location,
      photos: photos ?? this.photos,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'owner_image': ownerImage,
      'title': title,
      'description': description,
      'category': category,
      'price_per_day': pricePerDay,
      'price_per_week': pricePerWeek,
      'location': location,
      'photos': photos,
      'status': status,
      'rating': rating,
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Equipment.fromJson(Map<String, dynamic> json) {
    // Backend uses 'name' not 'title', 'user_id' not 'owner_id', and 'daily_rate' not 'price_per_day'
    final photos = json['photos'] as List<dynamic>? ?? [];
    
    // Determine status from is_available
    String status = 'available';
    if (json['status'] != null) {
      status = json['status'] as String;
    } else if (json['is_available'] != null) {
      status = json['is_available'] == true ? 'available' : 'unavailable';
    }
    
    return Equipment(
      id: json['id'] as String,
      ownerId: (json['owner_id'] ?? json['user_id'] ?? '') as String,
      ownerName: (json['owner_name'] ?? '') as String,
      ownerImage: json['owner_image'] as String?,
      title: (json['title'] ?? json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      pricePerDay: _parseDouble(json['price_per_day'] ?? json['daily_rate']),
      pricePerWeek: _parseDouble(json['price_per_week'] ?? json['weekly_rate']),
      location: json['location'] as String?,
      photos: photos.cast<String>(),
      status: status,
      rating: _parseDouble(json['rating']),
      reviewCount: json['review_count'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    return 0.0;
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        ownerName,
        ownerImage,
        title,
        description,
        category,
        pricePerDay,
        pricePerWeek,
        location,
        photos,
        status,
        rating,
        reviewCount,
        createdAt,
      ];
}
