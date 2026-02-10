import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../bloc/pro_registration/pro_registration_bloc.dart';
import '../../../bloc/pro_registration/pro_registration_event.dart';
import '../../../bloc/pro_registration/pro_registration_state.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';

class StepPayment extends StatefulWidget {
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const StepPayment({super.key, required this.onSubmit, required this.onBack});

  @override
  State<StepPayment> createState() => _StepPaymentState();
}

class _StepPaymentState extends State<StepPayment> with TickerProviderStateMixin {
  late TextEditingController _ecocashController;
  String _selectedCountryCode = '+263';
  bool _wantsToAddNow = false;

  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProRegistrationBloc>().state;
    
    // Extract phone number without country code
    String phone = state.ecocashNumber;
    for (final country in AppConstants.countryCodes) {
      if (phone.startsWith(country['code']!)) {
        _selectedCountryCode = country['code']!;
        phone = phone.substring(country['code']!.length);
        break;
      }
    }
    _ecocashController = TextEditingController(text: phone);
    _wantsToAddNow = phone.isNotEmpty;

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
    _ecocashController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateBloc() {
    String fullNumber = '';
    if (_ecocashController.text.trim().isNotEmpty) {
      String value = _ecocashController.text.trim();
      if (value.startsWith('0')) {
        value = value.substring(1);
      }
      fullNumber = '$_selectedCountryCode$value';
    }
    context.read<ProRegistrationBloc>().add(ProRegistrationPaymentUpdated(fullNumber));
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
                              'Set up how you want to receive your earnings. This can be updated anytime.',
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
                    const SizedBox(height: 32),

                    // Option to add now or later
                    if (!_wantsToAddNow) ...[
                      FadeTransition(
                        opacity: _fadeAnimations[1],
                        child: SlideTransition(
                          position: _slideAnimations[1],
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.neutral200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neutral100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.account_balance_wallet_outlined, size: 40, color: AppTheme.neutral400),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Add EcoCash later?',
                                  style: GoogleFonts.nunitoSans(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.navy),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "You can skip this for now and add your EcoCash details later in your profile settings.",
                                  style: TextStyle(color: AppTheme.neutral500, fontSize: 14, height: 1.5),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                _buildGradientButton(
                                  onPressed: () => setState(() => _wantsToAddNow = true),
                                  text: 'Set Up Now',
                                  icon: Icons.add_rounded,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // EcoCash Number Form
                      FadeTransition(
                        opacity: _fadeAnimations[1],
                        child: SlideTransition(
                          position: _slideAnimations[1],
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.navy.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.navy.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.navy.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.phone_android_rounded, color: AppTheme.navy, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'EcoCash',
                                            style: GoogleFonts.nunitoSans(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.navy),
                                          ),
                                          Text(
                                            'Mobile Money Payouts',
                                            style: TextStyle(color: AppTheme.navy.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'ECOCASH NUMBER',
                                  style: GoogleFonts.nunitoSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.neutral500, letterSpacing: 1),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    // Country Code Dropdown
                                    Container(
                                      height: 54,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: AppTheme.neutral200),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedCountryCode,
                                          borderRadius: BorderRadius.circular(14),
                                          items: AppConstants.countryCodes.map((country) {
                                            return DropdownMenuItem<String>(
                                              value: country['code'],
                                              child: Text(
                                                '${country['flag']} ${country['code']}',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                                    const SizedBox(width: 10),
                                    // Phone Number Field
                                    Expanded(
                                      child: TextField(
                                        controller: _ecocashController,
                                        keyboardType: TextInputType.phone,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        decoration: InputDecoration(
                                          hintText: '77 123 4567',
                                          hintStyle: TextStyle(color: AppTheme.neutral300, fontWeight: FontWeight.normal),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.neutral200)),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.neutral200)),
                                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        ),
                                        onChanged: (_) => _updateBloc(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      _ecocashController.clear();
                                      _updateBloc();
                                      setState(() => _wantsToAddNow = false);
                                    },
                                    icon: const Icon(Icons.close_rounded, size: 14),
                                    label: const Text('Cancel & Set Up Later', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.neutral500,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),

                    // Info Box
                    FadeTransition(
                      opacity: _fadeAnimations[2],
                      child: SlideTransition(
                        position: _slideAnimations[2],
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.verified_outlined, color: AppTheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _wantsToAddNow && state.ecocashNumber.isNotEmpty
                                      ? 'Perfect! Your earnings will be automatically sent to this number after each task.'
                                      : 'No worries. You can add your payment details later before your first payout.',
                                  style: const TextStyle(color: AppTheme.navy, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
                          onPressed: state.status == ProRegistrationStatus.loading ? null : widget.onBack,
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
                          onPressed: state.status == ProRegistrationStatus.loading ? null : widget.onSubmit,
                          text: 'Submit Application',
                          isLoading: state.status == ProRegistrationStatus.loading,
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

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    bool isLoading = false,
  }) {
    final bool isDisabled = onPressed == null;
    
    return Container(
      width: double.infinity,
      height: 56,
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
        child: isLoading
            ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (icon == null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}
