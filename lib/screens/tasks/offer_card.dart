import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/offer.dart';
import '../../models/user.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../core/service_locator.dart';
import '../../bloc/offer/offer_list_bloc.dart';
import '../../bloc/offer/offer_list_event.dart';
import '../../bloc/task/task_bloc.dart';
import '../../bloc/task/task_event.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../profile/public_profile_screen.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/badge_widgets.dart';

class OfferCard extends StatelessWidget {
  final Offer offer;
  final String? taskOwnerId; // To show/hide accept button
  final dynamic task; // To check task status
  const OfferCard({required this.offer, this.taskOwnerId, this.task, super.key});

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      // Elevation and shape now inherit from AppTheme.cardTheme
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section: User Info + Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info section (Avatar + Details)
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () async {
                      final apiService = getIt<ApiService>();
                      try {
                        final user = await apiService.getUser(offer.taskerId);
                        if (user != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PublicProfileScreen(
                                user: user,
                                showRequestQuoteButton: true,
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
                                  id: offer.taskerId,
                                  name: offer.taskerName ?? 'Tasker',
                                  email: '',
                                  profileImage: offer.taskerImage,
                                  rating: offer.taskerRating ?? 0,
                                  isVerified: offer.taskerVerified ?? false,
                                  totalReviews: offer.reviewCount ?? 0,
                                ),
                                showRequestQuoteButton: true,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (offer.tasker != null)
                          UserAvatar.fromUser(offer.tasker!, radius: 26, showBadge: false)
                        else
                          UserAvatar(
                            name: offer.taskerName ?? 'T',
                            profileImage: offer.taskerImage,
                            radius: 26,
                            isVerified: offer.taskerVerified ?? false,
                            showBadge: false,
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        offer.taskerName ?? 'Tasker',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0E1638),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (offer.tasker != null && offer.tasker!.badges.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      const SizedBox(width: 8),
                                      BadgeIconRow(badges: offer.tasker!.badges, iconSize: 22, spacing: -4),
                                      ],
                                  ],
                                ),
                              const SizedBox(height: 2),
                              // Rating
                              // Rating
                              if (offer.isNew == true || (offer.taskerRating ?? 0) == 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'New!',
                                    style: TextStyle(
                                      color: Colors.purple.shade700,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                )
                              else if (offer.taskerRating != null)
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 22, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Text(
                                      offer.taskerRating!.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '(${offer.reviewCount ?? 0})',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              // Completion rate
                              if (offer.completionRate != null && (offer.taskerCompletedTasks ?? 0) >= 3) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${offer.completionRate}%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.navy,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Completion',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Price section pushed to the right
                Expanded(
                  flex: 2,
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      final currentUserId = authState is AuthAuthenticated ? authState.user.id.toLowerCase() : null;
                      final isAuthorized = currentUserId != null && 
                          (currentUserId == taskOwnerId?.toLowerCase() || 
                           currentUserId == offer.taskerId.toLowerCase());

                      if (!isAuthorized) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (offer.amount != null)
                            Text(
                              '\$${offer.amount!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            )
                          else
                            Container(
                              width: 80,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppTheme.primarySoft,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                              ),
                            ),
                          const Text(
                            'BID PRICE',
                            style: TextStyle(
                              fontSize: 8,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (offer.availability != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              offer.availability!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0E1638),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            
            if (offer.message.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Light gray background for offer message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  offer.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0E1638),
                    height: 1.4,
                  ),
                ),
              ),
            ],

            // Invoices (Shared with owner and tasker)
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final currentUserId = authState is AuthAuthenticated ? authState.user.id.toLowerCase() : null;
                final isAuthorized = currentUserId != null &&
                    (currentUserId == taskOwnerId?.toLowerCase() ||
                        currentUserId == offer.taskerId.toLowerCase());

                if (isAuthorized && offer.invoiceUrl != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: InkWell(
                      onTap: () async {
                        final uri = Uri.parse(offer.invoiceUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.description, size: 16, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              offer.invoiceFileName ?? 'View Invoice',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.open_in_new, size: 12, color: AppTheme.primary.withOpacity(0.5)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
            
            // Use FutureBuilder to check if current user is task owner
            FutureBuilder<User?>(
              future: getIt<ApiService>().getCurrentUser(),
              builder: (context, snapshot) {
                final isTaskOwner = snapshot.hasData && 
                    taskOwnerId != null && 
                    snapshot.data?.id == taskOwnerId;
                
                if (!isTaskOwner) return const SizedBox();
                
                final taskStatus = task?.status?.toLowerCase() ?? 'open';
                final isAnyOfferAccepted = taskStatus != 'open';

                if (offer.status == 'accepted') {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'ACCEPTED',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (isAnyOfferAccepted) return const SizedBox();

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final selectedMethod = await showModalBottomSheet<String>(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (BuildContext context) {
                              return SafeArea(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                                  ),
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Select Payment Method',
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.navy),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Choose how you want to secure this task payment.',
                                          style: TextStyle(color: AppTheme.textSecondary),
                                        ),
                                        const SizedBox(height: 24),
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.account_balance_wallet, color: Colors.grey),
                                          ),
                                          title: Row(
                                            children: [
                                              const Text('Secure Escrow', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('Coming Soon', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                              ),
                                            ],
                                          ),
                                          subtitle: const Text('Funds held in your wallet & released on completion.', style: TextStyle(color: Colors.grey)),
                                          // trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                          onTap: null, // Disabled
                                        ),
                                        const Divider(height: 24),
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.payments, color: Colors.green),
                                          ),
                                          title: const Text('Cash Payment', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy)),
                                          subtitle: const Text('Pay the professional directly in person.'),
                                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                          onTap: () => Navigator.pop(context, 'cash'),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
    
                          if (selectedMethod != null && context.mounted) {
                            // Get the OfferListBloc from context and dispatch accept event
                            final offerBloc = context.read<OfferListBloc>();
                            offerBloc.add(AcceptOffer(
                              offerId: offer.id,
                              taskId: offer.taskId,
                              paymentMethod: selectedMethod,
                            ));
    
                            // Also refresh the task to update the action card
                            context.read<TaskBloc>().add(TaskLoadById(offer.taskId));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
