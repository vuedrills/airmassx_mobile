import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../bloc/pro_registration/pro_registration_bloc.dart';
import '../../../bloc/pro_registration/pro_registration_event.dart';
import '../../../bloc/pro_registration/pro_registration_state.dart';
import '../../../config/theme.dart';
import '../../../core/service_locator.dart';
import '../../../services/api_service.dart';

class StepIdentity extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const StepIdentity({super.key, required this.onNext, required this.onBack});

  @override
  State<StepIdentity> createState() => _StepIdentityState();
}

class _StepIdentityState extends State<StepIdentity> with TickerProviderStateMixin {
  bool _isUploading = false;
  String? _uploadingType;

  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimations = List.generate(4, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, 0.5 + index * 0.1, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(4, (index) {
      return Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, 0.5 + index * 0.1, curve: Curves.easeOut),
        ),
      );
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProRegistrationBloc, ProRegistrationState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: _fadeAnimations[0],
                child: SlideTransition(
                  position: _slideAnimations[0],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload a clear photo of your ID document (front) for verification.',
                        style: TextStyle(
                          color: AppTheme.neutral600,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ID Document Upload
              FadeTransition(
                opacity: _fadeAnimations[1],
                child: SlideTransition(
                  position: _slideAnimations[1],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ID Document *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navy)),
                      const SizedBox(height: 12),
                      _buildUploadCard(
                        context,
                        title: 'Front of ID',
                        subtitle: 'Upload the front side of your ID',
                        hasImage: state.idDocumentUrls.isNotEmpty,
                        isUploading: _isUploading && _uploadingType == 'id_front',
                        onTap: () => _pickAndUploadImage(context, type: 'id_front'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              FadeTransition(
                opacity: _fadeAnimations[2],
                child: SlideTransition(
                  position: _slideAnimations[2],
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isUploading ? null : widget.onBack,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _buildGradientButton(
                          onPressed: (state.isStep2Valid && !_isUploading) ? widget.onNext : null,
                          text: 'Continue',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool hasImage,
    required VoidCallback onTap,
    bool isUploading = false,
    IconData icon = Icons.upload_file,
  }) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasImage ? AppTheme.success.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage ? AppTheme.success.withValues(alpha: 0.5) : Colors.grey[200]!,
            width: hasImage ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasImage ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.neutral100,
                shape: BoxShape.circle,
              ),
              child: isUploading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary)),
                    )
                  : Icon(
                      hasImage ? Icons.check : icon,
                      color: hasImage ? AppTheme.success : AppTheme.primary,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunitoSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: hasImage ? AppTheme.success : AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUploading 
                        ? 'Uploading...' 
                        : hasImage 
                            ? 'Document uploaded successfully ✓' 
                            : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isUploading 
                          ? AppTheme.primary 
                          : hasImage 
                              ? AppTheme.success 
                              : AppTheme.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            if (!hasImage && !isUploading)
              Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.neutral300),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
  }) {
    final bool isDisabled = onPressed == null;
    
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: isDisabled ? null : const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        color: isDisabled ? Colors.grey[300] : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDisabled ? null : [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Future<File> _saveFilePermanently(File file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(file.path);
    final savedFile = await file.copy(path.join(appDir.path, fileName));
    return savedFile;
  }

  Future<void> _pickAndUploadImage(BuildContext context, {required String type}) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    setState(() {
      _isUploading = true;
      _uploadingType = type;
    });

    try {
      // Copy to permanent storage to avoid PathNotFoundException
      final pickedFile = File(image.path);
      final file = await _saveFilePermanently(pickedFile);
      
      // Upload to server
      final url = await getIt<ApiService>().uploadTaskerFile(file, 'id_document');
      
      if (!mounted) return;
      
      final bloc = context.read<ProRegistrationBloc>();
      final currentUrls = List<String>.from(bloc.state.idDocumentUrls);
      
      if (type == 'id_front') {
        if (currentUrls.isEmpty) {
          currentUrls.add(url);
        } else {
          currentUrls[0] = url;
        }
      } else {
        if (currentUrls.length < 2) {
          currentUrls.add(url);
        } else {
          currentUrls[1] = url;
        }
      }
      
      bloc.add(ProRegistrationIdentityUpdated(idDocumentUrls: currentUrls));
      
      // Clean up local copy after successful upload
      try {
        await file.delete();
      } catch (e) {
        debugPrint('Failed to delete temporary file: $e');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadingType = null;
        });
      }
    }
  }
}
