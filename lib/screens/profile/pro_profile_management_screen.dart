import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/portfolio_item.dart';

import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';
import '../../bloc/pro_registration/pro_registration_bloc.dart';
import '../../bloc/pro_registration/pro_registration_event.dart';
import '../../bloc/pro_registration/pro_registration_state.dart';
import '../../config/theme.dart';
import '../../core/service_locator.dart';
import '../../core/ui_utils.dart';
import '../../bloc/category/category_bloc.dart';
import '../../bloc/category/category_state.dart';
import '../../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/constants.dart';
import '../../models/tasker_profile.dart';
import '../../models/category.dart';

class ProProfileManagementScreen extends StatelessWidget {
  const ProProfileManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, profileState) {
        if (profileState is! ProfileLoaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return BlocProvider(
          create: (_) => ProRegistrationBloc(
            getIt<ApiService>(),
            initialProfile: profileState.profile,
          ),
          child: const _ProProfileManagementView(),
        );
      },
    );
  }
}

class _ProProfileManagementView extends StatefulWidget {
  const _ProProfileManagementView();

  @override
  State<_ProProfileManagementView> createState() => _ProProfileManagementViewState();
}

class _ProProfileManagementViewState extends State<_ProProfileManagementView> with TickerProviderStateMixin {
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

