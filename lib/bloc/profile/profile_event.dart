import 'package:equatable/equatable.dart';
import '../../models/user_profile.dart';
import '../../models/payment_method.dart';
import '../../models/notification_settings.dart';

/// Profile events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Load user profile
class LoadProfile extends ProfileEvent {}

/// Update profile information
class UpdateProfile extends ProfileEvent {
  final UserProfile profile;

  const UpdateProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Update profile avatar
class UpdateAvatar extends ProfileEvent {
  final String imagePath;

  const UpdateAvatar(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

/// Update notification settings
class UpdateNotificationSettings extends ProfileEvent {
  final NotificationSettings settings;

  const UpdateNotificationSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}

/// Load payment methods
class LoadPaymentMethods extends ProfileEvent {}

/// Add payment method
class AddPaymentMethod extends ProfileEvent {
  final PaymentMethod method;

  const AddPaymentMethod(this.method);

  @override
  List<Object?> get props => [method];
}

/// Remove payment method
class RemovePaymentMethod extends ProfileEvent {
  final String methodId;

  const RemovePaymentMethod(this.methodId);

  @override
  List<Object?> get props => [methodId];
}

/// Set default payment method
class SetDefaultPaymentMethod extends ProfileEvent {
  final String methodId;

  const SetDefaultPaymentMethod(this.methodId);

  @override
  List<Object?> get props => [methodId];
}

/// Load payment history
class LoadPaymentHistory extends ProfileEvent {}
