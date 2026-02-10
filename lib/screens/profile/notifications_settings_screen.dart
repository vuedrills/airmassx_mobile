import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';
import '../../models/notification_settings.dart';
import '../../config/theme.dart';
import '../../core/service_locator.dart';

/// Notifications settings screen - toggle preferences
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileLoaded) {
            return _buildSettings(context, state.notificationSettings);
          }

          if (state is ProfileError) {
             return Center(child: Text('Error: ${state.message}'));
          }

          return const Center(child: Text('Loading...'));
        },
      ),
    );
  }

  Widget _buildSettings(BuildContext context, NotificationSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'In-App Notifications',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),

        _buildSwitchTile(
          context,
          'Task Alerts',
          'Get notified about new tasks in your area',
          Icons.notification_important,
          settings.taskAlerts,
          (value) => _updateSettings(
            context,
            settings.copyWith(taskAlerts: value),
          ),
        ),

        _buildSwitchTile(
          context,
          'Messages',
          'Notifications for new messages',
          Icons.message,
          settings.messages,
          (value) => _updateSettings(
            context,
            settings.copyWith(messages: value),
          ),
        ),

        _buildSwitchTile(
          context,
          'Offers',
          'When someone makes an offer on your task',
          Icons.local_offer,
          settings.offers,
          (value) => _updateSettings(
            context,
            settings.copyWith(offers: value),
          ),
        ),

        _buildSwitchTile(
          context,
          'Task Reminders',
          'Reminders about upcoming tasks',
          Icons.alarm,
          settings.taskReminders,
          (value) => _updateSettings(
            context,
            settings.copyWith(taskReminders: value),
          ),
        ),

        _buildSwitchTile(
          context,
          'Promotions',
          'Special offers and promotions',
          Icons.star,
          settings.promotions,
          (value) => _updateSettings(
            context,
            settings.copyWith(promotions: value),
          ),
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        Text(
          'Notification Channels',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),

        _buildSwitchTile(
          context,
          'Email Notifications',
          'Receive notifications via email',
          Icons.email,
          settings.emailNotifications,
          (value) => _updateSettings(
            context,
            settings.copyWith(emailNotifications: value),
          ),
        ),

        _buildSwitchTile(
          context,
          'Push Notifications',
          'Receive push notifications on your device',
          Icons.phonelink_ring,
          settings.pushNotifications,
          (value) => _updateSettings(
            context,
            settings.copyWith(pushNotifications: value),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    void Function(bool) onChanged,
  ) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      secondary: Icon(icon, color: AppTheme.navy),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.navy,
    );
  }

  void _updateSettings(BuildContext context, NotificationSettings settings) {
    context.read<ProfileBloc>().add(UpdateNotificationSettings(settings));
  }
}