    _fadeAnimations = List.generate(10, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.08, 0.4 + index * 0.08, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(10, (index) {
      return Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.08, 0.4 + index * 0.08, curve: Curves.easeOut),
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
          UIUtils.showSnackBar(context, 'Professional profile updated successfully');
          context.read<ProfileBloc>().add(LoadProfile());
          context.pop();
        } else if (state.status == ProRegistrationStatus.failure) {
          UIUtils.showSnackBar(context, state.errorMessage ?? 'Update failed', isError: true);
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  AppTheme.primarySoft.withValues(alpha: 0.5),
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, state),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeTransition(
                            opacity: _fadeAnimations[0],
                            child: SlideTransition(
                              position: _slideAnimations[0],
                              child: _buildStatusBanner(context),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSection(1, 'Public Identity', [
                             _buildUserAvatarCard(context, state),
                          ]),
                          _buildSection(2, 'Professional Summary', [
                            _buildCompactOption(
                              context,
                              title: 'Bio & Experience',
                              subtitle: state.bio.isEmpty 
                                ? 'Tell clients about your expertise' 
                                : state.bio,
                              icon: Icons.description_outlined,
                              accentColor: Colors.deepPurple,
                              onTap: () => _editSummary(context, state),
                            ),
                          ]),
                          _buildSection(3, 'Work & Skills', [
                            _buildCompactOption(
                              context,
                              title: 'Professions',
                              subtitle: state.professionIds.isEmpty 
                                ? 'Select your skills' 
                                : state.professionIds.join(', '),
                              icon: Icons.work_outline,
                              accentColor: AppTheme.primary,
                              onTap: () => _editProfessions(context, state),
                            ),
                          ]),
                          _buildSection(4, 'Identity Verification', [
                            _buildCompactOption(
                              context,
                              title: 'ID Documents',
                              subtitle: state.idDocumentUrls.isNotEmpty ? 'Verified ✓' : 'Add verification documents',
                              icon: LucideIcons.shieldCheck,
                              accentColor: AppTheme.success,
                              onTap: () => _showIdentityDetail(context, state),
                            ),
                          ]),
                          _buildSection(5, 'Portfolio Showcase', [
                            _buildPortfolioManager(context, state),
                          ]),
                          _buildSection(6, 'Expertise & Training', [
                            _buildCompactOption(
                              context,
                              title: 'Qualifications',
                              subtitle: '${state.qualifications.length} certificates added',
                              icon: Icons.workspace_premium_outlined,
                              accentColor: Colors.amber,
                              onTap: () => _showQualificationsDetail(context, state),
                            ),
                          ]),
                          _buildSection(7, 'Payout Settings', [
                            _buildCompactOption(
                              context,
                              title: 'EcoCash Account',
                              subtitle: state.ecocashNumber.isEmpty ? 'Not linked' : state.ecocashNumber,
                              icon: Icons.account_balance_wallet_outlined,
                              accentColor: AppTheme.success,
                              onTap: () => _editPayment(context, state),
                            ),
                          ]),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ProRegistrationState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.navy),
            onPressed: () => context.pop(),
          ),
          Text(
            'PRO PROFILE',
            style: GoogleFonts.oswald(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.navy,
              letterSpacing: 1,
            ),
          ),
          if (state.status == ProRegistrationStatus.loading)
            const SizedBox(width: 48, height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: () => _handleSubmit(context),
              child: Text(
                'SAVE',
                style: GoogleFonts.nunitoSans(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(int index, String title, List<Widget> children) {
    return FadeTransition(
      opacity: _fadeAnimations[index % 10],
      child: SlideTransition(
        position: _slideAnimations[index % 10],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPremiumDivider(title),
            const SizedBox(height: 12),
            ...children.expand((w) => [w, const SizedBox(height: 12)]),
          ],
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
                colors: [Colors.transparent, Colors.grey[200]!],
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
            label.toUpperCase(),
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
                colors: [Colors.grey[200]!, Colors.transparent],
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
              color: Colors.black.withValues(alpha: 0.03),
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
                color: accentColor.withValues(alpha: 0.12),
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
                    style: GoogleFonts.nunitoSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  Widget _buildStatusBanner(BuildContext context) {
    final profileState = context.watch<ProfileBloc>().state as ProfileLoaded;
    final status = profileState.profile.taskerProfile?.status ?? 'not_started';
    
    Color color;
    IconData icon;
    String title;
    String message;

    switch (status) {
      case 'approved':
        color = AppTheme.success;
        icon = LucideIcons.shieldCheck;
        title = 'Approved Professional';
        message = 'Your profile is active and public.';
        break;
      case 'pending_review':
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        title = 'Pending Review';
        message = 'We are reviewing your recent updates.';
        break;
      default:
        color = AppTheme.accentRed;
        icon = Icons.error_outline;
        title = 'Verification Required';
        message = 'Complete your profile to start earning.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
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
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatarCard(BuildContext context, ProRegistrationState state) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppTheme.navy, AppTheme.accentRed.withValues(alpha: 0.4)],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        backgroundImage: state.profilePictureUrl != null ? NetworkImage(state.profilePictureUrl!) : null,
                        child: state.profilePictureUrl == null ? const Icon(Icons.person, size: 35, color: AppTheme.navy) : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _updateAvatar(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppTheme.navy, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.name,
                        style: GoogleFonts.nunitoSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy),
                      ),
                      Text(
                        state.phone,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _editBasicInfo(context, state),
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.navy, size: 20),
                ),
              ],
            ),
          ],
        ),
      );
  }

  Widget _buildPortfolioManager(BuildContext context, ProRegistrationState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Work Showcase',
                style: GoogleFonts.nunitoSans(fontWeight: FontWeight.bold, color: AppTheme.navy),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _addPortfolioLink(context),
                    icon: const Icon(Icons.link_outlined, color: AppTheme.primary, size: 22),
                    tooltip: 'Add Link',
                  ),
                  IconButton(
                    onPressed: () => _addPortfolioImage(context),
                    icon: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primary, size: 22),
                    tooltip: 'Add Image',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.portfolioItems.isEmpty)
             Text(
               'No items added yet. Showcase your work or add links to your profiles.',
               style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
             )
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.portfolioItems.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = state.portfolioItems[index];
                  final isLink = item.type == 'link';

                  return Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: AppTheme.neutral100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.neutral200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: isLink
                            ? _buildLinkItemPreview(item)
                            : Image.network(
                                item.url,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            final items = List<PortfolioItem>.from(state.portfolioItems)..removeAt(index);
                            context.read<ProRegistrationBloc>().add(ProRegistrationPortfolioUpdated(items));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                      if (isLink)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: GestureDetector(
                            onTap: () => _launchURL(item.url),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
                              child: const Icon(Icons.open_in_new, size: 12, color: AppTheme.primary),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLinkItemPreview(PortfolioItem item) {
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

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            item.title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.navy),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _showIdentityDetail(BuildContext context, ProRegistrationState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => BlocProvider.value(
        value: context.read<ProRegistrationBloc>(),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text('Verification Details', style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.navy)),
              const SizedBox(height: 20),
              _buildIdentityItem('ID Documents', state.idDocumentUrls.isNotEmpty ? 'Uploaded' : 'Action Required', Icons.badge_outlined),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityItem(String title, String status, IconData icon) {
    final bool isDone = status != 'Action Required';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (isDone ? AppTheme.success : AppTheme.accentRed).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: isDone ? AppTheme.success : AppTheme.accentRed, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(status, style: TextStyle(color: isDone ? AppTheme.success : AppTheme.accentRed, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  void _showQualificationsDetail(BuildContext context, ProRegistrationState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => BlocProvider.value(
        value: context.read<ProRegistrationBloc>(),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(modalContext).size.height * 0.8,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Qualifications', style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(modalContext);
                      _editQualifications(context, state);
                    },
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state.qualifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('No certifications added yet.', style: TextStyle(color: Colors.grey)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.qualifications.length,
                    itemBuilder: (context, index) {
                      final q = state.qualifications[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.workspace_premium, color: Colors.amber),
                        title: Text(q.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('${q.issuer} • ${q.date}', style: const TextStyle(fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.accentRed, size: 20),
                          onPressed: () {
                            context.read<ProRegistrationBloc>().add(ProRegistrationQualificationRemoved(index));
                            Navigator.pop(modalContext);
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ProRegistrationBloc>(),
        child: AlertDialog(
          title: Text('Submit for Review?', style: GoogleFonts.oswald()),
          content: const Text(
            'Any changes to your professional profile must be reviewed by our team. This usually takes 1-3 business days.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<ProRegistrationBloc>().add(ProRegistrationSubmitted());
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _editBasicInfo(BuildContext context, ProRegistrationState state) {
    _showIdentityForm(context);
  }

  void _showIdentityForm(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: parentContext.read<ProRegistrationBloc>(),
        child: const _IdentityFormModal(),
      ),
    );
  }

  void _editSummary(BuildContext context, ProRegistrationState state) {
    _showSummaryForm(context);
  }

  void _showSummaryForm(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: parentContext.read<ProRegistrationBloc>(),
        child: const _SummaryFormModal(),
      ),
    );
  }

  void _editProfessions(BuildContext context, ProRegistrationState state) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ProRegistrationBloc>(),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Select Professions', style: GoogleFonts.oswald(color: AppTheme.navy)),
          content: SizedBox(
            width: double.maxFinite,
            child: BlocBuilder<ProRegistrationBloc, ProRegistrationState>(
              builder: (context, proState) {
                return BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, catState) {
                    if (catState is! CategoryLoaded) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ));
                    }

                    final groups = {
                      'Trades & Artisanal': catState.getArtisanalCategories(),
                      'Professional Services': catState.getProfessionalCategories(),
                    };

                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: groups.entries.map<Widget>((groupEntry) {
                          final sectionTitle = groupEntry.key;
                          final categories = groupEntry.value;
                          
                          // Find "Other" category in this group
                          final otherCategory = categories.firstWhere(
                            (c) => c.name == 'Other',
                            orElse: () => categories.firstWhere((c) => c.name.toLowerCase() == 'other', orElse: () => categories.first), // Fallback
                          );
                          final hasOther = categories.any((c) => c.name == 'Other' || c.name.toLowerCase() == 'other');
                          final filteredCats = categories.where((c) => c.name != 'Other' && c.name.toLowerCase() != 'other').toList();

                          // Get selected subcategories for "Other"
                          final subcategoryNames = hasOther 
                              ? catState.getSubCategories(otherCategory.id).map((c) => c.name).toList()
                              : <String>[];
                          
                          final selectedSubCats = proState.professionIds
                              .where((id) => subcategoryNames.contains(id))
                              .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  sectionTitle,
                                  style: GoogleFonts.nunitoSans(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ...filteredCats.map<Widget>((cat) {
                                    final profession = cat.name;
                                    final isSelected = proState.professionIds.contains(profession);
                                    return FilterChip(
                                      label: Text(profession, style: const TextStyle(fontSize: 12)),
                                      selected: isSelected,
                                      selectedColor: AppTheme.primary.withValues(alpha: 0.1),
                                      checkmarkColor: AppTheme.primary,
                                      onSelected: (selected) {
                                        final currentIds = List<String>.from(proState.professionIds);
                                        if (selected) {
                                          if (!currentIds.contains(profession)) {
                                            currentIds.add(profession);
                                          }
                                        } else {
                                          currentIds.remove(profession);
                                        }
                                        context.read<ProRegistrationBloc>().add(ProRegistrationProfessionsUpdated(currentIds));
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(color: isSelected ? AppTheme.primary : Colors.grey.shade300),
                                      ),
                                      backgroundColor: Colors.white,
                                    );
                                  }),
                                  
                                  // "Other" ActionChip
                                  if (hasOther)
                                    ActionChip(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('Other', style: TextStyle(fontSize: 12)),
                                          if (selectedSubCats.isNotEmpty) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${selectedSubCats.length}',
                                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      onPressed: () => _showOtherOptionsSheet(context, sectionTitle, otherCategory),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(color: selectedSubCats.isNotEmpty ? AppTheme.primary : Colors.grey.shade300),
                                      ),
                                      backgroundColor: selectedSubCats.isNotEmpty ? AppTheme.primary.withValues(alpha: 0.1) : Colors.white,
                                      labelStyle: TextStyle(
                                        color: selectedSubCats.isNotEmpty ? AppTheme.primary : Colors.black87,
                                        fontWeight: selectedSubCats.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                ],
                              ),
                              
                              // Small chips for selected "Other" subcategories
                              if (selectedSubCats.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: selectedSubCats.map<Widget>((p) => Chip(
                                    label: Text(p, style: const TextStyle(fontSize: 10)),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: AppTheme.neutral100,
                                    deleteIcon: const Icon(Icons.close, size: 12),
                                    onDeleted: () {
                                      final currentIds = List<String>.from(proState.professionIds)..remove(p);
                                      context.read<ProRegistrationBloc>().add(ProRegistrationProfessionsUpdated(currentIds));
                                    },
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  )).toList(),
                                ),
                              ],
                              const SizedBox(height: 12),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('DONE', style: GoogleFonts.nunitoSans(fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _editQualifications(BuildContext context, ProRegistrationState state) {
    _showQualificationsForm(context);
  }

  void _updateAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 70,
      maxWidth: 1920,
    );
    if (image == null) return;
    try {
      final url = await getIt<ApiService>().uploadTaskerFile(File(image.path), 'profile_picture');
      if (!context.mounted) return;
      context.read<ProRegistrationBloc>().add(ProRegistrationBasicInfoUpdated(profilePictureUrl: url));
    } catch (e) {
      if (!context.mounted) return;
      UIUtils.showSnackBar(context, 'Upload failed', isError: true);
    }
  }

  void _addPortfolioImage(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 70,
      maxWidth: 1920,
    );
    if (image == null) return;
    try {
      final url = await getIt<ApiService>().uploadTaskerFile(File(image.path), 'portfolio');
      if (!context.mounted) return;
      final bloc = context.read<ProRegistrationBloc>();
      final currentItems = List<PortfolioItem>.from(bloc.state.portfolioItems);
      
      final newItem = PortfolioItem(
        title: 'Work Sample ${currentItems.length + 1}',
        url: url,
        type: 'image', // Explicitly set as image
      );
      
      bloc.add(ProRegistrationPortfolioUpdated([...currentItems, newItem]));
    } catch (e) {
      if (!context.mounted) return;
      UIUtils.showSnackBar(context, 'Upload failed', isError: true);
    }
  }

  void _addPortfolioLink(BuildContext context) {
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
                  Text(
                    'Add Portfolio Link',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Project Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. My Website',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('URL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      hintText: 'https://...',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final url = urlController.text.trim();
                        final title = titleController.text.trim();
                        if (url.isNotEmpty && title.isNotEmpty) {
                          final bloc = context.read<ProRegistrationBloc>();
                          final currentItems = List<PortfolioItem>.from(bloc.state.portfolioItems);
                          final newItem = PortfolioItem(
                            title: title, 
                            url: url, 
                            type: 'link', // Explicitly set as link
                          );
                          bloc.add(ProRegistrationPortfolioUpdated([...currentItems, newItem]));
                          Navigator.pop(modalContext);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                      child: const Text('Add Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQualificationsForm(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: parentContext.read<ProRegistrationBloc>(),
        child: const _QualificationFormModal(),
      ),
    );
  }

  void _editPayment(BuildContext context, ProRegistrationState state) {
    _showPaymentForm(context);
  }

  void _showPaymentForm(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: parentContext.read<ProRegistrationBloc>(),
        child: const _PaymentFormModal(),
      ),
    );
  }

  void _showOtherOptionsSheet(
    BuildContext parentContext,
    String sectionTitle,
    Category parentCategory,
  ) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: parentContext.read<ProRegistrationBloc>(),
        child: BlocProvider.value(
          value: parentContext.read<CategoryBloc>(),
          child: _OtherProfessionsModal(
            sectionTitle: sectionTitle,
            parentCategory: parentCategory,
          ),
        ),
      ),
    );
  }
}

class _OtherProfessionsModal extends StatelessWidget {
  final String sectionTitle;
  final Category parentCategory;

  const _OtherProfessionsModal({
    required this.sectionTitle,
    required this.parentCategory,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProRegistrationBloc, ProRegistrationState>(
      builder: (context, proState) {
        return BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, catState) {
            List<Category> subCategories = [];
            if (catState is CategoryLoaded) {
              subCategories = catState.getSubCategories(parentCategory.id);
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Additional $sectionTitle',
                            style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.navy),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      children: [
                        if (subCategories.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: Text('No additional categories found.', style: TextStyle(color: Colors.grey))),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: subCategories.map<Widget>((cat) {
                              final profession = cat.name;
                              final isSelected = proState.professionIds.contains(profession);
                              return FilterChip(
                                label: Text(profession),
                                selected: isSelected,
                                selectedColor: AppTheme.primary.withValues(alpha: 0.1),
                                checkmarkColor: AppTheme.primary,
                                onSelected: (selected) {
                                  final currentIds = List<String>.from(proState.professionIds);
                                  if (selected) {
                                    if (!currentIds.contains(profession)) {
                                      currentIds.add(profession);
                                    }
                                  } else {
                                    currentIds.remove(profession);
                                  }
                                  context.read<ProRegistrationBloc>().add(ProRegistrationProfessionsUpdated(currentIds));
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: isSelected ? AppTheme.primary : Colors.grey[200]!),
                                ),
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  color: isSelected ? AppTheme.primary : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.navy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _QualificationFormModal extends StatefulWidget {
  const _QualificationFormModal();

  @override
  State<_QualificationFormModal> createState() => _QualificationFormModalState();
}

class _QualificationFormModalState extends State<_QualificationFormModal> {
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _courseController = TextEditingController();
  final _dateController = TextEditingController();
  String? _certUrl;
  bool _isUploading = false;
  bool _isPdf = false;

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
  }

  Future<void> _loadCuratedData() async {
    final apiService = getIt<ApiService>();
    try {
      final qualTypes = await apiService.getQualificationTypes();
      final institutions = await apiService.getInstitutions();
      if (mounted) {
        setState(() {
          _qualificationTypes = qualTypes;
          _institutions = institutions;
        });
      }
    } catch (e) {
      debugPrint('Error loading curated data: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _courseController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add Qualification', style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 20),

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
                  const SizedBox(height: 20),
                  
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
                  const SizedBox(height: 20),

                  _buildLabel('Year Obtained'),
                  _buildTextField(_dateController, 'e.g. 2022', keyboardType: TextInputType.number),
                  const SizedBox(height: 32),
                  _buildLabel('Upload Document / Image'),
                  const SizedBox(height: 12),
                  _buildUploadSection(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(), 
        style: GoogleFonts.nunitoSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.neutral500, letterSpacing: 0.8)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildUploadSection() {
    return InkWell(
      onTap: _isUploading ? null : _pickDocument,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _certUrl != null ? AppTheme.success : Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: _isUploading 
          ? const Center(child: CircularProgressIndicator())
          : _certUrl != null
            ? _buildPreview()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, color: AppTheme.primary.withValues(alpha: 0.5), size: 48),
                  const SizedBox(height: 12),
                  const Text('Select Image or PDF', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy)),
                  const Text('Supports JPG, PNG, PDF', style: TextStyle(fontSize: 12, color: AppTheme.neutral500)),
                ],
              ),
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _isPdf
              ? Container(color: Colors.red[50], child: const Center(child: Icon(Icons.picture_as_pdf, color: Colors.red, size: 48)))
              : Image.network(_certUrl!, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: () => setState(() { _certUrl = null; _isPdf = false; }),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 16, color: AppTheme.accentRed),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    final bool isValid = _nameController.text.isNotEmpty && 
                        _courseController.text.isNotEmpty && 
                        _issuerController.text.isNotEmpty && 
                        _dateController.text.isNotEmpty && 
                        _certUrl != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isValid ? _save : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.navy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('ADD QUALIFICATION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
        ),
      ),
    );
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 70,
      maxWidth: 1920,
    );
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await getIt<ApiService>().uploadTaskerFile(File(image.path), 'qualification');
      setState(() {
        _certUrl = url;
        _isPdf = false;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) UIUtils.showSnackBar(context, 'Upload failed', isError: true);
    }
  }

  void _save() {
    context.read<ProRegistrationBloc>().add(ProRegistrationQualificationAdded(
      name: _nameController.text.trim(),
      courseName: _courseController.text.trim(),
      issuer: _issuerController.text.trim(),
      date: _dateController.text.trim(),
      url: _certUrl!,
    ));
    Navigator.pop(context);
  }

  Widget _buildDropdownWithOther({
    required String label,
    required List<String> items,
    required String? selectedValue,
    required bool isOther,
    required TextEditingController otherController,
    required String otherHint,
    required Function(String?) onChanged,
  }) {
    // Add "Other" to items if not present
    final List<String> dropdownItems = List.from(items);
    if (!dropdownItems.contains('Other')) {
      dropdownItems.add('Other');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: isOther ? 'Other' : selectedValue,
              isExpanded: true,
              hint: Text('Select $label', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
              items: dropdownItems.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        if (isOther) ...[
          const SizedBox(height: 12),
          _buildTextField(otherController, otherHint),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text('Specify your $label', style: TextStyle(fontSize: 11, color: AppTheme.primary.withValues(alpha: 0.7), fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }
}

class _SummaryFormModal extends StatefulWidget {
  const _SummaryFormModal();

  @override
  State<_SummaryFormModal> createState() => _SummaryFormModalState();
}

class _SummaryFormModalState extends State<_SummaryFormModal> {
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProRegistrationBloc>().state;
    _bioController = TextEditingController(text: state.bio);
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Professional Summary', style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'This summary helps clients understand your expertise and why they should hire you. Keep it professional and highlight your key strengths.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
                    ),
                  ),
                  Text('YOUR BIO', 
                    style: GoogleFonts.nunitoSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.neutral500, letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bioController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'e.g. I am a certified electrician with over 10 years of experience in both residential and industrial wiring...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  context.read<ProRegistrationBloc>().add(ProRegistrationBasicInfoUpdated(bio: _bioController.text.trim()));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('UPDATE SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentFormModal extends StatefulWidget {
  const _PaymentFormModal();

  @override
  State<_PaymentFormModal> createState() => _PaymentFormModalState();
}

class _PaymentFormModalState extends State<_PaymentFormModal> {
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProRegistrationBloc>().state;
    String currentNum = state.ecocashNumber;
    if (currentNum.startsWith('+263')) {
      currentNum = currentNum.substring(4);
    } else if (currentNum.startsWith('0')) {
      currentNum = currentNum.substring(1);
    }
    _phoneController = TextEditingController(text: currentNum);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('EcoCash Payout', style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.success.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.success, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Funds will be automatically sent to this EcoCash number upon task completion.',
                          style: TextStyle(color: Colors.green.shade800, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('ECOCASH NUMBER', 
                  style: GoogleFonts.nunitoSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.neutral500, letterSpacing: 0.8)),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                  decoration: InputDecoration(
                    prefixText: '+263 ',
                    prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy),
                    hintText: '771111111',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      String value = _phoneController.text.trim();
                      if (value.startsWith('0')) value = value.substring(1);
                      if (value.isNotEmpty) {
                        context.read<ProRegistrationBloc>().add(ProRegistrationPaymentUpdated('+263$value'));
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('UPDATE PAYOUT NUMBER', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _IdentityFormModal extends StatefulWidget {
  const _IdentityFormModal();

  @override
  State<_IdentityFormModal> createState() => _IdentityFormModalState();
}

class _IdentityFormModalState extends State<_IdentityFormModal> {
  late TextEditingController _nameController;
  String? _professionalType;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProRegistrationBloc>().state;
    _nameController = TextEditingController(text: state.name);
    _professionalType = state.professionalType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Account Identity', style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DISPLAY NAME', 
                  style: GoogleFonts.nunitoSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.neutral500, letterSpacing: 0.8)),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. John Doe',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),
                Text('PROFESSIONAL CATEGORY', 
                  style: GoogleFonts.nunitoSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.neutral500, letterSpacing: 0.8)),
                const SizedBox(height: 12),
                _buildProfessionalTypeSelector(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_nameController.text.trim().isNotEmpty) {
                        context.read<ProRegistrationBloc>().add(ProRegistrationBasicInfoUpdated(
                          name: _nameController.text.trim(),
                          professionalType: _professionalType,
                        ));
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _TypeChip(
            label: 'Artisanal / Skilled',
            isSelected: _professionalType == 'artisanal',
            onTap: () => setState(() => _professionalType = 'artisanal'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeChip(
            label: 'White Collar',
            isSelected: _professionalType == 'white_collar',
            onTap: () => setState(() => _professionalType = 'white_collar'),
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.navy,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
