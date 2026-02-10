import 'package:equatable/equatable.dart';
import '../../models/user_profile.dart';
import '../../models/payment_method.dart';
import '../../models/payment_transaction.dart';
import '../../models/notification_settings.dart';

/// Profile states
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ProfileInitial extends ProfileState {}

/// Loading profile
class ProfileLoading extends ProfileState {}

/// Profile loaded
class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  final NotificationSettings notificationSettings;

  const ProfileLoaded({
    required this.profile,
    required this.notificationSettings,
  });

  @override
  List<Object?> get props => [profile, notificationSettings];
}

/// Profile updating
class ProfileUpdating extends ProfileState {}

/// Profile updated successfully
class ProfileUpdated extends ProfileState {
  final UserProfile profile;

  const ProfileUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Payment methods loaded
class PaymentMethodsLoaded extends ProfileState {
  final List<PaymentMethod> methods;

  const PaymentMethodsLoaded(this.methods);

  @override
  List<Object?> get props => [methods];
}

/// Payment history loaded
class PaymentHistoryLoaded extends ProfileState {
  final List<PaymentTransaction> transactions;

  const PaymentHistoryLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

/// Profile error
class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
