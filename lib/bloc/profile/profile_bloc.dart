import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../models/user_profile.dart';
import '../../models/notification_settings.dart';
import '../../models/payment_method.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'profile_event.dart';
import 'profile_state.dart';

/// Profile BLoC - Handles profile-related state management
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ApiService _apiService;

  ProfileBloc(this._apiService) : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UpdateAvatar>(_onUpdateAvatar);
    on<UpdateNotificationSettings>(_onUpdateNotificationSettings);
    on<LoadPaymentMethods>(_onLoadPaymentMethods);
    on<AddPaymentMethod>(_onAddPaymentMethod);
    on<RemovePaymentMethod>(_onRemovePaymentMethod);
    on<SetDefaultPaymentMethod>(_onSetDefaultPaymentMethod);
    on<LoadPaymentHistory>(_onLoadPaymentHistory);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    print('ProfileBloc: _onLoadProfile started');
    emit(ProfileLoading());
    try {
      print('ProfileBloc: Calling _apiService.getCurrentUser()');
      final user = await _apiService.getCurrentUser(forceRefresh: true);
      print('ProfileBloc: _apiService.getCurrentUser() returned: ${user?.name}');
      
      if (user == null) {
        throw Exception('User data not found');
      }
      
      // Create UserProfile from User
      // Calculate completion rate: tasks completed on time / total tasks completed
      double completionRate = 0.0;
      if (user.tasksCompleted > 0) {
        completionRate = user.tasksCompletedOnTime / user.tasksCompleted;
        // Clamp to ensure it's never above 100% or below 0%
        completionRate = completionRate.clamp(0.0, 1.0);
      }

      // Fetch wallet transactions to calculate total earnings
      double totalEarnings = 0.0;
      try {
        final transactions = await _apiService.getWalletTransactions();
        totalEarnings = transactions
            .where((tx) => tx.type == 'credit' && (tx.status == 'completed' || tx.status == 'released'))
            .fold<double>(0, (sum, tx) => sum + tx.amount);
      } catch (e) {
        print('ProfileBloc: Error fetching earnings: $e');
      }
      
      final profile = UserProfile(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        profileImage: user.profileImage,
        bio: user.bio ?? '',
        rating: user.rating,
        totalReviews: user.totalReviews,
        completedTasks: user.tasksCompleted,
        tasksCompletedOnTime: user.tasksCompletedOnTime,
        completionRate: completionRate,
        totalEarnings: totalEarnings,
        isVerified: user.isVerified,
        address: user.address,
        city: user.city,
        country: user.country,
        postcode: user.postcode,
        dateOfBirth: user.dateOfBirth,
        taskerProfile: user.taskerProfile,
        badges: user.badges,
      );
      
      print('ProfileBloc: Loading notification settings');
      // Load notification settings from local storage
      final settings = await _loadNotificationSettings();
      
      print('ProfileBloc: Emitting ProfileLoaded');
      emit(ProfileLoaded(profile: profile, notificationSettings: settings));
    } on ApiException catch (e) {
      print('ProfileBloc: Auth error: $e');
      emit(ProfileError(e.statusCode == 401 ? 'Session expired. Please log in again.' : e.message));
    } catch (e) {
      print('ProfileBloc: Error in _onLoadProfile: $e');
      emit(ProfileError('Failed to load profile: ${e.toString()}'));
    }
  }

  Future<NotificationSettings> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('notification_settings');
      if (json != null) {
        final data = jsonDecode(json);
        return NotificationSettings(
          taskAlerts: data['taskAlerts'] ?? true,
          offers: data['offers'] ?? true,
          messages: data['messages'] ?? true,
          taskReminders: data['taskReminders'] ?? true,
          promotions: data['promotions'] ?? false,
          emailNotifications: data['emailNotifications'] ?? true,
          pushNotifications: data['pushNotifications'] ?? true,
        );
      }
    } catch (_) {}
    return const NotificationSettings();
  }

  Future<void> _saveNotificationSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_settings', jsonEncode({
      'taskAlerts': settings.taskAlerts,
      'offers': settings.offers,
      'messages': settings.messages,
      'taskReminders': settings.taskReminders,
      'promotions': settings.promotions,
      'emailNotifications': settings.emailNotifications,
      'pushNotifications': settings.pushNotifications,
    }));
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileUpdating());
    try {
      final Map<String, dynamic> updates = {
        'name': event.profile.name,
      };

      if (event.profile.phone != null) updates['phone'] = event.profile.phone;
      if (event.profile.bio != null) updates['bio'] = event.profile.bio;
      if (event.profile.address != null) updates['address'] = event.profile.address;
      if (event.profile.city != null) updates['city'] = event.profile.city;
      if (event.profile.country != null) updates['country'] = event.profile.country;
      if (event.profile.postcode != null) updates['postcode'] = event.profile.postcode;
      if (event.profile.dateOfBirth != null) {
        updates['date_of_birth'] = event.profile.dateOfBirth?.toIso8601String();
      }

      // Update profile via API
      await _apiService.updateUser(event.profile.id, updates);
      
      emit(ProfileUpdated(event.profile));
      
      // Reload profile to ensure consistency
      add(LoadProfile());
    } catch (e) {
      emit(ProfileError(e.toString()));
      // Restore previous state if possible (reload)
      add(LoadProfile());
    }
  }

  Future<void> _onUpdateAvatar(
    UpdateAvatar event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(ProfileUpdating());
      try {
        final file = File(event.imagePath);
        final imageUrl = await _apiService.uploadUserAvatar(file);

        final updatedProfile = currentState.profile.copyWith(
          profileImage: imageUrl,
        );
        
        emit(ProfileLoaded(
          profile: updatedProfile,
          notificationSettings: currentState.notificationSettings,
        ));
      } catch (e) {
        emit(ProfileError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateNotificationSettings(
    UpdateNotificationSettings event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      try {
        await _saveNotificationSettings(event.settings);
        emit(ProfileLoaded(
          profile: currentState.profile,
          notificationSettings: event.settings,
        ));
      } catch (e) {
        emit(ProfileError(e.toString()));
      }
    }
  }

  Future<void> _onLoadPaymentMethods(
    LoadPaymentMethods event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      // Load from local storage for now
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getStringList('payment_methods') ?? [];
      final methods = json.map((e) {
        final data = jsonDecode(e);
        return PaymentMethod(
          id: data['id'],
          type: PaymentType.values.byName(data['type'] ?? 'card'),
          displayName: data['displayName'] ?? '****${data['cardLast4'] ?? ''}',
          cardLast4: data['cardLast4'],
          isDefault: data['isDefault'] ?? false,
        );
      }).toList();
      emit(PaymentMethodsLoaded(methods));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onAddPaymentMethod(
    AddPaymentMethod event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getStringList('payment_methods') ?? [];
      json.add(jsonEncode({
        'id': event.method.id,
        'type': event.method.type.name,
        'displayName': event.method.displayName,
        'cardLast4': event.method.cardLast4,
        'isDefault': event.method.isDefault,
      }));
      await prefs.setStringList('payment_methods', json);
      
      // Reload
      add(LoadPaymentMethods());
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onRemovePaymentMethod(
    RemovePaymentMethod event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getStringList('payment_methods') ?? [];
      json.removeWhere((e) => jsonDecode(e)['id'] == event.methodId);
      await prefs.setStringList('payment_methods', json);
      
      // Reload
      add(LoadPaymentMethods());
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onSetDefaultPaymentMethod(
    SetDefaultPaymentMethod event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getStringList('payment_methods') ?? [];
      final methods = json.map((e) => jsonDecode(e)).toList();
      
      for (var method in methods) {
        method['isDefault'] = method['id'] == event.methodId;
      }
      
      await prefs.setStringList('payment_methods', methods.map((e) => jsonEncode(e)).toList());
      
      // Reload
      add(LoadPaymentMethods());
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistory event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final transactions = await _apiService.getPaymentHistory();
      emit(PaymentHistoryLoaded(transactions));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
