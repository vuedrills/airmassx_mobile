import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/tasker_profile.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import 'pro_registration_event.dart';
import 'pro_registration_state.dart';

class ProRegistrationBloc extends Bloc<ProRegistrationEvent, ProRegistrationState> {
  final ApiService _apiService;
  final String? existingName;
  final String? existingPhone;
  final String? existingBio;
  final String? existingProfilePicture;

  final UserProfile? initialProfile;

  ProRegistrationBloc(
    this._apiService, {
    this.initialProfile,
    this.existingName,
    this.existingPhone,
    this.existingBio,
    this.existingProfilePicture,
  }) : super(ProRegistrationState(
          name: initialProfile?.name ?? existingName ?? '',
          phone: initialProfile?.phone ?? existingPhone ?? '',
          bio: initialProfile?.taskerProfile?.bio ?? initialProfile?.bio ?? existingBio ?? '',
          profilePictureUrl: initialProfile?.taskerProfile?.profilePictureUrl ?? initialProfile?.profileImage ?? existingProfilePicture,
          professionalType: initialProfile?.taskerProfile?.professionalType,
          idDocumentUrls: initialProfile?.taskerProfile?.idDocumentUrls ?? const [],
          professionIds: initialProfile?.taskerProfile?.professionIds ?? const [],
          portfolioUrls: initialProfile?.taskerProfile?.portfolioUrls ?? const [],
          qualifications: initialProfile?.taskerProfile?.qualifications ?? const [],
          primaryCity: initialProfile?.taskerProfile?.primaryCity ?? '',
          primarySuburb: initialProfile?.taskerProfile?.primarySuburb ?? '',
          primaryAddress: initialProfile?.taskerProfile?.primaryAddress ?? '',
          primaryLatitude: initialProfile?.taskerProfile?.primaryLatitude,
          primaryLongitude: initialProfile?.taskerProfile?.primaryLongitude,
          ecocashNumber: initialProfile?.taskerProfile?.ecocashNumber ?? '',
        )) {
    on<ProRegistrationStepChanged>(_onStepChanged);
    on<ProRegistrationBasicInfoUpdated>(_onBasicInfoUpdated);
    on<ProRegistrationIdentityUpdated>(_onIdentityUpdated);
    on<ProRegistrationProfessionsUpdated>(_onProfessionsUpdated);
    on<ProRegistrationPortfolioUpdated>(_onPortfolioUpdated);
    on<ProRegistrationQualificationAdded>(_onQualificationAdded);
    on<ProRegistrationQualificationRemoved>(_onQualificationRemoved);
    on<ProRegistrationPaymentUpdated>(_onPaymentUpdated);
    on<ProRegistrationLocationUpdated>(_onLocationUpdated);
    on<ProRegistrationSubmitted>(_onSubmitted);
  }

  void _onStepChanged(
    ProRegistrationStepChanged event,
    Emitter<ProRegistrationState> emit,
  ) {
    emit(state.copyWith(currentStep: event.step));
  }

  void _onBasicInfoUpdated(
    ProRegistrationBasicInfoUpdated event,
    Emitter<ProRegistrationState> emit,
  ) {
    emit(state.copyWith(
      name: event.name ?? state.name,
      phone: event.phone ?? state.phone,
      bio: event.bio ?? state.bio,
      profilePictureUrl: event.profilePictureUrl ?? state.profilePictureUrl,
      professionalType: event.professionalType ?? state.professionalType,
    ));
  }

  void _onIdentityUpdated(
    ProRegistrationIdentityUpdated event,
    Emitter<ProRegistrationState> emit,
  ) {
    emit(state.copyWith(
      idDocumentUrls: event.idDocumentUrls,
    ));
  }

  void _onProfessionsUpdated(
    ProRegistrationProfessionsUpdated event,
    Emitter<ProRegistrationState> emit,
  ) {
    emit(state.copyWith(professionIds: event.professionIds));
  }

  void _onPortfolioUpdated(
    ProRegistrationPortfolioUpdated event,
    Emitter<ProRegistrationState> emit,
  ) {
    emit(state.copyWith(portfolioUrls: event.portfolioUrls));
  }

  void _onQualificationAdded(
    ProRegistrationQualificationAdded event,
    Emitter<ProRegistrationState> emit,
  ) {
    final newQualification = Qualification(
      name: event.name,
      courseName: event.courseName,
      issuer: event.issuer,
      date: event.date,
      url: event.url,
    );
    final updatedList = [...state.qualifications, newQualification];
    emit(state.copyWith(qualifications: updatedList));
  }

  void _onQualificationRemoved(
    ProRegistrationQualificationRemoved event,
    Emitter<ProRegistrationState> emit,
  ) {
    final updatedList = List<Qualification>.from(state.qualifications)
      ..removeAt(event.index);
    emit(state.copyWith(qualifications: updatedList));
  }

  void _onPaymentUpdated(
    ProRegistrationPaymentUpdated event,
    Emitter<ProRegistrationState> emit,
  ) {
    emit(state.copyWith(ecocashNumber: event.ecocashNumber));
  }

  void _onLocationUpdated(
    ProRegistrationLocationUpdated event,
    Emitter<ProRegistrationState> emit,
  ) {
    emit(state.copyWith(
      primaryCity: event.city,
      primarySuburb: event.suburb,
      primaryAddress: event.address,
      primaryLatitude: event.latitude,
      primaryLongitude: event.longitude,
    ));
  }

  Future<void> _onSubmitted(
    ProRegistrationSubmitted event,
    Emitter<ProRegistrationState> emit,
  ) async {
    emit(state.copyWith(status: ProRegistrationStatus.loading));
    
    try {
      final profileData = {
        'bio': state.bio,
        'profile_picture_url': state.profilePictureUrl,
        'professional_type': state.professionalType,
        'ecocash_number': state.ecocashNumber,
        'id_document_urls': state.idDocumentUrls,
        'profession_ids': state.professionIds,
        'portfolio_urls': state.portfolioUrls,
        'qualifications': state.qualifications.map((q) => q.toJson()).toList(),
        'primary_city': state.primaryCity,
        'primary_suburb': state.primarySuburb,
        'primary_address': state.primaryAddress,
        'primary_latitude': state.primaryLatitude,
        'primary_longitude': state.primaryLongitude,
        'status': 'pending_review',
        'onboarding_step': 7,
      };

      await _apiService.updateTaskerProfile(profileData);
      emit(state.copyWith(status: ProRegistrationStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: ProRegistrationStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}

