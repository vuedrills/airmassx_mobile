import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../config/theme.dart';
import 'package:intl/intl.dart';
import '../screens/profile/public_profile_screen.dart';
import '../services/api_service.dart';
import '../core/service_locator.dart';
import 'user_avatar.dart';

/// Enhanced task card with budget box, location, offers count
class EnhancedTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const EnhancedTaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap ?? () => context.push('/tasks/${task.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Status and Date
              Row(
                children: [
                  _StatusBadge(status: task.status),
                  const Spacer(),
                  Icon(Icons.calendar_today, size: 14, color: AppTheme.neutral500),
                  const SizedBox(width: 4),
                  Text(
                    task.deadline != null ? DateFormat('MMM d').format(task.deadline!) : 'Flexible',
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.neutral500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Title and Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'task_title_${task.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: Text(
                          task.title,
                          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _PriceBadge(
                    amount: task.budget,
                    heroTag: 'task_price_${task.id}',
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Location
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: AppTheme.neutral500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.locationAddress,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.neutral500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                task.description,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutral700,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 20),
              
              // Footer: Poster and Offer Count
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
                        children: [
                          if (task.poster != null)
                            UserAvatar.fromUser(task.poster!, radius: 14, badgeSize: 10)
                          else
                            UserAvatar(
                              name: task.posterName ?? 'U',
                              profileImage: task.posterImage,
                              radius: 14,
                              isVerified: task.posterVerified ?? false,
                              badgeSize: 10,
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.posterName ?? 'Anonymous',
                              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.neutral800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.neutral50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.neutral200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (task.questionsCount > 0) ...[
                          Icon(Icons.chat_bubble_outline, size: 14, color: AppTheme.neutral600),
                          const SizedBox(width: 4),
                          Text(
                            '${task.questionsCount}',
                            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neutral800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 1, height: 12, color: AppTheme.neutral300),
                          const SizedBox(width: 8),
                        ],
                        Icon(Icons.local_offer_outlined, size: 14, color: AppTheme.neutral600),
                        const SizedBox(width: 6),
                        Text(
                          '${task.offersCount} bid${task.offersCount != 1 ? 's' : ''}',
                          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.neutral800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'open': color = AppTheme.success; break;
      case 'assigned': color = AppTheme.info; break;
      case 'completed': color = AppTheme.neutral500; break;
      default: color = AppTheme.neutral500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final double amount;
  final String? heroTag;
  
  const _PriceBadge({required this.amount, this.heroTag});

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'USD',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary.withOpacity(0.7),
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        child: Material(
          type: MaterialType.transparency,
          child: badge
        ),
      );
    }
    
    return badge;
  }
}
