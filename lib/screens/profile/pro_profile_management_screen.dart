import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
                          _buildSection(2, 'Work & Skills', [
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
                          _buildSection(3, 'Identity Verification', [
                            _buildCompactOption(
                              context,
                              title: 'ID Documents',
                              subtitle: state.idDocumentUrls.isNotEmpty ? 'Verified ✓' : 'Add verification documents',
                              icon: Icons.verified_user_outlined,
                              accentColor: Colors.blue,
                              onTap: () => _showIdentityDetail(context, state),
                            ),
                          ]),
                          _buildSection(4, 'Portfolio Showcase', [
                            _buildPortfolioManager(context, state),
                          ]),
                          _buildSection(5, 'Expertise & Training', [
                            _buildCompactOption(
                              context,
                              title: 'Qualifications',
                              subtitle: '${state.qualifications.length} certificates added',
                              icon: Icons.workspace_premium_outlined,
                              accentColor: Colors.amber,
                              onTap: () => _showQualificationsDetail(context, state),
                            ),
                          ]),
                          _buildSection(6, 'Payout Settings', [
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
        icon = Icons.verified;
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
            if (state.bio.isNotEmpty) ...[
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  state.bio,
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4),
                ),
              ),
            ],
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
              IconButton(
                onPressed: () => _addPortfolioImage(context),
                icon: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primary, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.portfolioUrls.isEmpty)
             Text(
               'No photos added yet. Showcase your work to attract more clients.',
               style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
             )
          else
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.portfolioUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(state.portfolioUrls[index], width: 100, height: 100, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            final urls = List<String>.from(state.portfolioUrls)..removeAt(index);
                            context.read<ProRegistrationBloc>().add(ProRegistrationPortfolioUpdated(urls));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 10, color: Colors.white),
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

  void _showIdentityDetail(BuildContext context, ProRegistrationState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                    Navigator.pop(context);
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
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
    );
  }

  void _editBasicInfo(BuildContext context, ProRegistrationState state) {
    final bioController = TextEditingController(text: state.bio);
    _showCustomDialog(context, 'Edit Summary', [
      TextFormField(
        controller: bioController,
        maxLines: 4,
        decoration: const InputDecoration(labelText: 'Professional Summary', hintText: 'Describe your skills and experience...'),
      ),
    ], () {
      context.read<ProRegistrationBloc>().add(ProRegistrationBasicInfoUpdated(bio: bioController.text.trim()));
    });
  }

  void _editProfessions(BuildContext context, ProRegistrationState state) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ProRegistrationBloc>(),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select Professions', style: GoogleFonts.oswald()),
              content: SizedBox(
                width: double.maxFinite,
                child: BlocBuilder<CategoryBloc, CategoryState>(
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
                        children: groups.entries.map((groupEntry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(groupEntry.key, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy, fontSize: 13)),
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 0,
                                children: groupEntry.value.map((cat) {
                                  final profession = cat.name;
                                  final isSelected = state.professionIds.contains(profession);
                                  return FilterChip(
                                    label: Text(profession, style: const TextStyle(fontSize: 11)),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      final currentIds = List<String>.from(state.professionIds);
                                      if (selected) {
                                        currentIds.add(profession);
                                      } else {
                                        currentIds.remove(profession);
                                      }
                                      context.read<ProRegistrationBloc>().add(ProRegistrationProfessionsUpdated(currentIds));
                                      setDialogState(() {});
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Done')),
              ],
            );
          }
        ),
      ),
    );
  }

  void _updateAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    try {
      final url = await getIt<ApiService>().uploadTaskerFile(File(image.path), 'portfolio');
      if (!context.mounted) return;
      final currentUrls = List<String>.from(context.read<ProRegistrationBloc>().state.portfolioUrls);
      currentUrls.add(url);
      context.read<ProRegistrationBloc>().add(ProRegistrationPortfolioUpdated(currentUrls));
    } catch (e) {
      if (!context.mounted) return;
      UIUtils.showSnackBar(context, 'Upload failed', isError: true);
    }
  }

  void _editQualifications(BuildContext context, ProRegistrationState state) {
    final nameController = TextEditingController();
    final issuerController = TextEditingController();
    final yearController = TextEditingController();
    String? certUrl;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text('Add Qualification', style: GoogleFonts.oswald()),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Certificate Name')),
                  const SizedBox(height: 12),
                  TextField(controller: issuerController, decoration: const InputDecoration(labelText: 'Issuing Institution')),
                  const SizedBox(height: 12),
                  TextField(controller: yearController, decoration: const InputDecoration(labelText: 'Year Obtained'), keyboardType: TextInputType.number),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                      if (image == null) return;
                      try {
                        final url = await getIt<ApiService>().uploadTaskerFile(File(image.path), 'qualification');
                        setModalState(() => certUrl = url);
                      } catch (e) {
                         UIUtils.showSnackBar(context, 'Upload failed', isError: true);
                      }
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: certUrl != null ? AppTheme.success : Colors.grey.shade300),
                      ),
                      child: certUrl != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(certUrl!, fit: BoxFit.cover))
                        : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: Colors.grey), Text('Upload Proof', style: TextStyle(fontSize: 10))]),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: certUrl == null ? null : () {
                  context.read<ProRegistrationBloc>().add(ProRegistrationQualificationAdded(
                    name: nameController.text.trim(),
                    issuer: issuerController.text.trim(),
                    date: yearController.text.trim(),
                    url: certUrl!,
                  ));
                  Navigator.pop(dialogContext);
                },
                child: const Text('Add'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _editPayment(BuildContext context, ProRegistrationState state) {
    String currentNum = state.ecocashNumber;
    if (currentNum.startsWith('+263')) currentNum = currentNum.substring(4);
    final controller = TextEditingController(text: currentNum);
    _showCustomDialog(context, 'EcoCash Payout', [
      const Text('Funds will be sent to this number.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      const SizedBox(height: 12),
      TextField(
        controller: controller,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'Phone Number', prefixText: '+263 '),
      ),
    ], () {
      String value = controller.text.trim();
      if (value.startsWith('0')) value = value.substring(1);
      context.read<ProRegistrationBloc>().add(ProRegistrationPaymentUpdated('+263$value'));
    });
  }

  void _showCustomDialog(BuildContext context, String title, List<Widget> children, VoidCallback onSave) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, style: GoogleFonts.oswald()),
        content: Column(mainAxisSize: MainAxisSize.min, children: children),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { onSave(); Navigator.pop(dialogContext); }, child: const Text('Update')),
        ],
      ),
    );
  }
}
