import 'badge.dart';
import 'portfolio_item.dart';
import 'review.dart';
import 'tasker_profile.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? profileImage;
  final String? bio;
  final List<String> skills;
  final double rating;
  final int totalReviews;
  final bool isVerified;
  final String? verificationType;
  final String userType; // 'tasker' or 'poster'

  final List<PortfolioItem> portfolio;
  final List<Review> reviews;
  final Map<String, double> ratingCategories;
  final DateTime memberSince;
  final bool isTasker;
  final TaskerProfile? taskerProfile;
  final String? address;
  final String? city;
  final String? suburb;
  final String? country;
  final String? postcode;
  final double? latitude;
  final double? longitude;
  final DateTime? dateOfBirth;
  final List<UserBadge> badges;
  final int tasksCompleted;
  final int tasksPostedCompleted;
  final int tasksCompletedOnTime;
  final String? businessName;
  final String? businessAddress;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.profileImage,
    this.bio,
    this.skills = const [],
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isVerified = false,
    this.verificationType,
    this.portfolio = const [],
    this.reviews = const [],
    this.ratingCategories = const {},
    this.userType = 'tasker',
    this.isTasker = false,
    this.taskerProfile,
    this.address,
    this.city,
    this.suburb,
    this.country,
    this.postcode,
    this.latitude,
    this.longitude,
    this.dateOfBirth,
    this.badges = const [],
    this.tasksCompleted = 0,
    this.tasksPostedCompleted = 0,
    this.tasksCompletedOnTime = 0,
    this.businessName,
    this.businessAddress,
    DateTime? memberSince,
  }) : memberSince = memberSince ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      profileImage: json['profile_image'] as String?,
      bio: json['bio'] as String?,
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      verificationType: json['verification_type'] as String?,
      portfolio: (json['portfolio'] as List<dynamic>?)
              ?.map((e) => PortfolioItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ratingCategories: (json['rating_categories'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      userType: json['user_type'] as String? ?? 'tasker',
      isTasker: json['is_tasker'] as bool? ?? false,
      taskerProfile: json['tasker_profile'] != null
          ? TaskerProfile.fromJson(json['tasker_profile'])
          : null,
      memberSince: json['member_since'] != null
          ? DateTime.parse(json['member_since'] as String)
          : null,
      address: json['address'] as String?,
      city: json['city'] as String?,
      suburb: json['suburb'] as String?,
      country: json['country'] as String?,
      postcode: json['postcode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => UserBadge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tasksCompleted: json['tasks_completed'] as int? ?? 0,
      tasksPostedCompleted: json['tasks_posted_completed'] as int? ?? 0,
      tasksCompletedOnTime: json['tasks_completed_on_time'] as int? ?? 0,
      businessName: json['business_name'] as String?,
      businessAddress: json['business_address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
'email': email,
      'name': name,
      'phone': phone,
      'profile_image': profileImage,
      'bio': bio,
      'skills': skills,
      'rating': rating,
      'total_reviews': totalReviews,
      'is_verified': isVerified,
      'verification_type': verificationType,
      'portfolio': portfolio.map((e) => e.toJson()).toList(),
      'reviews': reviews.map((e) => e.toJson()).toList(),
      'rating_categories': ratingCategories,
      'user_type': userType,
      'is_tasker': isTasker,
      'tasker_profile': taskerProfile?.toJson(),
      'member_since': memberSince.toIso8601String(),
      'address': address,
      'city': city,
      'suburb': suburb,
       'country': country,
      'postcode': postcode,
      'latitude': latitude,
      'longitude': longitude,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'badges': badges.map((e) => e.toJson()).toList(),
      'tasks_completed': tasksCompleted,
      'tasks_posted_completed': tasksPostedCompleted,
      'tasks_completed_on_time': tasksCompletedOnTime,
      'business_name': businessName,
      'business_address': businessAddress,
    };
  }
  bool get isProfessional => taskerProfile?.status == 'approved';
  bool get isIdVerifiedOnly => isVerified && !isProfessional;

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profileImage,
    String? bio,
    List<String>? skills,
    double? rating,
    int? totalReviews,
    bool? isVerified,
    String? verificationType,
    List<PortfolioItem>? portfolio,
    List<Review>? reviews,
    Map<String, double>? ratingCategories,
    String? userType,
    bool? isTasker,
    TaskerProfile? taskerProfile,
    DateTime? memberSince,
    String? address,
    String? city,
    String? suburb,
    String? country,
     String? postcode,
    double? latitude,
    double? longitude,
    DateTime? dateOfBirth,
    List<UserBadge>? badges,
    int? tasksCompleted,
    int? tasksPostedCompleted,
    int? tasksCompletedOnTime,
    String? businessName,
    String? businessAddress,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isVerified: isVerified ?? this.isVerified,
      verificationType: verificationType ?? this.verificationType,
      portfolio: portfolio ?? this.portfolio,
      reviews: reviews ?? this.reviews,
      ratingCategories: ratingCategories ?? this.ratingCategories,
      userType: userType ?? this.userType,
      isTasker: isTasker ?? this.isTasker,
      taskerProfile: taskerProfile ?? this.taskerProfile,
      memberSince: memberSince ?? this.memberSince,
      address: address ?? this.address,
      city: city ?? this.city,
      suburb: suburb ?? this.suburb,
      country: country ?? this.country,
       postcode: postcode ?? this.postcode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      badges: badges ?? this.badges,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      tasksPostedCompleted: tasksPostedCompleted ?? this.tasksPostedCompleted,
      tasksCompletedOnTime: tasksCompletedOnTime ?? this.tasksCompletedOnTime,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
    );
  }
}
