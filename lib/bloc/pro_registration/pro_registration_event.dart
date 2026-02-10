import 'package:equatable/equatable.dart';

abstract class ProRegistrationEvent extends Equatable {
  const ProRegistrationEvent();
  @override
  List<Object?> get props => [];
}

class ProRegistrationStepChanged extends ProRegistrationEvent {
  final int step;
  const ProRegistrationStepChanged(this.step);
  @override
  List<Object?> get props => [step];
}

class ProRegistrationBasicInfoUpdated extends ProRegistrationEvent {
  final String? name;
  final String? phone;
  final String? bio;
  final String? profilePictureUrl;
  final String? professionalType;

  const ProRegistrationBasicInfoUpdated({
    this.name,
    this.phone,
    this.bio,
    this.profilePictureUrl,
    this.professionalType,
  });

  @override
  List<Object?> get props => [name, phone, bio, profilePictureUrl, professionalType];
}

class ProRegistrationIdentityUpdated extends ProRegistrationEvent {
  final List<String> idDocumentUrls;

  const ProRegistrationIdentityUpdated({
    required this.idDocumentUrls,
  });

  @override
  List<Object?> get props => [idDocumentUrls];
}

class ProRegistrationProfessionsUpdated extends ProRegistrationEvent {
  final List<String> professionIds;

  const ProRegistrationProfessionsUpdated(this.professionIds);

  @override
  List<Object?> get props => [professionIds];
}

class ProRegistrationPortfolioUpdated extends ProRegistrationEvent {
  final List<String> portfolioUrls;

  const ProRegistrationPortfolioUpdated(this.portfolioUrls);

  @override
  List<Object?> get props => [portfolioUrls];
}

class ProRegistrationQualificationAdded extends ProRegistrationEvent {
  final String name;
  final String courseName;
  final String issuer;
  final String date;
  final String url;

  const ProRegistrationQualificationAdded({
    required this.name,
    this.courseName = '',
    required this.issuer,
    required this.date,
    required this.url,
  });

  @override
  List<Object?> get props => [name, courseName, issuer, date, url];
}

class ProRegistrationQualificationRemoved extends ProRegistrationEvent {
  final int index;
  const ProRegistrationQualificationRemoved(this.index);
  @override
  List<Object?> get props => [index];
}

class ProRegistrationPaymentUpdated extends ProRegistrationEvent {
  final String ecocashNumber;

  const ProRegistrationPaymentUpdated(this.ecocashNumber);

  @override
  List<Object?> get props => [ecocashNumber];
}

class ProRegistrationLocationUpdated extends ProRegistrationEvent {
  final String city;
  final String suburb;
  final String address;
  final double? latitude;
  final double? longitude;

  const ProRegistrationLocationUpdated({
    required this.city,
    required this.suburb,
    required this.address,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [city, suburb, address, latitude, longitude];
}

class ProRegistrationSubmitted extends ProRegistrationEvent {}

