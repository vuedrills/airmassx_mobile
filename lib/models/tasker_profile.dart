import 'package:equatable/equatable.dart';

class Qualification extends Equatable {
  final String name;        // Qualification type (e.g., National Diploma, BSc)
  final String courseName;  // Course/Program (e.g., Plumbing & Drain Laying)
  final String issuer;      // Institution
  final String date;        // Year obtained
  final String url;         // Proof document URL

  const Qualification({
    required this.name,
    this.courseName = '',
    required this.issuer,
    required this.date,
    required this.url,
  });

  factory Qualification.fromJson(Map<String, dynamic> json) {
    return Qualification(
      name: json['name'] ?? '',
      courseName: json['course_name'] ?? '',
      issuer: json['issuer'] ?? '',
      date: json['date'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'course_name': courseName,
      'issuer': issuer,
      'date': date,
      'url': url,
    };
  }

  @override
  List<Object?> get props => [name, courseName, issuer, date, url];
}

class Availability extends Equatable {
  final List<String> monday;
  final List<String> tuesday;
  final List<String> wednesday;
  final List<String> thursday;
  final List<String> friday;
  final List<String> saturday;
  final List<String> sunday;

  const Availability({
    this.monday = const [],
    this.tuesday = const [],
    this.wednesday = const [],
    this.thursday = const [],
    this.friday = const [],
    this.saturday = const [],
    this.sunday = const [],
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      monday: List<String>.from(json['monday'] ?? []),
      tuesday: List<String>.from(json['tuesday'] ?? []),
      wednesday: List<String>.from(json['wednesday'] ?? []),
      thursday: List<String>.from(json['thursday'] ?? []),
      friday: List<String>.from(json['friday'] ?? []),
      saturday: List<String>.from(json['saturday'] ?? []),
      sunday: List<String>.from(json['sunday'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
      'saturday': saturday,
      'sunday': sunday,
    };
  }

  @override
  List<Object?> get props => [monday, tuesday, wednesday, thursday, friday, saturday, sunday];
}

class TaskerProfile extends Equatable {
  final String userId;
  final String status; // not_started, in_progress, pending_review, approved
  final int onboardingStep;
  final String? professionalType; // artisanal, white_collar
  final String? bio;
  final String? profilePictureUrl;
  final String? ecocashNumber;
  final String? addressDocumentUrl;
  final List<String> idDocumentUrls;
  final List<String> professionIds;
  final List<String> portfolioUrls;
  final List<Qualification> qualifications;
  final Availability availability;
  
  // Primary Location
  final String primaryCity;
  final String primarySuburb;
  final String primaryAddress;
  final double? primaryLatitude;
  final double? primaryLongitude;

  const TaskerProfile({
    required this.userId,
    this.status = 'not_started',
    this.onboardingStep = 1,
    this.professionalType,
    this.bio,
    this.profilePictureUrl,
    this.ecocashNumber,
    this.addressDocumentUrl,
    this.idDocumentUrls = const [],
    this.professionIds = const [],
    this.portfolioUrls = const [],
    this.qualifications = const [],
    this.availability = const Availability(),
    this.primaryCity = '',
    this.primarySuburb = '',
    this.primaryAddress = '',
    this.primaryLatitude,
    this.primaryLongitude,
  });

  TaskerProfile copyWith({
    String? userId,
    String? status,
    int? onboardingStep,
    String? professionalType,
    String? bio,
    String? profilePictureUrl,
    String? ecocashNumber,
    String? addressDocumentUrl,
    List<String>? idDocumentUrls,
    List<String>? professionIds,
    List<String>? portfolioUrls,
    List<Qualification>? qualifications,
    Availability? availability,
    String? primaryCity,
    String? primarySuburb,
    String? primaryAddress,
    double? primaryLatitude,
    double? primaryLongitude,
  }) {
    return TaskerProfile(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      professionalType: professionalType ?? this.professionalType,
      bio: bio ?? this.bio,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      ecocashNumber: ecocashNumber ?? this.ecocashNumber,
      addressDocumentUrl: addressDocumentUrl ?? this.addressDocumentUrl,
      idDocumentUrls: idDocumentUrls ?? this.idDocumentUrls,
      professionIds: professionIds ?? this.professionIds,
      portfolioUrls: portfolioUrls ?? this.portfolioUrls,
      qualifications: qualifications ?? this.qualifications,
      availability: availability ?? this.availability,
      primaryCity: primaryCity ?? this.primaryCity,
      primarySuburb: primarySuburb ?? this.primarySuburb,
      primaryAddress: primaryAddress ?? this.primaryAddress,
      primaryLatitude: primaryLatitude ?? this.primaryLatitude,
      primaryLongitude: primaryLongitude ?? this.primaryLongitude,
    );
  }

  factory TaskerProfile.fromJson(Map<String, dynamic> json) {
    return TaskerProfile(
      userId: json['user_id'] ?? '',
      status: json['status'] ?? 'not_started',
      onboardingStep: json['onboarding_step'] ?? 1,
      professionalType: json['professional_type'],
      bio: json['bio'],
      profilePictureUrl: json['profile_picture_url'],
      ecocashNumber: json['ecocash_number'],
      addressDocumentUrl: json['address_document_url'],
      idDocumentUrls: List<String>.from(json['id_document_urls'] ?? []),
      professionIds: List<String>.from(json['profession_ids'] ?? []),
      portfolioUrls: List<String>.from(json['portfolio_urls'] ?? []),
      qualifications: (json['qualifications'] as List<dynamic>?)
              ?.map((e) => Qualification.fromJson(e))
              .toList() ??
          [],
      availability: json['availability'] != null
          ? Availability.fromJson(json['availability'])
          : const Availability(),
      primaryCity: json['primary_city'] ?? '',
      primarySuburb: json['primary_suburb'] ?? '',
      primaryAddress: json['primary_address'] ?? '',
      primaryLatitude: (json['primary_latitude'] as num?)?.toDouble(),
      primaryLongitude: (json['primary_longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'status': status,
      'onboarding_step': onboardingStep,
      'professional_type': professionalType,
      'bio': bio,
      'profile_picture_url': profilePictureUrl,
      'ecocash_number': ecocashNumber,
      'address_document_url': addressDocumentUrl,
      'id_document_urls': idDocumentUrls,
      'profession_ids': professionIds,
      'portfolio_urls': portfolioUrls,
      'qualifications': qualifications.map((e) => e.toJson()).toList(),
      'availability': availability.toJson(),
      'primary_city': primaryCity,
      'primary_suburb': primarySuburb,
      'primary_address': primaryAddress,
      'primary_latitude': primaryLatitude,
      'primary_longitude': primaryLongitude,
    };
  }

  @override
  List<Object?> get props => [
        userId,
        status,
        onboardingStep,
        professionalType,
        bio,
        profilePictureUrl,
        ecocashNumber,
        addressDocumentUrl,
        idDocumentUrls,
        professionIds,
        portfolioUrls,
        qualifications,
        availability,
        primaryCity,
        primarySuburb,
        primaryAddress,
        primaryLatitude,
        primaryLongitude,
      ];
}

