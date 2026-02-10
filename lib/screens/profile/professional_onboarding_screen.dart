import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../core/service_locator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfessionalOnboardingScreen extends StatefulWidget {
  const ProfessionalOnboardingScreen({super.key});

  @override
  State<ProfessionalOnboardingScreen> createState() => _ProfessionalOnboardingScreenState();
}

class _ProfessionalOnboardingScreenState extends State<ProfessionalOnboardingScreen> {
  // Documents
  String? _idDocumentUrl;
  bool _isUploadingId = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      if (user.taskerProfile != null) {
        _idDocumentUrl = user.taskerProfile?.idDocumentUrls.isNotEmpty == true 
            ? user.taskerProfile?.idDocumentUrls.first : null;
      }
    }
  }

  Future<void> _submitVerification() async {
    if (_idDocumentUrl == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your National ID to continue')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final profileData = {
        'id_document_urls': [_idDocumentUrl],
        // Trigger review process. Note: This sets status to pending_review.
        // If the user later wants to become a pro, they will follow the Pro flow.
        'verification_type': 'pending_review',
        'status': 'pending_review',
      };

      await getIt<ApiService>().updateTaskerProfile(profileData);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Verification Submitted'),
            content: const Text('Your ID has been submitted for review. Thank you for helping keep our community safe.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<ProfileBloc>().add(LoadProfile());
                  context.pop();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ID Verification'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.navy,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.navy.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: AppTheme.navy, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verify Your Identity',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upload your National ID to verify your identity and earn a verified badge.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            _buildUploadTile(
              title: 'National ID',
              subtitle: 'Upload a clear photo of your ID',
              url: _idDocumentUrl,
              isUploading: _isUploadingId,
              onTap: () => _handleFileUpload('id_document'),
              icon: Icons.badge_outlined,
            ),

            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitVerification,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppTheme.navy,
                ),
                child: _isSubmitting 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Verification'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadTile({
    required String title,
    required String subtitle,
    required String? url,
    required bool isUploading,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: url != null ? AppTheme.success : Colors.grey.shade300,
            width: url != null ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: url != null ? AppTheme.success.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: url != null ? AppTheme.success : AppTheme.navy.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                url != null ? Icons.check : icon, 
                color: url != null ? Colors.white : AppTheme.navy
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            if (isUploading)
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            else if (url != null)
               ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: url.startsWith('http') 
                    ? Image.network(url, width: 48, height: 48, fit: BoxFit.cover)
                    : Image.file(File(url), width: 48, height: 48, fit: BoxFit.cover),
              )
            else
              const Icon(Icons.add_photo_alternate_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFileUpload(String type) async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (image == null) return;

      setState(() {
        _isUploadingId = true;
      });

      final File file = File(image.path);
      final String remoteUrl = await getIt<ApiService>().uploadTaskerFile(file, type);

      setState(() {
        _idDocumentUrl = remoteUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingId = false;
        });
      }
    }
  }
}

