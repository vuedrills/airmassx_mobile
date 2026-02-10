import 'package:equatable/equatable.dart';

/// Notification settings model
class NotificationSettings extends Equatable {
  final bool taskAlerts;
  final bool messages;
  final bool offers;
  final bool taskReminders;
  final bool promotions;
  final bool emailNotifications;
  final bool pushNotifications;

  const NotificationSettings({
    this.taskAlerts = true,
    this.messages = true,
    this.offers = true,
    this.taskReminders = true,
    this.promotions = false,
    this.emailNotifications = true,
    this.pushNotifications = true,
  });

  NotificationSettings copyWith({
    bool? taskAlerts,
    bool? messages,
    bool? offers,
    bool? taskReminders,
    bool? promotions,
    bool? emailNotifications,
    bool? pushNotifications,
  }) {
    return NotificationSettings(
      taskAlerts: taskAlerts ?? this.taskAlerts,
      messages: messages ?? this.messages,
      offers: offers ?? this.offers,
      taskReminders: taskReminders ?? this.taskReminders,
      promotions: promotions ?? this.promotions,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskAlerts': taskAlerts,
      'messages': messages,
      'offers': offers,
      'taskReminders': taskReminders,
      'promotions': promotions,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      taskAlerts: json['taskAlerts'] as bool? ?? true,
      messages: json['messages'] as bool? ?? true,
      offers: json['offers'] as bool? ?? true,
      taskReminders: json['taskReminders'] as bool? ?? true,
      promotions: json['promotions'] as bool? ?? false,
      emailNotifications: json['emailNotifications'] as bool? ?? true,
      pushNotifications: json['pushNotifications'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        taskAlerts,
        messages,
        offers,
        taskReminders,
        promotions,
        emailNotifications,
        pushNotifications,
      ];
}
