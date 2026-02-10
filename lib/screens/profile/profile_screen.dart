import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';
import '../../config/theme.dart';
import '../../core/ui_utils.dart';
import '../../widgets/badge_widgets.dart';
import '../../widgets/user_avatar.dart';

/// Enhanced profile screen matching welcome screen design
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Create staggered animations for elements
    _fadeAnimations = List.generate(8, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.08, 0.4 + index * 0.08, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(8, (index) {
      return Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.08, 0.4 + index * 0.08, curve: Curves.easeOut),
        ),
      );
    });

    _animationController.forward();
  }

  void _loadProfile() {
    final profileBloc = context.read<ProfileBloc>();
    final currentState = profileBloc.state;
    if (currentState is! ProfileLoaded && currentState is! ProfileLoading) {
      profileBloc.add(LoadProfile());
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is! AuthAuthenticated) {
                return _buildUnauthenticatedView(context);
              }

              return BlocListener<ProfileBloc, ProfileState>(
                listener: (context, profileState) {
                  if (profileState is ProfileError) {
                    UIUtils.showSnackBar(context, profileState.message, isError: true);
                  }
                },
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, profileState) {
                    if (profileState is ProfileLoading || profileState is ProfileUpdating) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (profileState is ProfileLoaded) {
                      return _buildAuthenticatedView(context, profileState);
                    }

                    if (profileState is ProfileError) {
                      return _buildErrorView(context, profileState);
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      context.read<ProfileBloc>().add(LoadProfile());
                    });

                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, ProfileError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Failed to load profile', style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(state.message, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.read<ProfileBloc>().add(LoadProfile()),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _fadeAnimations[0],
            child: SlideTransition(
              position: _slideAnimations[0],
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_circle_outlined,
                  size: 64,
                  color: AppTheme.navy,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _fadeAnimations[1],
            child: SlideTransition(
              position: _slideAnimations[1],
              child: Text(
                'Log in or Sign up',
                style: GoogleFonts.oswald(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FadeTransition(
            opacity: _fadeAnimations[2],
            child: SlideTransition(
              position: _slideAnimations[2],
              child: Text(
                'Join the community to get tasks done or earn money.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          FadeTransition(
            opacity: _fadeAnimations[3],
            child: SlideTransition(
              position: _slideAnimations[3],
              child: _buildPrimaryActionCard(
                context,
                title: 'Log in',
                icon: Icons.login_rounded,
                onTap: () => context.go('/login'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeTransition(
            opacity: _fadeAnimations[4],
            child: SlideTransition(
              position: _slideAnimations[4],
              child: _buildCompactOption(
                context,
                title: 'Create an Account',
                subtitle: 'Join Airmass Xpress today',
                icon: Icons.person_add_outlined,
                accentColor: AppTheme.primary,
                onTap: () => context.go('/signup'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedView(BuildContext context, ProfileLoaded state) {
    final profile = state.profile;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProfileBloc>().add(LoadProfile());
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with settings
            FadeTransition(
              opacity: _fadeAnimations[0],
              child: SlideTransition(
                position: _slideAnimations[0],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Profile',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.neutral600,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              profile.name,
                              style: GoogleFonts.oswald(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navy,
                              ),
                            ),
                            if (profile.badges.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              BadgeIconRow(badges: profile.badges, iconSize: 20, spacing: -4),
                            ],
                          ],
                        ),
                      ],
                    ),
                    _buildSettingsButton(context),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // User Avatar Card
            FadeTransition(
              opacity: _fadeAnimations[1],
              child: SlideTransition(
                position: _slideAnimations[1],
                child: _buildUserAvatarCard(context, profile),
              ),
            ),
            const SizedBox(height: 16),

            // Stats Cards Row
            FadeTransition(
              opacity: _fadeAnimations[2],
              child: SlideTransition(
                position: _slideAnimations[2],
                child: _buildStatsRow(profile),
              ),
            ),
            const SizedBox(height: 20),

            // Professional Banner
            if (!(profile.isVerified && profile.taskerProfile?.status == 'approved'))
              FadeTransition(
                opacity: _fadeAnimations[3],
                child: SlideTransition(
                  position: _slideAnimations[3],
                  child: _buildProUpgradeBanner(
                    context,
                    profile.taskerProfile?.status ?? profile.verificationType,
                  ),
                ),
              ),

            // Divider
            _buildPremiumDivider('Account'),
            const SizedBox(height: 12),

            // Account Section
            _buildCompactOption(
              context,
              title: 'Personal Info',
              subtitle: 'Manage your personal details',
              icon: Icons.person_outline,
              accentColor: AppTheme.primary,
              onTap: () => context.push('/profile/personal-info'),
            ),
            const SizedBox(height: 10),
            _buildCompactOption(
              context,
              title: 'Manage Equipment',
              subtitle: 'Add or edit your equipment items',
              icon: Icons.construction_outlined,
              accentColor: const Color(0xFFE67E22),
              onTap: () => context.push('/profile/inventory'),
            ),
            const SizedBox(height: 10),
            _buildCompactOption(
              context,
              title: 'My Disputes',
              subtitle: 'View and manage your disputes',
              icon: Icons.gavel_outlined,
              accentColor: AppTheme.accentRed,
              onTap: () => context.push('/profile/disputes'),
            ),
            const SizedBox(height: 10),
            _buildCompactOption(
              context,
              title: (profile.isProfessional || profile.isProfessionalPending) ? 'Professional Profile' : 'Verification',
              subtitle: _getVerificationStatus(profile),
              icon: Icons.verified_user_outlined,
              accentColor: _getVerificationColor(profile),
              onTap: () {
                if (profile.isProfessional || profile.isProfessionalPending) {
                  context.push('/profile/pro-profile');
                } else if (!profile.isVerified && profile.verificationType == 'pending_review') {
                  UIUtils.showSnackBar(context, 'Your identity verification is currently under review.', isError: false);
                } else {
                  context.push('/profile/onboarding');
                }
              },
            ),
            const SizedBox(height: 20),

            // Divider
            _buildPremiumDivider('Payment'),
            const SizedBox(height: 12),

            // Payment Section
            _buildCompactOption(
              context,
              title: 'Payment Settings',
              subtitle: 'Manage your payment methods',
              icon: Icons.payment,
              accentColor: AppTheme.secondary,
              onTap: () => context.push('/profile/payment-settings'),
            ),
            const SizedBox(height: 10),
            _buildCompactOption(
              context,
              title: 'Payment History',
              subtitle: 'View your transaction history',
              icon: Icons.history,
              accentColor: AppTheme.navy,
              onTap: () => context.push('/profile/payment-history'),
            ),
            const SizedBox(height: 20),

            // Divider
            _buildPremiumDivider('Settings'),
            const SizedBox(height: 12),

            // Settings Section
            _buildCompactOption(
              context,
              title: 'Notification Settings',
              subtitle: 'Configure your notifications',
              icon: Icons.notifications_outlined,
              accentColor: AppTheme.warning,
              onTap: () => context.push('/profile/notifications'),
            ),
            const SizedBox(height: 10),
            _buildCompactOption(
              context,
              title: 'Help & Support',
              subtitle: 'Get help or contact us',
              icon: Icons.help_outline,
              accentColor: AppTheme.info,
              onTap: () => context.push('/profile/help'),
            ),
            const SizedBox(height: 10),
            _buildCompactOption(
              context,
              title: 'About Airmass Xpress',
              subtitle: 'App info and legal',
              icon: Icons.info_outline,
              accentColor: AppTheme.neutral500,
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Airmass Xpress',
                  applicationVersion: '1.0.0',
                );
              },
            ),
            const SizedBox(height: 24),

            // Log out button
            _buildLogoutCard(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/profile/help'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.settings_outlined, color: AppTheme.navy, size: 22),
      ),
    );
  }

  Widget _buildUserAvatarCard(BuildContext context, profile) {
    return InkWell(
      onTap: () => context.push('/profile/edit'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with gradient border
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.navy,
                    AppTheme.navy.withOpacity(0.6),
                    AppTheme.accentRed.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: UserAvatar.fromProfile(
                  profile,
                  radius: 30,
                  showBadge: false,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Profile',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (profile.rating > 0) ...[
                        Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${profile.rating}',
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ] else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'New!',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ),
                      Container(
                        height: 12,
                        width: 1,
                        color: AppTheme.neutral200,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Text(
                        '${profile.totalReviews} reviews',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.navy.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit, size: 16, color: AppTheme.navy),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(profile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              '${(profile.completionRate.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
              'Completion',
              Icons.check_circle_rounded,
              AppTheme.success,
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppTheme.neutral200,
          ),
          Expanded(
            child: _buildStatItem(
              '${profile.completedTasks}',
              'Tasks Done',
              Icons.task_alt_rounded,
              AppTheme.navy,
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppTheme.neutral200,
          ),
          Expanded(
            child: _buildStatItem(
              '\$${profile.totalEarnings.toStringAsFixed(0)}',
              'Earned',
              Icons.attach_money_rounded,
              AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.nunitoSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProUpgradeBanner(BuildContext context, String? status) {
    String title = 'Become a Professional';
    String subtitle = 'Earn money by completing tasks with your skills.';
    IconData icon = Icons.stars_rounded;
    bool showButton = true;
    String buttonText = 'Apply Now';

    if (status == 'pending_review') {
      title = 'Application Pending';
      subtitle = 'We are currently reviewing your professional profile.';
      icon = Icons.hourglass_empty;
      showButton = false;
    } else if (status == 'in_progress') {
      title = 'Complete Your Setup';
      subtitle = 'Finish your professional registration to start earning.';
      icon = Icons.edit_note;
      buttonText = 'Continue Setup';
    } else if (status == 'approved') {
      title = 'Professional Status: Approved';
      subtitle = 'You are a verified professional on Airmass Xpress.';
      icon = Icons.verified_user;
      showButton = false;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: showButton ? () => context.push('/profile/pro-registration') : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.navy, AppTheme.navyLight],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.navy.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (showButton)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumDivider(String label) {
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.neutral100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 1,
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

  Widget _buildCompactOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.navy, AppTheme.navyLight],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.navy.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context) {
    return InkWell(
      onTap: () => context.read<AuthBloc>().add(AuthLogout()),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.logout_rounded, color: AppTheme.accentRed, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              'Log out',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVerificationStatus(profile) {
    if (profile.isVerified || profile.taskerProfile?.status == 'approved') return 'Verified ✓';
    if (profile.verificationType == 'pending_review' || profile.taskerProfile?.status == 'pending_review') return 'Under review...';
    return 'Action required';
  }

  Color _getVerificationColor(profile) {
    if (profile.isVerified || profile.taskerProfile?.status == 'approved') return AppTheme.success;
    if (profile.verificationType == 'pending_review' || profile.taskerProfile?.status == 'pending_review') return AppTheme.warning;
    return AppTheme.accentRed;
  }
}
