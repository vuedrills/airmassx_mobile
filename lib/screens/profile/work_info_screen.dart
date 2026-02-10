import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';
import '../../config/theme.dart';
import '../../core/service_locator.dart';

/// Work info screen - job title, company, skills
class WorkInfoScreen extends StatefulWidget {
  const WorkInfoScreen({super.key});

  @override
  State<WorkInfoScreen> createState() => _WorkInfoScreenState();
}

class _WorkInfoScreenState extends State<WorkInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _jobTitleController;
  late TextEditingController _companyController;

  @override
  void dispose() {
    _jobTitleController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Info'),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Work info updated')),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileLoaded) {
            _jobTitleController = TextEditingController(text: state.profile.jobTitle ?? '');
            _companyController = TextEditingController(text: state.profile.company ?? '');

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
            TextFormField(
              controller: _jobTitleController,
              decoration: const InputDecoration(
                labelText: 'Job Title',
                hintText: 'e.g., Licensed Tradesperson',
                prefixIcon: Icon(Icons.work_outline),
              ),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company',
                hintText: 'e.g., ABC Services Pty Ltd',
                prefixIcon: Icon(Icons.business),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Your Skills',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.profile.skills
                  .map((skill) => Chip(
                        label: Text(skill),
                        backgroundColor: AppTheme.navy.withValues(alpha: 0.1),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 12),

            TextButton.icon(
              onPressed: () => context.go('/profile/edit'),
              icon: const Icon(Icons.edit),
              label: const Text('Edit skills in profile settings'),
            ),

            const SizedBox(height: 32),

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
    final updatedProfile = state.profile.copyWith(
      jobTitle: _jobTitleController.text.trim(),
      company: _companyController.text.trim(),
    );

    context.read<ProfileBloc>().add(UpdateProfile(updatedProfile));
  }
}
