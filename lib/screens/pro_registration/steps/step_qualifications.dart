import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../bloc/pro_registration/pro_registration_bloc.dart';
import '../../../bloc/pro_registration/pro_registration_event.dart';
import '../../../bloc/pro_registration/pro_registration_state.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../core/service_locator.dart';
import '../../../models/tasker_profile.dart';
import '../../../services/api_service.dart';

class StepQualifications extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const StepQualifications({super.key, required this.onNext, required this.onBack});

  @override
  State<StepQualifications> createState() => _StepQualificationsState();
}

class _StepQualificationsState extends State<StepQualifications> with TickerProviderStateMixin {
  bool _isAdding = false;
  bool _isUploading = false;
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _courseController = TextEditingController();
  final _dateController = TextEditingController();
  String? _certUrl;
  bool _isPdf = false;

  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  // Curated data
  List<Map<String, dynamic>> _qualificationTypes = [];
  List<Map<String, dynamic>> _institutions = [];
  String? _selectedQualificationType;
  String? _selectedInstitution;
  String? _selectedCourse;
  bool _isOtherQualificationType = false;
  bool _isOtherInstitution = false;
  bool _isOtherCourse = false;

  @override
  void initState() {
    super.initState();
    _loadCuratedData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimations = List.generate(5, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, 0.5 + index * 0.1, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(5, (index) {
      return Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, 0.5 + index * 0.1, curve: Curves.easeOut),
        ),
      );
    });

    _animationController.forward();
  }

  Future<void> _loadCuratedData() async {
    final apiService = getIt<ApiService>();
    final qualTypes = await apiService.getQualificationTypes();
    final institutions = await apiService.getInstitutions();
    if (mounted) {
      setState(() {
        _qualificationTypes = qualTypes;
        _institutions = institutions;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _courseController.dispose();
    _dateController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _issuerController.clear();
    _courseController.clear();
    _dateController.clear();
    _certUrl = null;
    _isPdf = false;
    _selectedQualificationType = null;
    _selectedInstitution = null;
    _selectedCourse = null;
    _isOtherQualificationType = false;
    _isOtherInstitution = false;
    _isOtherCourse = false;
    setState(() => _isAdding = false);
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
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.military_tech, color: Color(0xFF8B5CF6), size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Upload certificates to earn the Certified badge and boost visibility.',
                                      style: TextStyle(
                                        color: const Color(0xFF5B21B6),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Existing qualifications
                    if (state.qualifications.isNotEmpty) ...[
                      FadeTransition(
                        opacity: _fadeAnimations[1],
                        child: SlideTransition(
                          position: _slideAnimations[1],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ADDED QUALIFICATIONS',
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.neutral500,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...state.qualifications.asMap().entries.map((entry) {
                                final index = entry.key;
                                final q = entry.value;
                                return _buildQualificationCard(q, index);
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Add form
                    FadeTransition(
                      opacity: _fadeAnimations[2],
                      child: SlideTransition(
                        position: _slideAnimations[2],
                        child: _isAdding 
                          ? _buildAddForm(context)
                          : InkWell(
                              onTap: () => setState(() => _isAdding = true),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 1.5, style: BorderStyle.solid),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 28),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Add a Qualification',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.navy,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(state),
          ],
        );
      },
    );
  }

  Widget _buildQualificationCard(Qualification q, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: q.url != null && q.url!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: q.url!.endsWith('.pdf')
                        ? const Center(child: Icon(Icons.picture_as_pdf, color: Colors.red, size: 30))
                        : q.url!.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: q.url!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : Image.file(File(q.url!), fit: BoxFit.cover),
                  )
                : const Icon(Icons.workspace_premium, color: Color(0xFF8B5CF6), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.name,
                  style: GoogleFonts.nunitoSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navy),
                ),
                if (q.courseName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    q.courseName,
                    style: TextStyle(color: AppTheme.navy.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  'Issued by ${q.issuer}',
                  style: TextStyle(color: AppTheme.neutral500, fontSize: 12),
                ),
                Text(
                  'Year: ${q.date}',
                  style: TextStyle(color: AppTheme.neutral500, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: AppTheme.accentRed, size: 18),
            ),
            onPressed: () {
              context.read<ProRegistrationBloc>().add(ProRegistrationQualificationRemoved(index));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Add New Qualification',
                style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildDropdownWithOther(
            label: 'Qualification Type',
            items: _qualificationTypes.isNotEmpty 
                ? _qualificationTypes.map((t) => t['name'] as String).toList()
                : ['National Certificate', 'National Diploma', 'Higher National Diploma', "Bachelor's Degree", "Master's Degree", 'PhD', 'Trade Certificate', 'Professional License'],
            selectedValue: _selectedQualificationType,
            isOther: _isOtherQualificationType,
            otherController: _nameController,
            otherHint: 'e.g. Specialized Trade Cert',
            onChanged: (value) {
              setState(() {
                if (value == 'Other') {
                  _isOtherQualificationType = true;
                  _selectedQualificationType = null;
                } else {
                  _isOtherQualificationType = false;
                  _selectedQualificationType = value;
                  _nameController.text = value ?? '';
                }
              });
            },
          ),
          const SizedBox(height: 16),

          _buildDropdownWithOther(
            label: 'Course / Program',
            items: AppConstants.zimbabweanCourses,
            selectedValue: _selectedCourse,
            isOther: _isOtherCourse,
            otherController: _courseController,
            otherHint: 'e.g. Advanced Solar Installation',
            onChanged: (value) {
              setState(() {
                if (value == 'Other') {
                  _isOtherCourse = true;
                  _selectedCourse = null;
                } else {
                  _isOtherCourse = false;
                  _selectedCourse = value;
                  _courseController.text = value ?? '';
                }
              });
            },
          ),
          const SizedBox(height: 16),
          
          _buildDropdownWithOther(
            label: 'Institution',
            items: _institutions.isNotEmpty 
                ? _institutions.map((i) => i['name'] as String).toList()
                : AppConstants.zimbabweanInstitutions,
            selectedValue: _selectedInstitution,
            isOther: _isOtherInstitution,
            otherController: _issuerController,
            otherHint: 'e.g. Zim Institute of Tech',
            onChanged: (value) {
              setState(() {
                if (value == 'Other') {
                  _isOtherInstitution = true;
                  _selectedInstitution = null;
                } else {
                  _isOtherInstitution = false;
                  _selectedInstitution = value;
                  _issuerController.text = value ?? '';
                }
              });
            },
          ),
          const SizedBox(height: 16),
          
          _buildYearPicker(),
          const SizedBox(height: 24),
          
          Text(
            'PROOF OF QUALIFICATION',
            style: GoogleFonts.nunitoSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.neutral500, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          
          InkWell(
            onTap: _isUploading ? null : _pickAndUploadCertificate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.neutral50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _certUrl != null ? AppTheme.success.withValues(alpha: 0.5) : AppTheme.neutral200,
                  width: _certUrl != null ? 2 : 1,
                  style: _certUrl != null ? BorderStyle.solid : BorderStyle.solid,
                ),
              ),
              child: _isUploading 
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.navy)))
                : _certUrl != null
                  ? _buildUploadedPreview()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, color: AppTheme.primary.withValues(alpha: 0.5), size: 36),
                        const SizedBox(height: 8),
                        Text('Upload Certificate', style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('(Image or PDF)', style: TextStyle(color: AppTheme.neutral500, fontSize: 11)),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isUploading ? null : _resetForm, 
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.neutral500, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGradientButton(
                  onPressed: (_canAdd && !_isUploading) ? _addQualification : null,
                  text: 'Save',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedPreview() {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _isPdf
                ? Container(
                    color: Colors.red.withValues(alpha: 0.05),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                          SizedBox(height: 6),
                          Text('PDF Uploaded', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                : _certUrl!.startsWith('http')
                    ? CachedNetworkImage(imageUrl: _certUrl!, fit: BoxFit.cover)
                    : Image.file(File(_certUrl!), fit: BoxFit.cover),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black.withValues(alpha: 0.3),
          ),
        ),
        const Center(
          child: Icon(Icons.check_circle, color: Colors.white, size: 40),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: () => setState(() { _certUrl = null; _isPdf = false; }),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: AppTheme.accentRed),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(ProRegistrationState state) {
    return FadeTransition(
      opacity: _fadeAnimations[4],
      child: SlideTransition(
        position: _slideAnimations[4],
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
                  text: state.qualifications.isEmpty ? 'Skip' : 'Continue',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    double height = 54,
  }) {
    final bool isDisabled = onPressed == null;
    
    return Container(
      width: double.infinity,
      height: height,
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

  bool get _canAdd =>
      _nameController.text.isNotEmpty &&
      _issuerController.text.isNotEmpty &&
      _dateController.text.isNotEmpty &&
      _certUrl != null;

  Future<void> _pickAndUploadCertificate() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Upload Certificate', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.navy)),
              const SizedBox(height: 24),
              _buildUploadOption(icon: Icons.camera_alt, label: 'Take Photo', onTap: () => Navigator.pop(context, 'camera')),
              const SizedBox(height: 12),
              _buildUploadOption(icon: Icons.photo_library, label: 'Choose from Gallery', onTap: () => Navigator.pop(context, 'gallery')),
              const SizedBox(height: 12),
              _buildUploadOption(icon: Icons.picture_as_pdf, label: 'Upload PDF', isPdf: true, onTap: () => Navigator.pop(context, 'pdf')),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;

    setState(() => _isUploading = true);

    try {
      File? file;
      
      if (choice == 'pdf') {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (result != null && result.files.single.path != null) {
          file = File(result.files.single.path!);
          _isPdf = true;
        }
      } else {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 70,
          maxWidth: 1920,
        );
        if (image != null) {
          file = File(image.path);
          _isPdf = false;
        }
      }

      if (file == null) {
        setState(() => _isUploading = false);
        return;
      }

      final url = await getIt<ApiService>().uploadTaskerFile(file, 'qualification');
      
      if (mounted) {
        setState(() {
          _certUrl = url;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildUploadOption({required IconData icon, required String label, bool isPdf = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.neutral50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.neutral200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPdf ? Colors.red.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isPdf ? Colors.red : AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navy)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.neutral400),
          ],
        ),
      ),
    );
  }

  void _addQualification() {
    context.read<ProRegistrationBloc>().add(ProRegistrationQualificationAdded(
          name: _nameController.text,
          courseName: _courseController.text,
          issuer: _issuerController.text,
          date: _dateController.text,
          url: _certUrl!,
        ));
    _resetForm();
  }

  Widget _buildDropdownWithOther({
    required String label,
    required List<String> items,
    required String? selectedValue,
    required bool isOther,
    required TextEditingController otherController,
    required String otherHint,
    required void Function(String?) onChanged,
  }) {
    final allItems = [...items.where((i) => i != 'Other'), 'Other'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.nunitoSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.neutral500, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: isOther ? 'Other' : selectedValue,
          hint: Text('Select ${label.toLowerCase()}', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.neutral50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.neutral200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.neutral200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.navy, width: 1.5)),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.navy),
          items: allItems.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: onChanged,
        ),
        if (isOther) ...[
          const SizedBox(height: 8),
          TextField(
            controller: otherController,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: otherHint,
              hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.neutral200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.neutral200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.navy, width: 1.5)),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }

  Widget _buildYearPicker() {
    final currentYear = DateTime.now().year;
    final years = List.generate(50, (index) => (currentYear - index).toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YEAR OBTAINED',
          style: GoogleFonts.nunitoSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.neutral500, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _dateController.text.isNotEmpty ? _dateController.text : null,
          hint: Text('Select year', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.neutral50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.neutral200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.neutral200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.navy, width: 1.5)),
          ),
          icon: const Icon(Icons.calendar_today, color: AppTheme.navy, size: 18),
          items: years.map((year) => DropdownMenuItem(
            value: year,
            child: Text(year, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          )).toList(),
          onChanged: (value) {
            setState(() {
              _dateController.text = value ?? '';
            });
          },
        ),
      ],
    );
  }
}
