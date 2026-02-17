import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/task/task_bloc.dart';
import '../../bloc/task/task_event.dart';
import '../../bloc/task/task_state.dart';
import '../../bloc/offer/offer_list_bloc.dart';
import '../../bloc/offer/offer_list_state.dart';
import '../../bloc/offer/offer_list_event.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../config/theme.dart';
import '../../core/service_locator.dart';
import '../../services/api_service.dart';
import '../../widgets/user_avatar.dart';
import '../tasks/offer_card.dart';
import '../../core/ui_utils.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String taskId;

  const ProjectDetailScreen({super.key, required this.taskId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late final OfferListBloc _offerListBloc;

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(TaskLoadById(widget.taskId));
    _offerListBloc = getIt<OfferListBloc>();
    _offerListBloc.add(LoadOffers(taskId: widget.taskId));
  }

  @override
  void dispose() {
    _offerListBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state.selectedTask == null) {
          return const Scaffold(body: Center(child: Text('Project not found')));
        }

        final task = state.selectedTask!;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, task),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProjectHeader(task),
                      const SizedBox(height: 24),
                      _buildDescription(task),
                      const SizedBox(height: 24),
                      _buildDocuments(task),
                      const SizedBox(height: 24),
                      _buildLocationTime(task),
                      const SizedBox(height: 24),
                      _buildOffersSection(context, task),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, task),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, Task task) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.navy,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (task.photos.isNotEmpty && task.photos.first.startsWith('http'))
              Image.network(
                task.photos.first, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppTheme.navy,
                  child: const Icon(Icons.apartment, size: 80, color: Colors.white24),
                ),
              )
            else
              Container(
                color: AppTheme.navy,
                child: const Icon(Icons.apartment, size: 80, color: Colors.white24),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildProjectHeader(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'PROJECT',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              task.category,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          task.title,
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.navy,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (task.poster != null)
              UserAvatar.fromUser(task.poster!, radius: 18)
            else
              UserAvatar(name: task.posterName ?? 'U', radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    task.posterName ?? 'Unknown User',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (task.posterRating != null)
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          task.posterRating!.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Text(
               '\$${UIUtils.formatBudget(task.budget)}',
               style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy),
        ),
        const SizedBox(height: 8),
        Text(
          task.description,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildDocuments(Task task) {
    if (task.attachments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Documents',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy),
        ),
        const SizedBox(height: 12),
        ...task.attachments.map((doc) => _buildDocTile(doc)).toList(),
      ],
    );
  }

  Widget _buildDocTile(TaskAttachment doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: const Icon(Icons.description, color: AppTheme.primary),
        title: Text(doc.name ?? 'Project Document', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.download, size: 20),
        onTap: () async {
          final uri = Uri.parse(doc.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }

  Widget _buildLocationTime(Task task) {
    final isTechnical = ['Electrical', 'Mechanical', 'Energy', 'Other'].contains(task.category);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.location_on, 'Location', task.locationAddress),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.straighten, 
            isTechnical ? 'Project Scale' : 'Project Size', 
            task.projectSize ?? 'Not specified',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.fact_check_outlined, 
            isTechnical ? 'Nature of Work' : 'Site Readiness', 
            task.siteReadiness ?? 'Not specified',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.calendar_today, 
            'Target Start', 
            task.deadline != null ? DateFormat('MMMM dd, yyyy').format(task.deadline!) : 'Flexible',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.visibility, 
            'Site Visit', 
            task.requiresSiteVisit ? 'Required' : 'Not required',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.navy)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOffersSection(BuildContext context, Task task) {
    return BlocProvider.value(
      value: _offerListBloc,
      child: BlocBuilder<OfferListBloc, OfferListState>(
        builder: (context, state) {
          if (state is OfferListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OfferListLoaded) {
            if (state.offers.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.history_edu, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('No quotes submitted yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Formal Quotes (${state.offers.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy),
                ),
                const SizedBox(height: 16),
                ...state.offers.map((offer) => OfferCard(offer: offer, taskOwnerId: task.posterId, task: task)).toList(),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Task task) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;
        final isVerified = authState is AuthAuthenticated ? authState.user.isVerified : false;
        final isOwner = currentUserId == task.posterId;

        if (isOwner) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Only verified contractors can bid on projects. Complete your verification in Profile.',
                          style: TextStyle(fontSize: 12, color: AppTheme.navy, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ElevatedButton(
                onPressed: isVerified ? () {
                  context.push('/tasks/${task.id}/make-offer', extra: task);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text('Submit Formal Quote', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }
}
