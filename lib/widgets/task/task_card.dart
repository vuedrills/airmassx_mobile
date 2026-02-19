import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/task.dart';
import '../../models/user.dart';
import '../../config/theme.dart';
import '../../screens/profile/public_profile_screen.dart';
import '../../services/api_service.dart';
import '../../core/service_locator.dart';
import '../user_avatar.dart';
import '../badge_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../models/badge.dart';
import '../../core/ui_utils.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return AppTheme.info;
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      case 'open':
      case 'posted':
        return AppTheme.navy.withOpacity(0.05);
      default:
        return AppTheme.neutral200;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'open':
      case 'posted':
        return 'Open';
      default:
        return status;
    }
  }

  String _getFirstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'User';
    return fullName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = task.status.toLowerCase() == 'open' || task.status.toLowerCase() == 'posted';
    
    return Material(
      color: Colors.transparent,
      child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (task.taskType == 'project') {
                context.push('/projects/${task.id}');
              } else {
                context.push('/tasks/${task.id}');
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Title and Status Badge (in upper right)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                task.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.navy,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 60), // Space for status badge
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Row 2: Description (Compact)
                      Text(
                        task.description.trim(),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Row 3: Tags (Category, Location, Time)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.navy.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.category,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.navy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.neutral500),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              task.locationAddress,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.neutral500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeago.format(task.createdAt, locale: 'en_short'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.neutral400,
                            ),
                          ),
                        ],
                      ),
                      
                      const Divider(height: 24, thickness: 0.5),

                      // Row 4: Footer (Poster Identity + Budget/Counts)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final apiService = getIt<ApiService>();
                                try {
                                  final user = await apiService.getUser(task.posterId);
                                  if (user != null && context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PublicProfileScreen(
                                          user: user,
                                          showRequestQuoteButton: false,
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PublicProfileScreen(
                                          user: User(
                                            id: task.posterId,
                                            name: task.posterName ?? 'User',
                                            email: '',
                                            profileImage: task.posterImage,
                                            rating: task.posterRating ?? 0,
                                            isVerified: task.posterVerified ?? false,
                                          ),
                                          showRequestQuoteButton: false,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (task.poster != null)
                                    UserAvatar.fromUser(task.poster!, radius: 12, showBadge: false)
                                  else
                                    UserAvatar(
                                      name: task.posterName ?? 'U',
                                      profileImage: task.posterImage,
                                      radius: 12,
                                      isVerified: task.posterVerified ?? false,
                                      showBadge: false,
                                    ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _getFirstName(task.posterName),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppTheme.neutral700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Rating
                                  if ((task.posterRating ?? 0) > 0) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.star, size: 12, color: Colors.amber),
                                    Text(
                                      task.posterRating!.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.neutral600,
                                      ),
                                    ),
                                  ] else ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        'New!',
                                        style: TextStyle(
                                          color: Colors.purple.shade700,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                  // Dynamic Badges from poster - Limited to 1 to prevent overflow
                                  if (task.poster != null && task.poster!.badges.isNotEmpty) ...[
                                    const SizedBox(width: 4),
                                    BadgeIconRow(
                                      badges: task.poster!.badges,
                                      iconSize: 16,
                                      spacing: -3,
                                      maxVisible: 1, // Reduced from 2
                                    ),
                                  ] else if (task.posterVerified == true) ...[
                                    // Fallback to verified badge if poster object not available
                                    const SizedBox(width: 4),
                                    const BadgeIcon(badgeId: BadgeIds.idVerified, size: 16),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Counts with "bids" label
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_offer_outlined, size: 14, color: AppTheme.neutral500),
                              const SizedBox(width: 2),
                              Text(
                                '${task.offersCount} ${task.offersCount == 1 ? 'bid' : 'bids'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.neutral700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          // Budget
                              Text(
                                '\$${UIUtils.formatBudget(task.budget)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                          const SizedBox(width: 8),
                          // Place a Bid button (only if open and not own task)
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, authState) {
                              final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;
                              final canBid = isOpen && currentUserId != null && currentUserId != task.posterId;
                              
                              if (canBid) {
                                return GestureDetector(
                                  onTap: () => context.push('/tasks/${task.id}'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(4), // Less round
                                      border: Border.all(
                                        color: AppTheme.primary.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'Place a bid',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Badge in Upper Right Corner
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildStatusBadge(),
                ),
              ],
            ),
          ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = task.status.toLowerCase();
    final isPassive = status == 'open' || status == 'posted';
    final bgColor = _getStatusColor(task.status);
    final textColor = isPassive ? AppTheme.navy : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getStatusLabel(task.status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
