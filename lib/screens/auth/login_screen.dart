import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../config/theme.dart';
import '../../core/validators.dart';
import '../../widgets/brand_icons.dart';
import '../../services/api_service.dart';

/// Login screen following Airmass Xpress premium design
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isGoogleSignInEnabled = true;

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

    // Staggered animations for form elements
    // 0: Header, 1: Email, 2: Password, 3: Forgot Pass, 4: Button, 5: OR divider, 6: Social Auth, 7: Signup
    _fadeAnimations = List.generate(9, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.06, 0.3 + index * 0.06, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(9, (index) {
      return Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.06, 0.3 + index * 0.06, curve: Curves.easeOut),
        ),
      );
    });

    _checkGoogleSignInStatus();
    _animationController.forward();
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthLogin(
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
            icon: const Icon(Icons.close, color: AppTheme.textPrimary, size: 20),
            onPressed: () => context.go('/welcome'),
            splashRadius: 20,
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
              context.go('/home');
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
            child: SingleChildScrollView(
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
                          Text(
                            'Log in to your account',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.navy,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your details to continue',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    if (_isGoogleSignInEnabled) ...[
                      // Social Auth (Moved to Top)
                      _buildAnimatedWidget(
                        index: 1,
                        child: Column(
                          children: [
                            if (Platform.isIOS) ...[
                              BlocBuilder<AuthBloc, AuthState>(
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
                              const SizedBox(height: 12),
                            ],
                            if (_isGoogleSignInEnabled)
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return _buildSocialButton(
                                    context,
                                    label: 'Continue with Google',
                                    icon: Icons.g_mobiledata_outlined, // Using icon data instead of custom widget for consistency if possible, or adapt
                                    // But original code used BrandIcons.google() inside _buildSocialButton
                                    // Let's keep using _buildSocialButton but adapt it if needed.
                                    // Wait, _buildSocialButton signature in original code takes `icon: IconData`.
                                    // But Google button implementation had `BrandIcons.google()` HARDCODED inside `_buildSocialButton` implementation?
                                    // Let me check `_buildSocialButton` implementation first.
                                    color: AppTheme.textPrimary,
                                    isLoading: state is AuthLoading,
                                    onTap: () {
                                      context.read<AuthBloc>().add(AuthGoogleLogin());
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // OR Divider (Moved to Top)
                      _buildAnimatedWidget(
                        index: 2,
                        child: _buildPremiumDivider(text: 'OR LOGIN WITH EMAIL'),
                      ),

                      const SizedBox(height: 24),
                    ],
                    
                    // Email
                    _buildAnimatedWidget(
                      index: 3,
                      child: _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'Enter your email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        action: TextInputAction.next,
                        validator: Validators.email,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Password
                    _buildAnimatedWidget(
                      index: 4,
                      child: _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
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
                        onSubmitted: (_) => _onLogin(),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Forgot Password
                    _buildAnimatedWidget(
                      index: 5,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Login Button
                    _buildAnimatedWidget(
                      index: 6,
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
                              onPressed: state is AuthLoading ? null : _onLogin,
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
                                  : const Text(
                                      'Log In',
                                      style: TextStyle(
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
                    
                    const SizedBox(height: 32),
                    
                    // Sign Up Link
                    _buildAnimatedWidget(
                      index: 7,
                      child: Center(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: InkWell(
                                  onTap: () => context.go('/signup'),
                                  child: const Text(
                                    'Sign up',
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

                    const SizedBox(height: 24),

                    // Terms and Privacy Links
                     _buildAnimatedWidget(
                      index: 8,
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'By continuing, you agree to our',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () => _launchUrl('https://www.airmassxpress.com/terms'),
                                  child: const Text(
                                    'Terms & Conditions',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                Text(
                                  ' and ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _launchUrl('https://www.airmassxpress.com/privacy_policy'),
                                  child: const Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await canLaunchUrl(Uri.parse(url))) {
      debugPrint('Could not launch $url');
      return;
    }
    await launchUrl(Uri.parse(url));
  }

  Widget _buildAnimatedWidget({required int index, required Widget child}) {
    // Safety check just in case index is out of bounds
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
