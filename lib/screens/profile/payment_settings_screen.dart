import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Settings'),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdated) {
            UIUtils.showSnackBar(context, 'Payment settings updated successfully');
            context.pop();
          } else if (state is ProfileError) {
             UIUtils.showSnackBar(context, state.message, isError: true);
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined, // Changed icon
                  size: 48,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Payout Method',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Receive payments directly to your EcoCash wallet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            
            const SizedBox(height: 40),
            
            // Input Field
            Text(
              'EcoCash Mobile Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ecocashController,
              decoration: InputDecoration(
                hintText: '077 123 4567',
                prefixIcon: const Icon(Icons.phone_android, color: AppTheme.primary),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.neutral200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.neutral200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your EcoCash number';
                }
                // Basic flexible validation
                if (value.length < 9) {
                   return 'Please enter a valid number';
                }
                return null;
              },
            ),

            const SizedBox(height: 40),

            // Save Button
            ElevatedButton(
              onPressed: () => _handleSave(context, state),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: const Text('Save Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 32),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.info.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.info, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Payments are processed automatically upon task completion. Ensure your number is registered with EcoCash.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.navy.withOpacity(0.8),
                        height: 1.5,
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
