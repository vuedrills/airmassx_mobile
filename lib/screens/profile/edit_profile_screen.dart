import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';
import '../../config/theme.dart';
import '../../core/service_locator.dart';
import '../../core/validators.dart';

/// Edit profile screen - update name, bio, skills
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    
    // Initialize with current data if available
    final state = context.read<ProfileBloc>().state;
    if (state is ProfileLoaded) {
      _nameController.text = state.profile.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null && mounted) {
        context.read<ProfileBloc>().add(UpdateAvatar(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
              if (state is ProfileUpdated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
                context.pop();
              } else if (state is ProfileError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${state.message}')),
                );
              }
            },
            builder: (context, state) {
              if (state is ProfileLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ProfileLoaded) {
                 // Update controller if text is empty (first load) or matches previous state 
                 // but simpler is to rely on initState for initial value and manual edits thereafter
                 return _buildForm(context, state);
              }
              
              // Handle other states like ProfileUpdating or just fallback to content if we have data
              if (state is ProfileUpdating) {
                  return const Center(child: CircularProgressIndicator());
              }
              
              // If we are in Initial state but missing data, try to reload? 
              // Usually we should be Loaded.
              return const Center(child: CircularProgressIndicator());
            },
          ),
        );
  }

  Widget _buildForm(BuildContext context, ProfileLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Avatar section
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.navy.withOpacity(0.1), width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: state.profile.profileImage != null
                          ? NetworkImage(state.profile.profileImage!)
                          : null,
                      backgroundColor: AppTheme.neutral100,
                      child: state.profile.profileImage == null
                          ? Text(
                              state.profile.name.isNotEmpty ? state.profile.name[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.navy),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.navy,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: Validators.name,
            ),

            const SizedBox(height: 48),

            // Save button
            ElevatedButton(
              onPressed: () => _saveProfile(context, state),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Update Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile(BuildContext context, ProfileLoaded state) {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = state.profile.copyWith(
        name: _nameController.text.trim(),
      );

      context.read<ProfileBloc>().add(UpdateProfile(updatedProfile));
    }
  }
}
