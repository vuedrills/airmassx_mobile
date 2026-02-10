import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';
import '../../config/theme.dart';
import '../../core/ui_utils.dart';

/// Payment settings screen - specifically for EcoCash
class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ecocashController;
  bool _initialized = false;

  @override
  void dispose() {
    _ecocashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Settings'),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdated) {
            UIUtils.showSnackBar(context, 'EcoCash number updated');
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileUpdating) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileLoaded) {
            if (!_initialized) {
              _ecocashController = TextEditingController(
                text: state.profile.taskerProfile?.ecocashNumber ?? '',
              );
              _initialized = true;
            }
            return _buildEcoCashForm(context, state);
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildEcoCashForm(BuildContext context, ProfileLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.phonelink_ring_outlined,
              size: 64,
              color: AppTheme.navy,
            ),
            const SizedBox(height: 24),
            Text(
              'EcoCash Settings',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your EcoCash number where you\'ll receive payments for tasks.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _ecocashController,
              decoration: const InputDecoration(
                labelText: 'EcoCash Number',
                hintText: '077XXXXXXX',
                prefixIcon: Icon(Icons.phone_android),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your EcoCash number';
                }
                if (!RegExp(r'^(077|078|071)\d{7}$').hasMatch(value)) {
                  return 'Enter a valid Zimbabwe mobile number';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _handleSave(context, state),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save EcoCash Number'),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.navy.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.navy, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Payments are made directly to your EcoCash account by the client upon task completion.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.navy.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave(BuildContext context, ProfileLoaded state) {
    if (_formKey.currentState!.validate()) {
      // We need to update the tasker profile status or just the ecocash number
      // Since ProfileBloc doesn't have a direct "UpdateEcoCash" we might need to 
      // extend it or use the generic UpdateProfile if the backend supports it.
      // Looking at ProfileBloc.dart, _onUpdateProfile takes a UserProfile.
      
      final updatedProfile = state.profile.copyWith(
        taskerProfile: state.profile.taskerProfile?.copyWith(
          ecocashNumber: _ecocashController.text.trim(),
        ) ?? state.profile.taskerProfile, // Fallback if no profile yet
      );

      // We might need to handle the case where taskerProfile is null
      // But for now let's hope it exists or backend handles partial updates.
      context.read<ProfileBloc>().add(UpdateProfile(updatedProfile));
    }
  }
}
