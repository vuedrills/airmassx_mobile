import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../bloc/pro_registration/pro_registration_bloc.dart';
import '../../../bloc/pro_registration/pro_registration_event.dart';
import '../../../bloc/pro_registration/pro_registration_state.dart';
import '../../../config/theme.dart';
import '../../../core/service_locator.dart';
import '../../../services/api_service.dart';

class StepPortfolio extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const StepPortfolio({super.key, required this.onNext, required this.onBack});

  @override
  State<StepPortfolio> createState() => _StepPortfolioState();
}

class _StepPortfolioState extends State<StepPortfolio> with TickerProviderStateMixin {
  bool _isUploading = false;
  int _uploadCount = 0;
  int _totalToUpload = 0;

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
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                              'Upload photos of your previous work to showcase your skills and build client trust.',
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

                    // Upload progress
                    if (_isUploading) ...[
                      FadeTransition(
                        opacity: _fadeAnimations[1],
                        child: SlideTransition(
                          position: _slideAnimations[1],
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary)),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Uploading $_uploadCount of $_totalToUpload...',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Portfolio Grid
                    FadeTransition(
                      opacity: _fadeAnimations[2],
                      child: SlideTransition(
                        position: _slideAnimations[2],
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1,
                          ),
                          itemCount: state.portfolioUrls.length + 1,
                          itemBuilder: (context, index) {
                            if (index == state.portfolioUrls.length) {
                              return _buildAddButton(context);
                            }
                            return _buildPortfolioItem(context, state.portfolioUrls[index], index);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _fadeAnimations[3],
                      child: SlideTransition(
                        position: _slideAnimations[3],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.neutral100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${state.portfolioUrls.length}/10 photos',
                            style: const TextStyle(color: AppTheme.neutral600, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom buttons
            FadeTransition(
              opacity: _fadeAnimations[3],
              child: SlideTransition(
                position: _slideAnimations[3],
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
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
                          onPressed: _isUploading ? null : widget.onNext,
                          text: state.portfolioUrls.isEmpty ? 'Skip' : 'Continue',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return InkWell(
      onTap: _isUploading ? null : () => _pickAndUploadImages(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.neutral100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isUploading ? AppTheme.neutral200 : AppTheme.neutral200,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined, 
              color: _isUploading ? AppTheme.neutral300 : AppTheme.primary, 
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _isUploading ? AppTheme.neutral300 : AppTheme.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioItem(BuildContext context, String url, int index) {
    ImageProvider imageProvider;
    if (url.startsWith('http')) {
      imageProvider = NetworkImage(url);
    } else if (url.startsWith('/uploads')) {
      imageProvider = NetworkImage('${ApiService.assetBaseUrl}$url');
    } else {
      imageProvider = FileImage(File(url));
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: _isUploading ? null : () {
              final bloc = context.read<ProRegistrationBloc>();
              final updatedUrls = List<String>.from(bloc.state.portfolioUrls)..removeAt(index);
              bloc.add(ProRegistrationPortfolioUpdated(updatedUrls));
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
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

  Future<void> _pickAndUploadImages(BuildContext context) async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) return;

    final bloc = context.read<ProRegistrationBloc>();
    final currentUrls = List<String>.from(bloc.state.portfolioUrls);
    final availableSlots = 10 - currentUrls.length;
    final imagesToUpload = images.take(availableSlots).toList();

    if (imagesToUpload.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 10 photos allowed'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadCount = 0;
      _totalToUpload = imagesToUpload.length;
    });

    final apiService = getIt<ApiService>();
    final uploadedUrls = <String>[];

    for (final image in imagesToUpload) {
      try {
        final file = File(image.path);
        final url = await apiService.uploadTaskerFile(file, 'portfolio');
        uploadedUrls.add(url);
        
        if (mounted) {
          setState(() {
            _uploadCount++;
          });
        }
      } catch (e) {
        debugPrint('Failed to upload portfolio image: $e');
        // Continue with other images even if one fails
      }
    }

    if (mounted) {
      // Update bloc with uploaded URLs
      final updatedUrls = [...currentUrls, ...uploadedUrls];
      bloc.add(ProRegistrationPortfolioUpdated(updatedUrls));

      setState(() {
        _isUploading = false;
        _uploadCount = 0;
        _totalToUpload = 0;
      });

      if (uploadedUrls.length < imagesToUpload.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${uploadedUrls.length} of ${imagesToUpload.length} photos uploaded'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}
