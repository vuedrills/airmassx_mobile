import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../bloc/pro_registration/pro_registration_bloc.dart';
import '../../../bloc/pro_registration/pro_registration_event.dart';
import '../../../bloc/pro_registration/pro_registration_state.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';

class StepBasicInfo extends StatefulWidget {
  final VoidCallback onNext;

  const StepBasicInfo({super.key, required this.onNext});

  @override
  State<StepBasicInfo> createState() => _StepBasicInfoState();
}

class _StepBasicInfoState extends State<StepBasicInfo> with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  String _selectedCountryCode = '+263'; // Default to Zimbabwe

  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProRegistrationBloc>().state;
    _nameController = TextEditingController(text: state.name);
    
    // Extract phone number without country code
    String phone = state.phone;
    for (final country in AppConstants.countryCodes) {
      if (phone.startsWith(country['code']!)) {
        _selectedCountryCode = country['code']!;
        phone = phone.substring(country['code']!.length);
        break;
      }
    }
    _phoneController = TextEditingController(text: phone);
    _bioController = TextEditingController(text: state.bio);

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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateBloc() {
    // Combine country code with phone number
    String fullPhone = '';
    if (_phoneController.text.trim().isNotEmpty) {
      fullPhone = '$_selectedCountryCode${_phoneController.text.trim()}';
    }
    
    context.read<ProRegistrationBloc>().add(ProRegistrationBasicInfoUpdated(
          name: _nameController.text,
          phone: fullPhone,
          bio: _bioController.text,
        ));
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
                        'This information will be visible on your professional profile and helps clients find you.',
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

              // Name Card
              FadeTransition(
                opacity: _fadeAnimations[1],
                child: SlideTransition(
                  position: _slideAnimations[1],
                  child: _buildInputCard(
                    label: 'Full Name',
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primary, size: 20),
                      ),
                      onChanged: (_) => _updateBloc(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Phone Card
              FadeTransition(
                opacity: _fadeAnimations[2],
                child: SlideTransition(
                  position: _slideAnimations[2],
                  child: _buildInputCard(
                    label: 'Phone Number (Optional)',
                    subtitle: 'Used for client communication only',
                    child: Row(
                      children: [
                        // Country Code Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.neutral100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCountryCode,
                              borderRadius: BorderRadius.circular(12),
                              items: AppConstants.countryCodes.map((country) {
                                return DropdownMenuItem<String>(
                                  value: country['code'],
                                  child: Text(
                                    '${country['flag']} ${country['code']}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.navy),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedCountryCode = value!);
                                _updateBloc();
                              },
                            ),
                          ),
                        ),
                        // Phone Number Field
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: '77 123 4567',
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                              border: InputBorder.none,
                            ),
                            onChanged: (_) => _updateBloc(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bio Card
              FadeTransition(
                opacity: _fadeAnimations[3],
                child: SlideTransition(
                  position: _slideAnimations[3],
                  child: _buildInputCard(
                    label: 'Professional Summary',
                    subtitle: 'Describe your skills and experience',
                    child: TextField(
                      controller: _bioController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                      decoration: InputDecoration(
                        hintText: 'e.g. Experienced plumber with 10+ years in residential projects...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => _updateBloc(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Continue Button
              FadeTransition(
                opacity: _fadeAnimations[4],
                child: SlideTransition(
                  position: _slideAnimations[4],
                  child: _buildGradientButton(
                    onPressed: state.isStep1Valid ? widget.onNext : null,
                    text: 'Continue',
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

  Widget _buildInputCard({
    required String label,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.nunitoSans(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.navy,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
          const SizedBox(height: 4),
          child,
        ],
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
}
