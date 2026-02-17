import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/portfolio_item.dart';
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
                            itemCount: state.portfolioItems.length + 1,
                            itemBuilder: (context, index) {
                              if (index == state.portfolioItems.length) {
                                return _buildAddButton(context);
                              }
                              return _buildPortfolioItem(context, state.portfolioItems[index], index);
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
                            '${state.portfolioItems.length}/10 items',
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
                          text: state.portfolioItems.isEmpty ? 'Skip' : 'Continue',
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

  // ... existing code ...

  Widget _buildAddButton(BuildContext context) {
    return InkWell(
      onTap: _isUploading ? null : () => _showAddOptions(context),
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
              Icons.add_link, 
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

  void _showAddOptions(BuildContext context) {
    final bloc = context.read<ProRegistrationBloc>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: AppTheme.primary),
              title: const Text('Upload Photo'),
              onTap: () {
                Navigator.pop(modalContext);
                _pickAndUploadImages(bloc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: AppTheme.primary),
              title: const Text('Add Link (GitHub, Portfolio, etc.)'),
              onTap: () {
                Navigator.pop(modalContext);
                _showAddLinkDialog(context, bloc);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLinkDialog(BuildContext context, ProRegistrationBloc bloc) {
    final urlController = TextEditingController();
    final titleController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalContext).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Portfolio Link',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a link to your GitHub, Behance, or personal website.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Project Title',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. My Portfolio website',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Project URL',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      hintText: 'https://github.com/username',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: _buildGradientButton(
                      text: 'Add Link',
                      onPressed: () {
                        final url = urlController.text.trim();
                        final title = titleController.text.trim();
                        if (url.isNotEmpty && title.isNotEmpty) {
                          final currentItems = List<PortfolioItem>.from(bloc.state.portfolioItems);
                          if (currentItems.length < 10) {
                            final newItem = PortfolioItem(
                              title: title,
                              url: url,
                              type: 'link',
                            );
                            bloc.add(ProRegistrationPortfolioUpdated([...currentItems, newItem]));
                          }
                          Navigator.pop(modalContext);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioItem(BuildContext context, PortfolioItem item, int index) {
    if (item.type == 'link') {
      return _buildLinkCard(context, item, index);
    }

    // Image rendering
    ImageProvider imageProvider;
    if (item.url.startsWith('http')) {
      imageProvider = NetworkImage(item.url);
    } else if (item.url.startsWith('/uploads')) {
      imageProvider = NetworkImage('${ApiService.assetBaseUrl}${item.url}');
    } else {
      imageProvider = FileImage(File(item.url));
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
          child: _buildRemoveButton(context, index),
        ),
      ],
    );
  }

  Widget _buildLinkCard(BuildContext context, PortfolioItem item, int index) {
    IconData icon = Icons.link;
    Color color = Colors.grey;
    final url = item.url;

    if (url.contains('github.com')) {
      icon = Icons.code;
      color = Colors.black;
    } else if (url.contains('behance.net')) {
      icon = Icons.brush;
      color = Colors.blue;
    } else if (url.contains('dribbble.com')) {
      icon = Icons.sports_basketball;
      color = Colors.pink;
    } else if (url.contains('linkedin.com')) {
      icon = Icons.work;
      color = Colors.blue[800]!;
    }

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.neutral100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 4),
              Text(
                item.title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.navy),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                url.replaceFirst(RegExp(r'https?://(www\.)?'), ''),
                style: const TextStyle(fontSize: 9, color: AppTheme.neutral600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: _buildRemoveButton(context, index),
        ),
      ],
    );
  }

  Widget _buildRemoveButton(BuildContext context, int index) {
    return GestureDetector(
      onTap: _isUploading ? null : () {
        final bloc = context.read<ProRegistrationBloc>();
        final updatedItems = List<PortfolioItem>.from(bloc.state.portfolioItems)..removeAt(index);
        bloc.add(ProRegistrationPortfolioUpdated(updatedItems));
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 16),
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

  Future<void> _pickAndUploadImages(ProRegistrationBloc bloc) async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) return;

    final currentItems = List<PortfolioItem>.from(bloc.state.portfolioItems);
    final availableSlots = 10 - currentItems.length;
    final imagesToUpload = images.take(availableSlots).toList();

    if (imagesToUpload.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 10 photos allowed')),
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
      // Create PortfolioItems from uploaded URLs
      final newPortfolioItems = uploadedUrls.map((url) => PortfolioItem(
        title: 'Work Sample ${currentItems.length + uploadedUrls.indexOf(url) + 1}',
        url: url,
        type: 'image',
      )).toList();
      
      final updatedItems = [...currentItems, ...newPortfolioItems];
      bloc.add(ProRegistrationPortfolioUpdated(updatedItems));

      setState(() {
        _isUploading = false;
        _uploadCount = 0;
        _totalToUpload = 0;
      });

      if (uploadedUrls.length < imagesToUpload.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${uploadedUrls.length} of ${imagesToUpload.length} photos uploaded'),
          ),
        );
      }
    }
  }
}
