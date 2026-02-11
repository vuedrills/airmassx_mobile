import 'package:equatable/equatable.dart';
import '../../models/tasker_profile.dart';

enum ProRegistrationStatus { initial, loading, success, failure }

class ProRegistrationState extends Equatable {
  final int currentStep;
  final ProRegistrationStatus status;
  final String? errorMessage;

  // Step 1: Basic Info
  final String name;
  final String phone;
  final String bio;
  final String? profilePictureUrl;
  final String? professionalType; // artisanal, white_collar

  // Step 2: Identity
  final List<String> idDocumentUrls;

  // Step 3: Professions
  final List<String> professionIds;

  // Step 4: Portfolio
  final List<String> portfolioUrls;

  // Step 5: Qualifications
  final List<Qualification> qualifications;

  // Step 6: Location
  final String primaryCity;
  final String primarySuburb;
  final String primaryAddress;
  final double? primaryLatitude;
  final double? primaryLongitude;

  // Step 7: Payment
  final String ecocashNumber;

  const ProRegistrationState({
    this.currentStep = 1,
    this.status = ProRegistrationStatus.initial,
    this.errorMessage,
    this.name = '',
    this.phone = '',
    this.bio = '',
    this.profilePictureUrl,
    this.professionalType,
    this.idDocumentUrls = const [],
    this.professionIds = const [],
    this.portfolioUrls = const [],
    this.qualifications = const [],
    this.primaryCity = '',
    this.primarySuburb = '',
    this.primaryAddress = '',
    this.primaryLatitude,
    this.primaryLongitude,
    this.ecocashNumber = '',
  });

  ProRegistrationState copyWith({
    int? currentStep,
    ProRegistrationStatus? status,
    String? errorMessage,
    String? name,
    String? phone,
    String? bio,
    String? profilePictureUrl,
    String? professionalType,
    List<String>? idDocumentUrls,
    List<String>? professionIds,
    List<String>? portfolioUrls,
    List<Qualification>? qualifications,
    String? primaryCity,
    String? primarySuburb,
    String? primaryAddress,
    double? primaryLatitude,
    double? primaryLongitude,
    String? ecocashNumber,
  }) {
    return ProRegistrationState(
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      professionalType: professionalType ?? this.professionalType,
      idDocumentUrls: idDocumentUrls ?? this.idDocumentUrls,
      professionIds: professionIds ?? this.professionIds,
      portfolioUrls: portfolioUrls ?? this.portfolioUrls,
      qualifications: qualifications ?? this.qualifications,
      primaryCity: primaryCity ?? this.primaryCity,
      primarySuburb: primarySuburb ?? this.primarySuburb,
      primaryAddress: primaryAddress ?? this.primaryAddress,
      primaryLatitude: primaryLatitude ?? this.primaryLatitude,
      primaryLongitude: primaryLongitude ?? this.primaryLongitude,
      ecocashNumber: ecocashNumber ?? this.ecocashNumber,
    );
  }

  // Validation helpers
  // Step 1: Name is required, phone is now optional
  bool get isStep1Valid => name.isNotEmpty;
  bool get isStep2Valid => idDocumentUrls.isNotEmpty;
  bool get isStep3Valid => professionIds.isNotEmpty;
  bool get isStep4Valid => true; // Portfolio is optional
  bool get isStep5Valid => true; // Qualifications are optional
  bool get isStep6Valid => 
      primaryCity.isNotEmpty && 
      primaryLatitude != null && 
      primaryLongitude != null &&
      primaryLatitude != 0 &&
      primaryLongitude != 0; // Location is required
  bool get isStep7Valid => true; // EcoCash is now optional for submission

  // Can submit as long as core requirements are met
  // EcoCash can be added later before first payout
  bool get canSubmit =>
      isStep1Valid &&
      isStep2Valid &&
      isStep3Valid &&
      isStep6Valid;

  @override
  List<Object?> get props => [
        currentStep,
        status,
        errorMessage,
        name,
        phone,
        bio,
        profilePictureUrl,
        professionalType,
        idDocumentUrls,
        professionIds,
        portfolioUrls,
        qualifications,
        primaryCity,
        primarySuburb,
        primaryAddress,
        primaryLatitude,
        primaryLongitude,
        ecocashNumber,
      ];
}
