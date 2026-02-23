import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../config/theme.dart';
import '../../core/validators.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../widgets/brand_icons.dart';
import '../../services/api_service.dart';

/// Register screen following Airmass Xpress premium design
/// Two-step flow: 1) Account type selection  2) Sign-up form
class RegisterScreen extends StatefulWidget {
  final String? accountType;

  const RegisterScreen({
    super.key,
    this.accountType,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _acceptedTerms = false;
  bool _wantsToEarn = false;
  bool _isGoogleSignInEnabled = true;

  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();

    // Default to 'client' (false) unless 'pro' or 'tasker' is specified
    if (widget.accountType != null) {
      _wantsToEarn = widget.accountType == 'pro' || widget.accountType == 'tasker';
    }

    _initFormAnimations();
    _checkGoogleSignInStatus();
    _animationController.forward();
  }

  void _initFormAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Staggered animations for form fields
    _fadeAnimations = List.generate(10, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.06, 0.4 + index * 0.06, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(10, (index) {
      return Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.06, 0.4 + index * 0.06, curve: Curves.easeOut),
        ),
      );
    });
  }

  Future<void> _checkGoogleSignInStatus() async {
    final enabled = await ApiService().getGoogleSignInStatus();
    if (mounted) {
      setState(() {
        _isGoogleSignInEnabled = enabled;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions'),
          backgroundColor: AppTheme.accentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthRegister(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 20),
            splashRadius: 20,
            onPressed: () {
              context.go('/login');
            },
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              AppTheme.primarySoft.withOpacity(0.5),
              Colors.white,
            ],
          ),
        ),
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.read<ProfileBloc>().add(LoadProfile());
              if (_wantsToEarn) {
                context.go('/home?tab=4&action=pro_registration');
              } else {
                context.go('/home?tab=0');
              }
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.accentRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: SafeArea(
            child: _buildSignUpFormStep(),
          ),
        ),
      ),
    );
  }

  // =============================================
  // ACCOUNT TYPE TOGGLE
  // =============================================

  Widget _buildAccountTypeToggle() {
    return Container(
      height: 56, // Fixed height for consistent tap target
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA), // Neutral light background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Stack(
        children: [
          // Animated Background Pill
          AnimatedAlign(
            alignment: _wantsToEarn ? Alignment.centerRight : Alignment.centerLeft,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubicEmphasized,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Interactive Labels
          Row(
            children: [
              _buildAnimatedToggleOption(
                title: 'Client',
                isSelected: !_wantsToEarn,
                onTap: () => setState(() => _wantsToEarn = false),
              ),
              _buildAnimatedToggleOption(
                title: 'Service Provider',
                isSelected: _wantsToEarn,
                onTap: () => setState(() => _wantsToEarn = true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedToggleOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppTheme.primary : Colors.grey[500],
              letterSpacing: 0.3,
            ),
            child: Text(title),
          ),
        ),
      ),
    );
  }

  // =============================================
  // STEP 1: Sign-Up Form
  // =============================================

  Widget _buildSignUpFormStep() {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            
            // Header
            _buildAnimatedWidget(
              index: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account type pill indicator removed
                  const SizedBox(height: 12),
                  Text(
                    'Create your account',
                    style: GoogleFonts.oswald(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your details to get started',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildAccountTypeToggle(),
                ],
              ),
            ),

            const SizedBox(height: 32),

            if (Platform.isIOS) ...[
              _buildAnimatedWidget(
                index: 1,
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return _buildSocialButton(
                      context,
                      label: 'Continue with Apple',
                      icon: Icons.apple,
                      color: Colors.black,
                      textColor: Colors.white,
                      backgroundColor: Colors.black,
                      isLoading: state is AuthLoading,
                      onTap: () {
                        context.read<AuthBloc>().add(AuthAppleLogin());
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_isGoogleSignInEnabled) ...[
              // Social Auth
              _buildAnimatedWidget(
                index: 1,
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return _buildSocialButton(
                      context,
                      label: 'Continue with Google',
                      icon: Icons.g_mobiledata_outlined,
                      color: AppTheme.textPrimary,
                      isLoading: state is AuthLoading,
                      onTap: () {
                        context.read<AuthBloc>().add(AuthGoogleLogin());
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // OR Divider
              _buildAnimatedWidget(
                index: 2,
                child: _buildPremiumDivider(text: 'OR SIGN UP WITH EMAIL'),
              ),
              
              const SizedBox(height: 24),
            ],
            
            // Full Name
            _buildAnimatedWidget(
              index: 3,
              child: _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'John Doe',
                icon: Icons.person_outline,
                textCapitalization: TextCapitalization.words,
                action: TextInputAction.next,
                validator: Validators.name,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Email
            _buildAnimatedWidget(
              index: 4,
              child: _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'john@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                action: TextInputAction.next,
                validator: Validators.email,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Password
            _buildAnimatedWidget(
              index: 5,
              child: _buildTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Create a strong password',
                icon: Icons.lock_outline,
                isPassword: true,
                isPasswordVisible: _isPasswordVisible,
                onVisibilityToggle: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                action: TextInputAction.done,
                validator: Validators.password,
                onSubmitted: (_) => _onRegister(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Terms Checkbox
            _buildAnimatedWidget(
              index: 6,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _acceptedTerms 
                     ? AppTheme.primary.withOpacity(0.05) 
                     : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _acceptedTerms 
                       ? AppTheme.primary.withOpacity(0.2) 
                       : Colors.transparent
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _acceptedTerms,
                        activeColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _acceptedTerms = value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: 'I accept the ',
                              recognizer: TapGestureRecognizer()..onTap = () {
                                setState(() {
                                  _acceptedTerms = !_acceptedTerms;
                                });
                              },
                            ),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: const TextStyle(
                                color: AppTheme.navy,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchUrl('https://www.airmassxpress.com/terms'),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: AppTheme.navy,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchUrl('https://www.airmassxpress.com/privacy_policy'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Register Button
            _buildAnimatedWidget(
              index: 7,
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: state is AuthLoading ? null : _onRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: state is AuthLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _wantsToEarn ? 'Sign Up & Start Earning' : 'Create Account',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Login Link
            _buildAnimatedWidget(
              index: 8,
              child: Center(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                    children: [
                      const TextSpan(text: "Already have an account? "),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: InkWell(
                          onTap: () => context.go('/login'),
                          child: const Text(
                            'Log in',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // =============================================
  // SHARED HELPER WIDGETS
  // =============================================

  Future<void> _launchUrl(String url) async {
    if (!await canLaunchUrl(Uri.parse(url))) {
      debugPrint('Could not launch $url');
      return;
    }
    await launchUrl(Uri.parse(url));
  }

  Widget _buildAnimatedWidget({required int index, required Widget child}) {
    final safeIndex = index.clamp(0, _fadeAnimations.length - 1);
    return FadeTransition(
      opacity: _fadeAnimations[safeIndex],
      child: SlideTransition(
        position: _slideAnimations[safeIndex],
        child: child,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction? action,
    String? Function(String?)? validator,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onVisibilityToggle,
    void Function(String)? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: action,
        validator: validator,
        onFieldSubmitted: onSubmitted,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: AppTheme.primary),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey[500],
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.accentRed),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumDivider({String text = 'OR CONTINUE WITH'}) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.grey[300]!],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.neutral100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[300]!, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    Color backgroundColor = Colors.white,
    Color? textColor,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: backgroundColor == Colors.white ? Border.all(color: Colors.grey[200]!) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isLoading 
          ? Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: textColor ?? AppTheme.primary,
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (label.contains('Google'))
                  BrandIcons.google()
                else
                  Icon(icon, color: textColor ?? color, size: 24),
                  
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? color,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
