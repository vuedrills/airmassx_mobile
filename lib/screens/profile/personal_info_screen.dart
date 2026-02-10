import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';
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
  late TextEditingController _cityController;
  late TextEditingController _postcodeController;
  late TextEditingController _countryController;

  @override
  void dispose() {
    if (_controllersInitialized) {
      _emailController.dispose();
      _phoneController.dispose();
      _addressController.dispose();
      _cityController.dispose();
      _postcodeController.dispose();
      _countryController.dispose();
    }
    super.dispose();
  }

  bool _controllersInitialized = false;

  void _initializeControllers(UserProfile profile) {
    if (_controllersInitialized) return;
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone ?? '');
    _addressController = TextEditingController(text: profile.address ?? '');
    _cityController = TextEditingController(text: profile.city ?? '');
    _postcodeController = TextEditingController(text: profile.postcode ?? '');
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
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full Name (read-only)
            TextFormField(
              initialValue: state.profile.name,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
                suffixIcon: Icon(Icons.lock_outline, size: 18),
              ),
              readOnly: true,
              enabled: false,
            ),

            const SizedBox(height: 20),

            // Email (read-only)
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                suffixIcon: Icon(Icons.lock_outline, size: 18),
              ),
              readOnly: true,
              enabled: false,
            ),

            const SizedBox(height: 20),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+263 7X XXX XXXX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                // Basic check, or use Validators.phone if it supports generic
                return null; 
              },
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            Text(
              'Address',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            // Street Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                hintText: '123 Samora Machel Ave',
                prefixIcon: Icon(Icons.home_outlined),
              ),
            ),

            const SizedBox(height: 20),

            // City & Postcode
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      hintText: 'Harare',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _postcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Postcode',
                      hintText: '00263',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Country
            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'Country',
                prefixIcon: Icon(Icons.public),
              ),
              readOnly: true, // Make it read-only as verified default
            ),

            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: () => _saveInfo(context, state),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveInfo(BuildContext context, ProfileLoaded state) {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = state.profile.copyWith(
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        postcode: _postcodeController.text.trim(),
        country: _countryController.text.trim(),
      );

      context.read<ProfileBloc>().add(UpdateProfile(updatedProfile));
    }
  }
}
