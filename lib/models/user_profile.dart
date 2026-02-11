import 'package:equatable/equatable.dart';
import 'tasker_profile.dart';
import 'badge.dart';

/// Comprehensive user profile model
class UserProfile extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final String? bio;
  final List<String> skills;
  final double rating;
  final int totalReviews;
  final int completedTasks;
  final int tasksCompletedOnTime;
  final double completionRate;
  final double totalEarnings;
  final bool isVerified;
  final String? verificationType;
  
  // Work info
  final String? jobTitle;
  final String? company;
  
  // Address info
  final String? address;
  final String? city;
  final String? suburb;
  final String? country;
  final String? postcode;
  final double? latitude;
  final double? longitude;
  final DateTime? dateOfBirth;
  
  // New fields
  final TaskerProfile? taskerProfile;
  final List<UserBadge> badges;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.bio,
    this.skills = const [],
    this.rating = 0.0,
    this.totalReviews = 0,
    this.completedTasks = 0,
    this.tasksCompletedOnTime = 0,
    this.completionRate = 0.0,
    this.totalEarnings = 0.0,
    this.isVerified = false,
    this.verificationType,
    this.jobTitle,
    this.company,
    this.address,
    this.city,
    this.suburb,
    this.country,
    this.postcode,
    this.latitude,
    this.longitude,
    this.dateOfBirth,
    this.taskerProfile,
    this.badges = const [],
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? bio,
    List<String>? skills,
    double? rating,
    int? totalReviews,
    int? completedTasks,
    int? tasksCompletedOnTime,
    double? completionRate,
    double? totalEarnings,
    bool? isVerified,
    String? verificationType,
    String? jobTitle,
    String? company,
    String? address,
    String? city,
    String? suburb,
    String? country,
    String? postcode,
    double? latitude,
    double? longitude,
    DateTime? dateOfBirth,
    TaskerProfile? taskerProfile,
    List<UserBadge>? badges,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      completedTasks: completedTasks ?? this.completedTasks,
      tasksCompletedOnTime: tasksCompletedOnTime ?? this.tasksCompletedOnTime,
      completionRate: completionRate ?? this.completionRate,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      isVerified: isVerified ?? this.isVerified,
      verificationType: verificationType ?? this.verificationType,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      address: address ?? this.address,
      city: city ?? this.city,
      suburb: suburb ?? this.suburb,
      country: country ?? this.country,
      postcode: postcode ?? this.postcode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      taskerProfile: taskerProfile ?? this.taskerProfile,
      badges: badges ?? this.badges,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'bio': bio,
      'skills': skills,
      'rating': rating,
      'totalReviews': totalReviews,
      'completedTasks': completedTasks,
      'tasksCompletedOnTime': tasksCompletedOnTime,
      'completionRate': completionRate,
      'totalEarnings': totalEarnings,
      'isVerified': isVerified,
      'verificationType': verificationType,
      'jobTitle': jobTitle,
      'company': company,
      'address': address,
      'city': city,
      'suburb': suburb,
      'country': country,
      'postcode': postcode,
      'latitude': latitude,
      'longitude': longitude,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      profileImage: json['profileImage'] as String?,
      bio: json['bio'] as String?,
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      completedTasks: json['completedTasks'] as int? ?? 0,
      tasksCompletedOnTime: json['tasksCompletedOnTime'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationType: json['verificationType'] as String?,
      jobTitle: json['jobTitle'] as String?,
      company: json['company'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      suburb: json['suburb'] as String?,
      country: json['country'] as String?,
      postcode: json['postcode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      dateOfBirth: (json['date_of_birth'] ?? json['dateOfBirth']) != null
          ? DateTime.parse((json['date_of_birth'] ?? json['dateOfBirth']) as String)
          : null,
      taskerProfile: json['tasker_profile'] != null || json['taskerProfile'] != null
          ? TaskerProfile.fromJson(json['tasker_profile'] ?? json['taskerProfile'])
          : null,
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => UserBadge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get isProfessional => taskerProfile?.status == 'approved';
  bool get isProfessionalPending => taskerProfile?.status == 'pending_review';

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        profileImage,
        bio,
        skills,
        rating,
        totalReviews,
        completedTasks,
        tasksCompletedOnTime,
        completionRate,
        totalEarnings,
        isVerified,
        verificationType,
        jobTitle,
        company,
        address,
        city,
        suburb,
        country,
        postcode,
        latitude,
        longitude,
        dateOfBirth,
        taskerProfile,
        badges,
      ];
}
