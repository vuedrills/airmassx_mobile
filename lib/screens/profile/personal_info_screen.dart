import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';
import '../../config/theme.dart';
import '../../core/service_locator.dart';
import '../../core/validators.dart';
import '../../models/user_profile.dart';


/// Personal info screen - email, phone, address
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _countryController;

  @override
  void dispose() {
    if (_controllersInitialized) {
      _emailController.dispose();
      _phoneController.dispose();
      _addressController.dispose();
      _countryController.dispose();
    }
    super.dispose();
  }

  bool _controllersInitialized = false;

  void _initializeControllers(UserProfile profile) {
    if (_controllersInitialized) return;
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone ?? profile.taskerProfile?.ecocashNumber ?? '');
    _addressController = TextEditingController(text: profile.address ?? profile.taskerProfile?.primaryAddress ?? '');
    _countryController = TextEditingController(text: profile.country ?? 'Zimbabwe');
    _controllersInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Info'),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Personal info updated')),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileLoaded) {
            _initializeControllers(state.profile);
            return _buildForm(context, state);
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, ProfileLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Header
            Text(
              'Account Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
            ),
            const SizedBox(height: 24),

            // Full Name (read-only)
            _buildReadOnlyField('Full Name', state.profile.name, Icons.person_outline),
            const SizedBox(height: 16),

            // Email (read-only)
            _buildReadOnlyField('Email', state.profile.email, Icons.email_outlined),
            const SizedBox(height: 16),

            // Phone
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '+263 7X XXX XXXX',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 32),
            Divider(height: 32, thickness: 1, color: AppTheme.neutral200),
            
            Text(
              'Address Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
            ),
            const SizedBox(height: 24),

            // Street Address
            _buildTextField(
              controller: _addressController,
              label: 'Street Address',
              hint: '123 Samora Machel Ave',
              icon: Icons.home_outlined,
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 16),
            // Country
            _buildReadOnlyField('Country', _countryController.text, Icons.public),

            const SizedBox(height: 48),

            // Save button
            ElevatedButton(
              onPressed: () => _saveInfo(context, state),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.neutral500),
        suffixIcon: const Icon(Icons.lock_outline, size: 16, color: AppTheme.neutral400),
        filled: true,
        fillColor: AppTheme.neutral100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
      readOnly: true,
      enabled: false,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.neutral400),
        prefixIcon: icon != null ? Icon(icon, color: AppTheme.primary) : null,
        filled: true,
        fillColor: Colors.white,
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
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w500),
    );
  }

  void _saveInfo(BuildContext context, ProfileLoaded state) {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = state.profile.copyWith(
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        country: _countryController.text.trim(),
        latitude: state.profile.latitude ?? state.profile.taskerProfile?.primaryLatitude,
        longitude: state.profile.longitude ?? state.profile.taskerProfile?.primaryLongitude,
      );

      context.read<ProfileBloc>().add(UpdateProfile(updatedProfile));
    }
  }
}
