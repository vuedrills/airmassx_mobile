import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/pro_registration/pro_registration_bloc.dart';
import '../../bloc/pro_registration/pro_registration_event.dart';
import '../../bloc/pro_registration/pro_registration_state.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../config/theme.dart';
import '../../core/service_locator.dart';
import '../../services/api_service.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/profile/profile_state.dart';
import 'steps/step_basic_info.dart';
import 'steps/step_identity.dart';
import 'steps/step_professions.dart';
import 'steps/step_portfolio.dart';
import 'steps/step_qualifications.dart';
import 'steps/step_location.dart';
import 'steps/step_payment.dart';

class ProRegistrationScreen extends StatelessWidget {
  final String? existingName;
  final String? existingPhone;
  final String? existingBio;
  final String? existingProfilePicture;

  const ProRegistrationScreen({
    super.key,
    this.existingName,
    this.existingPhone,
    this.existingBio,
    this.existingProfilePicture,
  });

  @override
  Widget build(BuildContext context) {
    // Attempt to get existing info from ProfileBloc or AuthBloc
    final profileState = context.read<ProfileBloc>().state;
    final authState = context.read<AuthBloc>().state;
    
    String? name = existingName;
    String? phone = existingPhone;
    String? bio = existingBio;
    String? profilePicture = existingProfilePicture;

    if (profileState is ProfileLoaded) {
      final profile = profileState.profile;
      name ??= profile.name;
      phone ??= profile.phone;
      bio ??= profile.bio;
      profilePicture ??= profile.profileImage;
    } else if (authState is AuthAuthenticated) {
      final user = authState.user;
      name ??= user.name;
      phone ??= user.phone;
      bio ??= user.bio;
      profilePicture ??= user.profileImage;
    }

    return BlocProvider(
      create: (_) => ProRegistrationBloc(
        getIt<ApiService>(),
        existingName: name,
        existingPhone: phone,
        existingBio: bio,
        existingProfilePicture: profilePicture,
      ),
      child: const _ProRegistrationView(),
    );
  }
}

class _ProRegistrationView extends StatefulWidget {
  const _ProRegistrationView();

  @override
  State<_ProRegistrationView> createState() => _ProRegistrationViewState();
}

class _ProRegistrationViewState extends State<_ProRegistrationView> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  static const _steps = [
    'Basic Info',
    'Identity',
    'Professions',
    'Portfolio',
    'Qualifications',
    'Location',
    'Payment',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimations = List.generate(4, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, 0.4 + index * 0.1, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(4, (index) {
      return Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, 0.4 + index * 0.1, curve: Curves.easeOut),
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
    return BlocConsumer<ProRegistrationBloc, ProRegistrationState>(
      listener: (context, state) {
        if (state.status == ProRegistrationStatus.success) {
          _showSuccessDialog(context);
        } else if (state.status == ProRegistrationStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Submission failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.navy),
              onPressed: () => context.pop(),
            ),
            title: Text(
              _steps[state.currentStep - 1],
              style: GoogleFonts.oswald(
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),
          body: Container(
            color: Colors.white,
            child: Column(
              children: [
                Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimations[1],
                      child: SlideTransition(
                        position: _slideAnimations[1],
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                            return Stack(
                              alignment: Alignment.topCenter,
                              children: <Widget>[
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            );
                          },
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.05, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            key: ValueKey<int>(state.currentStep),
                            child: _buildCurrentStep(context, state),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
      },
    );
  }


  Widget _buildCurrentStep(BuildContext context, ProRegistrationState state) {
    switch (state.currentStep) {
      case 1:
        return StepBasicInfo(
          onNext: () => _goToStep(context, 2),
        );
      case 2:
        return StepIdentity(
          onNext: () => _goToStep(context, 3),
          onBack: () => _goToStep(context, 1),
        );
      case 3:
        return StepProfessions(
          onNext: () => _goToStep(context, 4),
          onBack: () => _goToStep(context, 2),
        );
      case 4:
        return StepPortfolio(
          onNext: () => _goToStep(context, 5),
          onBack: () => _goToStep(context, 3),
        );
      case 5:
        return StepQualifications(
          onNext: () => _goToStep(context, 6),
          onBack: () => _goToStep(context, 4),
        );
      case 6:
        return StepLocation(
          onNext: () => _goToStep(context, 7),
          onBack: () => _goToStep(context, 5),
        );
      case 7:
        return StepPayment(
          onSubmit: () => context.read<ProRegistrationBloc>().add(ProRegistrationSubmitted()),
          onBack: () => _goToStep(context, 6),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _goToStep(BuildContext context, int step) {
    context.read<ProRegistrationBloc>().add(ProRegistrationStepChanged(step));
  }

  void _showSuccessDialog(BuildContext context) {
    // Store the outer context for ProfileBloc access
    final outerContext = context;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppTheme.success, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Application Submitted!',
              style: GoogleFonts.oswald(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your application is under review. We\'ll notify you once it\'s approved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                // Trigger profile reload
                outerContext.read<ProfileBloc>().add(LoadProfile());
                // Navigate back to profile
                outerContext.go('/home');
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

