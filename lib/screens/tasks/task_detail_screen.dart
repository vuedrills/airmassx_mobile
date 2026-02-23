import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../bloc/task/task_bloc.dart';
import '../../bloc/task/task_event.dart';
import '../../models/task.dart';
import '../../bloc/task/task_state.dart';
import '../../bloc/offer/offer_list_bloc.dart';
import '../../bloc/offer/offer_list_state.dart';
import '../../bloc/question/question_bloc.dart';
import '../../bloc/question/question_event.dart';
import '../../bloc/question/question_state.dart';
import '../../bloc/offer/offer_list_event.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../profile/public_profile_screen.dart';
import '../../models/user.dart';
import '../../config/theme.dart';
import '../../widgets/dynamic_map.dart';
import '../../bloc/map_settings/map_settings_cubit.dart';
import '../../core/service_locator.dart';
import 'make_offer_screen.dart';
import 'offer_card.dart';
import 'post_review_screen.dart';
import '../wallet/topup_screen.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../services/geocoding_service.dart';
import '../messaging/chat_screen.dart';
import '../../widgets/user_avatar.dart';
import '../map/task_map_screen.dart';
import '../../models/question.dart';
import '../../widgets/badge_widgets.dart';
import '../../widgets/task/dispute_dialog.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/ui_utils.dart';
import '../../utils/auth_gate.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0; // 0 for Offers, 1 for Questions

  late final OfferListBloc _offerListBloc;
  late final QuestionBloc _questionBloc;
  final TextEditingController _questionController = TextEditingController();
  
  // Realtime subscriptions
  StreamSubscription? _offerSubscription;
  StreamSubscription? _questionSubscription;
  
  // Track if user already has an offer on this task
  bool _hasExistingOffer = false;
  bool _checkingOffer = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
        });
      }
    });
    context.read<TaskBloc>().add(TaskLoadById(widget.taskId));
    _offerListBloc = getIt<OfferListBloc>();
    _questionBloc = getIt<QuestionBloc>();
    _offerListBloc.add(LoadOffers(taskId: widget.taskId));
    _questionBloc.add(LoadQuestions(widget.taskId));
    
    // Only do auth-dependent operations if authenticated
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      // Subscribe to realtime updates
      _setupRealtimeSubscriptions();
      
      // Check if user already has an offer on this task
      _checkExistingOffer();
    } else {
      // Guest: skip offer check
      _checkingOffer = false;
    }
  }

  Future<void> _checkExistingOffer() async {
    try {
      final hasOffer = await getIt<ApiService>().hasOfferOnTask(widget.taskId);
      if (mounted) {
        setState(() {
          _hasExistingOffer = hasOffer;
          _checkingOffer = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _checkingOffer = false);
      }
    }
  }

  void _setupRealtimeSubscriptions() {
    final realtimeService = getIt<RealtimeService>();
    
    // Subscribe to task room for updates
    realtimeService.subscribeToTask(widget.taskId);
    
    // Listen for new offers
    _offerSubscription = realtimeService.offerCreated.listen((data) {
      // Reload offers when a new one is created
      _offerListBloc.add(LoadOffers(taskId: widget.taskId));
    });
    
    // Listen for new questions
    _questionSubscription = realtimeService.questionCreated.listen((data) {
      // Reload questions when a new one is created
      _questionBloc.add(LoadQuestions(widget.taskId));
    });
  }

  @override
  void dispose() {
    // Unsubscribe from realtime updates
    final realtimeService = getIt<RealtimeService>();
    realtimeService.unsubscribeFromTask(widget.taskId);
    _offerSubscription?.cancel();
    _questionSubscription?.cancel();
    
    _offerListBloc.close();
    _questionBloc.close();
    _questionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Subtle grey background like home screen
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        actions: const [],
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
         builder: (context, state) {
          if (state.isLoading) {
            return _buildLoadingState();
          }

          if (state.error != null) {
            return Center(child: Text(state.error!));
          }

          if (state.selectedTask == null) {
            return const Center(child: Text('Task not found'));
          }

          final task = state.selectedTask!;

          return MultiBlocProvider(
            providers: [
              BlocProvider.value(value: _offerListBloc),
              BlocProvider.value(value: _questionBloc),
            ],
            child: BlocListener<OfferListBloc, OfferListState>(
              listener: (context, offerState) {
                if (offerState is OfferListFailure) {
                  _showEscrowErrorDialog(context, offerState.message);
                } else if (offerState is OfferListLoaded && offerState.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(offerState.message!),
                    ),
                  );
                }
              },
              child: Scaffold(
              backgroundColor: const Color(0xFFF9FAFB),
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 0), // Adjust padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Details Card
                    Card(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task.taskType == 'project') ...[
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
                              const SizedBox(height: 12),
                            ],
                            // Title
                            Text(
                              task.title,
                              style: GoogleFonts.oswald(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0E1638),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Poster Info
                            InkWell(
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
                                    UserAvatar.fromUser(task.poster!, radius: 20, showBadge: false)
                                  else
                                    UserAvatar(
                                      name: (task.posterName?.isNotEmpty == true) ? task.posterName! : 'User',
                                      profileImage: task.posterImage,
                                      radius: 20,
                                      isVerified: task.posterVerified ?? false,
                                      showBadge: false,
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (task.posterName?.isNotEmpty == true) ? task.posterName! : 'User',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                          Row(
                                            children: [
                                              if ((task.posterRating ?? 0) > 0) ...[
                                                const Icon(Icons.star, size: 22, color: Colors.orange),
                                                const SizedBox(width: 4),
                                                Text(
                                                  task.posterRating!.toStringAsFixed(1),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.orange,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ] else
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.purple.shade50,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'New!',
                                                    style: TextStyle(
                                                      color: Colors.purple.shade700,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              if (task.poster?.badges != null && task.poster!.badges.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                BadgeIconRow(badges: task.poster!.badges, iconSize: 22, spacing: -4),
                                              ],
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 20),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Divider(height: 1),
                            ),

                            // Location
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(LucideIcons.mapPin, color: AppTheme.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Location', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                      Text(
                                        task.locationAddress,
                                        style: const TextStyle(fontSize: 14, color: Color(0xFF0E1638)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TaskMapScreen(
                                          initialTasks: const [], // Let it load all, or pass just this one
                                          initialTask: task,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Map', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Date
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(LucideIcons.calendar, color: AppTheme.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Due Date', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    Text(
                                      _formatTaskDate(task),
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF0E1638)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Posted Time & Budget
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(LucideIcons.clock, color: AppTheme.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Posted', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    Text(
                                      _getTimeAgo(task.createdAt),
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF0E1638)),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Hero(
                                  tag: 'task_price_${task.id}',
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primarySoft,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'BUDGET',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black54,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '\$${UIUtils.formatBudget(task.budget)}',
                                                style: GoogleFonts.oswald(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'USD',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.primary.withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Divider(height: 1),
                            ),

                            // Equipment Specs (if valid)
                            if (task.taskType == 'equipment') ...[
                              _buildEquipmentSpecs(task),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Divider(height: 1),
                              ),
                            ],

                            // Project Specs (if valid)
                            if (task.taskType == 'project') ...[
                              _buildProjectSpecs(task),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Divider(height: 1),
                              ),
                            ],

                            // Description
                            const Text(
                              'Description',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0E1638)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              task.description.trim(),
                              style: const TextStyle(fontSize: 15, color: Color(0xFF4B5563), height: 1.6),
                            ),
                            if (task.photos.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: task.photos.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: GestureDetector(
                                        onTap: () => _showFullscreenImage(context, task.photos[index]),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl: task.photos[index],
                                            width: 140,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              width: 140,
                                              color: Colors.grey[200],
                                              child: const Center(child: CircularProgressIndicator()),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              width: 140,
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.broken_image, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            
                            // Document Attachments
                            if (task.attachments.any((a) => a.type != 'image')) ...[
                              const SizedBox(height: 24),
                              const Text(
                                'Documents (BOQs, Plans, etc)',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0E1638)),
                              ),
                              const SizedBox(height: 12),
                              ...task.attachments.where((a) => a.type != 'image').map((att) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        att.type == 'pdf' ? Icons.picture_as_pdf : Icons.description,
                                        color: Colors.blue.shade700,
                                        size: 24,
                                      ),
                                    ),
                                    title: Text(
                                      att.name ?? 'Attachment',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: const Icon(Icons.download_rounded, color: Colors.grey, size: 20),
                                    onTap: () async {
                                      final uri = Uri.parse(att.url);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ],
                          ],
                        ),
                      ),
                    ),

                   // Offers / Questions Tabs
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                     child: Container(
                       decoration: BoxDecoration(
                         color: AppTheme.neutral100,
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: TabBar(
                         controller: _tabController,
                         indicator: BoxDecoration(
                           color: AppTheme.primary,
                           borderRadius: BorderRadius.circular(12),
                         ),
                         splashBorderRadius: BorderRadius.circular(12),
                         labelColor: Colors.white,
                         unselectedLabelColor: AppTheme.neutral600,
                         labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                         indicatorSize: TabBarIndicatorSize.tab,
                         dividerColor: Colors.transparent,
                         tabs: [
                           Tab(
                             child: BlocBuilder<OfferListBloc, OfferListState>(
                               bloc: _offerListBloc,
                               builder: (context, offerState) {
                                 final count = offerState is OfferListLoaded 
                                     ? offerState.offers.length 
                                     : task.offersCount;
                                 return Text('Bids  $count');
                               },
                             ),
                           ),
                           Tab(
                             child: BlocBuilder<QuestionBloc, QuestionState>(
                               bloc: _questionBloc,
                               builder: (context, questionState) {
                                 final count = questionState is QuestionsLoaded
                                     ? questionState.questions.length
                                     : task.questionsCount;
                                 return Text('Questions  $count');
                               },
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                  
                  // Content area for tabs
                  if (_selectedTab == 1)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: BlocBuilder<QuestionBloc, QuestionState>(
                        bloc: _questionBloc,
                        builder: (context, questionState) {
                          if (questionState is QuestionsLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (questionState is QuestionsLoaded) {
                            if (questionState.questions.isEmpty) {
                              return _buildEmptyQuestions();
                            }
                            return _buildQuestionsList(questionState.questions, task.posterId);
                          }
                          
                          return _buildEmptyQuestions();
                        },
                      ),
                    )
                  else
                    BlocBuilder<OfferListBloc, OfferListState>(
                      bloc: _offerListBloc,
                      builder: (context, offerState) {
                        if (offerState is OfferListLoading) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (offerState is OfferListLoaded) {
                          if (offerState.offers.isEmpty) {
                            return _buildEmptyOffers(context, task.posterId);
                          }
                          return Column(
                            children: [
                              ...offerState.offers.map((offer) => OfferCard(
                                offer: offer,
                                taskOwnerId: task.posterId,
                                task: task,
                              )),

                            ],
                          );
                        } else if (offerState is OfferListFailure) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                  const SizedBox(height: 16),
                                  Text(
                                    offerState.message,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => _offerListBloc.add(LoadOffers(taskId: widget.taskId)),
                                    child: const Text('Try Again'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return _buildEmptyOffers(context, task.posterId);
                      },
                    ),

                    
                  const SizedBox(height: 100), // Extra space for sticky button
                ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
              ),
            ),
            bottomNavigationBar: _buildActionCard(context, task),
          ),
        ),
      );
    },
  ),
);
}

  /// Builds a smart action card that shows different buttons based on:
  /// - Current user role (poster, assigned tasker, or other)
  /// - Task status (open, assigned, completed)
  Widget _buildActionCard(BuildContext context, dynamic task) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String? currentUserId;
        final isAuthenticated = authState is AuthAuthenticated;
        if (isAuthenticated) {
          currentUserId = authState.user.id;
        }

        // Guest users: show a "Sign in to bid" card
        if (!isAuthenticated) {
          return _buildGuestActionCard(context, task);
        }

        final bool isPoster = currentUserId == task.posterId;
        final bool isAssignedTasker = task.assignedTo != null && task.assignedTo == currentUserId;
        final String status = task.status?.toLowerCase() ?? 'open';

        // Determine which card to show
        if (status == 'completed') {
          return _buildCompletedCard(context);
        } else if (status == 'cancelled') {
          return _buildCancelledCard(context);
        } else if (status == 'assigned') {
          // Task is assigned
          if (isAssignedTasker) {
            return _buildMarkCompleteCard(context, task, currentUserId);
          } else if (isPoster) {
            return _buildAssignedStatusCard(context, task, currentUserId);
          }
          return const SizedBox.shrink(); // Other users can't do anything
        } else if (status == 'disputed') {
          return _buildDisputedCard(context, task);
        } else {
          // Task is open - show make offer (unless poster)
          if (isPoster) {
            return _buildPosterStatusCard(context, task);
          }
          return _buildMakeOfferCard(context, task);
        }
      },
    );
  }

  Widget _buildGuestActionCard(BuildContext context, dynamic task) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Budget',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  '\$${task.budget.toStringAsFixed(0)}',
                  style: GoogleFonts.oswald(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => requireAuth(context, 'place a bid on this task'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Place a Bid',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.grey.shade600, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Cancelled',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Text(
                      'This task is no longer active',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSpecs(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hire Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0E1638)),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (task.fuelIncluded != null)
              _SpecPill(
                icon: task.fuelIncluded! ? Icons.local_gas_station : Icons.water_drop_outlined,
                label: 'Hire Type',
                value: task.fuelIncluded! ? 'Wet Rate' : 'Dry Rate',
                color: task.fuelIncluded! ? Colors.orange : Colors.blue,
              ),
            if (task.costingBasis != null)
              _SpecPill(
                icon: _getCostingIcon(task.costingBasis!),
                label: 'Charge Basis',
                value: _getCostingLabel(task.costingBasis!),
                color: Colors.indigo,
              ),
            if (task.hireDurationType != null)
              _SpecPill(
                icon: Icons.timer_outlined,
                label: 'Hire Duration',
                value: _getDurationLabel(task),
                color: Colors.teal,
              ),
            if (task.equipmentUnits != null)
              _SpecPill(
                icon: Icons.construction,
                label: 'Units',
                value: '${task.equipmentUnits} ${task.equipmentUnits == 1 ? "Machine" : "Machines"}',
                color: Colors.grey,
              ),
            if (task.capacityValue != null)
              _SpecPill(
                icon: Icons.straighten,
                label: 'Capacity',
                value: '${task.capacityValue} ${task.capacityUnit ?? ""}',
                color: Colors.deepPurple,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectSpecs(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Specs',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0E1638)),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (task.projectSize != null && task.projectSize!.isNotEmpty)
              _SpecPill(
                icon: Icons.straighten,
                label: 'Project Size',
                value: task.projectSize!,
                color: Colors.teal,
              ),
            if (task.siteReadiness != null && task.siteReadiness!.isNotEmpty)
              _SpecPill(
                icon: Icons.fact_check_outlined,
                label: 'Site Readiness',
                value: task.siteReadiness!,
                color: Colors.indigo,
              ),
            if (task.timelineStart != null)
              _SpecPill(
                icon: Icons.event,
                label: 'Start Date',
                value: DateFormat('d MMM yyyy').format(task.timelineStart!),
                color: Colors.green,
              ),
            if (task.timelineEnd != null)
              _SpecPill(
                icon: Icons.event_available,
                label: 'Target End',
                value: DateFormat('d MMM yyyy').format(task.timelineEnd!),
                color: Colors.blue,
              ),
          ],
        ),
      ],
    );
  }

  IconData _getCostingIcon(String basis) {
    switch (basis) {
      case 'time': return Icons.schedule;
      case 'distance': return Icons.route;
      case 'per_load': return Icons.local_shipping;
      case 'quantity': return Icons.inventory_2_outlined;
      default: return Icons.payments_outlined;
    }
  }

  String _getCostingLabel(String basis) {
    switch (basis) {
      case 'time': return 'By Time';
      case 'distance': return 'By Distance';
      case 'per_load': return 'Per Load';
      case 'quantity': return 'By Quantity';
      default: return basis.toUpperCase();
    }
  }

  String _getDurationLabel(Task task) {
    final type = task.hireDurationType;
    final count = type == 'hourly' ? task.estimatedHours : task.estimatedDuration;
    if (count == null) return type ?? 'N/A';
    
    switch (type) {
      case 'hourly': return '${count.toStringAsFixed(0)} Hours';
      case 'daily': return '${count.toStringAsFixed(0)} Days';
      case 'weekly': return '${count.toStringAsFixed(0)} Weeks';
      case 'monthly': return '${count.toStringAsFixed(0)} Months';
      case 'kilometers': return '${count.toStringAsFixed(0)} KM';
      case 'loads': return '${count.toStringAsFixed(0)} Loads';
      case 'units': return '${count.toStringAsFixed(0)} Units';
      default: return '${count.toStringAsFixed(0)} $type';
    }
  }
  Widget _buildMakeOfferCard(BuildContext context, dynamic task) {
    final bool canMakeOffer = !_hasExistingOffer && !_checkingOffer;
    
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Budget',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  '\$${task.budget.toStringAsFixed(0)}',
                  style: GoogleFonts.oswald(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (_checkingOffer)
            const SizedBox(
              width: 100,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_hasExistingOffer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Offer Sent',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MakeOfferScreen(task: task),
                  ),
                );
                if (result == true) {
                  _offerListBloc.add(LoadOffers(taskId: widget.taskId));
                  // Update the existing offer check
                  setState(() => _hasExistingOffer = true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Place a Bid',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

 
  Widget _buildMarkCompleteCard(BuildContext context, dynamic task, String? currentUserId) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_turned_in, color: AppTheme.success, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Mark Task as Complete',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCompleteConfirmation(context, task),
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _navigateToChat(context, task, currentUserId ?? ''),
              icon: const Icon(Icons.message_outlined),
              label: const Text('Message Poster'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppTheme.navy),
                foregroundColor: AppTheme.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, dynamic task) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'How was the service?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToReview(context, task),
              icon: const Icon(Icons.rate_review),
              label: const Text('Leave a Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.success, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'This task has been completed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

 
  void _showDisputeDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => DisputeDialog(
        taskId: task.id,
        onSubmit: (reason, description) async {
          final apiService = getIt<ApiService>();
          try {
            await apiService.createDispute(
              taskId: task.id,
              reason: reason,
              description: description,
            );
            
            if (context.mounted) {
              Navigator.pop(context); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dispute submitted successfully. Support will contact you.'),
                ),
              );
              // Refresh task
              context.read<TaskBloc>().add(TaskLoadById(task.id));
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to submit dispute: ${e.toString()}'),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildAssignedStatusCard(BuildContext context, dynamic task, String? currentUserId) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.person_pin, color: AppTheme.info, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Assigned',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
                ),
                Text(
                  'Tasker is working on this',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () => _navigateToChat(context, task, currentUserId ?? ''),
            icon: const Icon(Icons.message_outlined),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.info.withOpacity(0.1),
              foregroundColor: AppTheme.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterStatusCard(BuildContext context, dynamic task) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: AppTheme.primary, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Publicly Visible',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navy,
                      ),
                    ),
                    Text(
                      'Awaiting bids from taskers',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCancelConfirmation(context, task),
              icon: const Icon(LucideIcons.trash2, size: 18),
              label: const Text('Cancel Task'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputedCard(BuildContext context, dynamic task) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(top: BorderSide(color: Colors.red.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Under Dispute',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                    const Text(
                      'A support agent is reviewing this case',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => context.push('/profile/disputes'),
                child: const Text('View Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCompleteConfirmation(BuildContext context, dynamic task) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark Task as Complete?'),
        content: const Text(
          'This will notify the poster that the task is done. '
          'Make sure you have completed all the work before proceeding.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Completing task...'),
                    ],
                  ),
                  backgroundColor: AppTheme.info,
                  duration: Duration(seconds: 2),
                ),
              );
              
              // Complete the task
              context.read<TaskBloc>().add(TaskComplete(task.id));
              
              // Wait a moment for the API call to complete
              await Future.delayed(const Duration(milliseconds: 1500));
              
              if (!mounted) return;
              
              // Show success message
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task marked as complete! Please leave a review.'),
                  backgroundColor: AppTheme.success,
                  duration: Duration(seconds: 2),
                ),
              );
              
              // Reload the task to update UI
              context.read<TaskBloc>().add(TaskLoadById(widget.taskId));
              
              // Navigate to review screen for the tasker to review the poster
              // Show the review form after a brief delay
              await Future.delayed(const Duration(milliseconds: 500));
              
              if (!mounted) return;
              
              // Show review form to tasker (to review the poster)
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => PostReviewScreen(
                    task: task,
                    isForced: false, // Tasker can skip if they want
                  ),
                ),
              );
              
              if (result == true && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Review submitted! Thank you.'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _navigateToReview(BuildContext context, dynamic task) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PostReviewScreen(task: task),
      ),
    );
    if (result == true && mounted) {
      // Refresh task details
      context.read<TaskBloc>().add(TaskLoadById(widget.taskId));
    }
  }

  Widget _buildEmptyQuestions() {
    return Column(
      children: [
        // Public warning message
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Color(0xFF1976D2), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'These messages are public. Don\'t share private info. We never ask for payment, send links/QR codes, or request verification in Questions.',
                  style: TextStyle(
                    color: Color(0xFF0D47A1),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),

        _buildQuestionInput(),
      ],
    );
  }

  Widget _buildEmptyOffers(BuildContext context, String posterId) {
    final authState = context.read<AuthBloc>().state;
    final String currentUserId = authState is AuthAuthenticated ? authState.user.id : '';
    final bool isPoster = currentUserId == posterId;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isPoster ? 'Waiting for bids...' : 'No bids yet',
            style: GoogleFonts.oswald(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isPoster
                ? 'Your task is live! Sit back while we find the best professionals for your project.'
                : 'Be the first to place a bid! High-quality early bids have a great chance of being selected.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F7FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_offer_outlined,
              size: 50,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList(List questions, String posterId) {
    return Column(
      children: [
        // Public warning message
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Color(0xFF1976D2), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'These messages are public. Don\'t share private info. We never ask for payment, send links/QR codes, or request verification in Questions.',
                  style: TextStyle(
                    color: Color(0xFF0D47A1),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Question input field
        _buildQuestionInput(),

        const SizedBox(height: 24),

        // Questions list
        const SizedBox(height: 16),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            String? currentUserId;
            if (authState is AuthAuthenticated) {
              currentUserId = authState.user.id;
            }
            return Column(
              children: questions.map((question) => _buildQuestionCard(
                question, 
                currentUserId, 
                posterId,
              )).toList(),
            );
          },
        ),

        const SizedBox(height: 24),


      ],
    );
  }

  Widget _buildQuestionInput() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Ask a question',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                filled: false,
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _sendQuestion(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.grey.shade600,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Ask', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question question, String? currentUserId, String? posterId) {
    final timeAgo = _getTimeAgo(question.timestamp);
    final isPoster = currentUserId != null && currentUserId == posterId;
    final hasAnswer = question.answer != null && question.answer!.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (question.user != null)
                  UserAvatar.fromUser(
                    question.user!,
                    radius: 18,
                    showBadge: false,
                  )
                else
                  UserAvatar(
                    name: question.userName,
                    profileImage: question.userImage,
                    radius: 18,
                    isVerified: question.isVerified,
                    showBadge: false,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              question.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.navy,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (question.user != null && question.user!.badges.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            BadgeIconRow(badges: question.user!.badges, iconSize: 22, spacing: -4),
                          ],
                        ],
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.question,
              style: const TextStyle(
                color: AppTheme.navy,
                height: 1.4,
                fontSize: 14,
              ),
            ),
            
            if (hasAnswer) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.navy.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.reply, size: 16, color: AppTheme.navy),
                        const SizedBox(width: 8),
                        Text(
                          'Poster\'s Reply',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.navy.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.answer!,
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isPoster) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showReplyDialog(question),
                  icon: const Icon(Icons.reply, size: 18),
                  label: const Text('Reply'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(Question question) {
    final TextEditingController replyController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   const Text(
                    'Reply to Question',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: replyController,
                    maxLines: 4,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Type your reply...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: () {
                      if (replyController.text.trim().isNotEmpty) {
                        _questionBloc.add(AnswerQuestion(
                          taskId: widget.taskId,
                          questionId: question.id,
                          answer: replyController.text.trim(),
                        ));
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Send Reply',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _sendQuestion() {
    if (_questionController.text.trim().isEmpty) return;
    
    _questionBloc.add(AskQuestion(
      taskId: widget.taskId,
      question: _questionController.text.trim(),
    ));
    _questionController.clear();
  }

  String _formatTaskDate(dynamic task) {
    // Check for project timeline dates first
    final timelineStart = task.timelineStart as DateTime?;
    final timelineEnd = task.timelineEnd as DateTime?;
    
    if (timelineStart != null && timelineEnd != null) {
      return '${DateFormat('d MMM yyyy').format(timelineStart)} – ${DateFormat('d MMM yyyy').format(timelineEnd)}';
    } else if (timelineStart != null) {
      return 'From ${DateFormat('d MMM yyyy').format(timelineStart)}';
    } else if (timelineEnd != null) {
      return 'By ${DateFormat('d MMM yyyy').format(timelineEnd)}';
    }

    // Check for dateType
    final dateType = task.dateType as String?;
    final deadline = task.deadline as DateTime?;
    final timeOfDay = task.timeOfDay as String?;
    
    String dateStr = '';
    
    if (dateType == 'flexible') {
      dateStr = 'Flexible';
    } else if (dateType == 'on_date' && deadline != null) {
      dateStr = 'On ${_formatDate(deadline)}';
    } else if (dateType == 'before_date' && deadline != null) {
      dateStr = 'Before ${_formatDate(deadline)}';
    } else if (deadline != null) {
      // Fallback if dateType not set but deadline exists
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final taskDate = DateTime(deadline.year, deadline.month, deadline.day);
      
      if (taskDate == today) {
        dateStr = 'Today';
      } else if (taskDate == today.add(const Duration(days: 1))) {
        dateStr = 'Tomorrow';
      } else {
        dateStr = _formatDate(deadline);
      }
    } else {
      dateStr = 'Flexible';
    }

    // Append time of day if it exists and is not 'any' or empty
    if (timeOfDay != null && timeOfDay.isNotEmpty && timeOfDay.toLowerCase() != 'any') {
      final capitalizedTime = timeOfDay[0].toUpperCase() + timeOfDay.substring(1).toLowerCase();
      return '$dateStr ($capitalizedTime)';
    }
    
    return dateStr;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showLocationMap(BuildContext context, dynamic task) async {
    // Check if task has coordinates
    double? lat = task.locationLat;
    double? lng = task.locationLng;
    
    // If no coordinates, try to geocode the address
    if (lat == null || lng == null) {
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      try {
        // Use our GeocodingService instead
        final geocodingService = GeocodingService();
        final results = await geocodingService.searchPlaces(task.locationAddress);
        Navigator.pop(context); // Remove loading indicator
        
        if (results.isNotEmpty) {
          lat = results.first.lat;
          lng = results.first.lng;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find location on map'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      } catch (e) {
        Navigator.pop(context); // Remove loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not geocode address: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final taskLocation = LatLng(lat!, lng!);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.navy),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.locationAddress,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Map
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: DynamicMap(
                  initialCenter: taskLocation,
                  initialZoom: 15,
                  markers: [
                    DynamicMarker(
                      id: 'task_location',
                      point: taskLocation,
                      googleHue: 0.0,
                      width: 100, // Sufficient width for budget badge
                      height: 80, // Sufficient height for badge + icon
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.navy,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '\$${task.budget.toInt()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.location_on,
                            color: AppTheme.navy,
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(color: Colors.white, height: 120, width: double.infinity),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(color: Colors.white, height: 32, width: 250),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), width: 48, height: 48),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(color: Colors.white, height: 16, width: 120),
                          const SizedBox(height: 8),
                          Container(color: Colors.white, height: 14, width: 80),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(color: Colors.white, height: 24, width: 24),
                      const SizedBox(width: 16),
                      Container(color: Colors.white, height: 18, width: 200),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(color: Colors.white, height: 24, width: 24),
                      const SizedBox(width: 16),
                      Container(color: Colors.white, height: 18, width: 150),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(color: Colors.white, height: 20, width: 100),
                  const SizedBox(height: 12),
                  Container(color: Colors.white, height: 14, width: double.infinity),
                  const SizedBox(height: 8),
                  Container(color: Colors.white, height: 14, width: double.infinity),
                  const SizedBox(height: 8),
                  Container(color: Colors.white, height: 14, width: 200),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChat(BuildContext context, dynamic task, String currentUserId) {
    if (task.conversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation not available for this task.'),
          backgroundColor: AppTheme.primary,
        ),
      );
      return;
    }

    final bool isPoster = currentUserId == task.posterId;
    final String otherUserId = isPoster ? (task.assignedTo ?? '') : task.posterId;
    final String otherUserName = isPoster ? (task.assignedToName ?? 'Tasker') : (task.posterName ?? 'Poster');
    final String? otherUserImage = isPoster ? task.assignedToImage : task.posterImage;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: task.conversationId!,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          otherUserImage: otherUserImage,
          conversationTitle: task.title,
          otherUser: isPoster ? (task as Task).assignee : (task as Task).poster,
        ),
      ),
    );
  }

  void _showEscrowErrorDialog(BuildContext context, String message) {
    final bool isInsufficientBalance = message.contains('insufficient wallet balance');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isInsufficientBalance ? 'Insufficient Balance' : 'Acceptance Failed',
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isInsufficientBalance 
            ? 'You do not have enough funds in your wallet to cover the task budget. Please top up to continue.'
            : message,
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          if (isInsufficientBalance)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TopUpScreen()),
                ).then((_) {
                  // Reload offers when returning from top up
                  _offerListBloc.add(LoadOffers(taskId: widget.taskId));
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Top Up Now'),
            ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Task?'),
        content: const Text(
          'Are you sure you want to cancel this task? '
          'All active bidders will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep Task'),
          ),
          ElevatedButton(
            onPressed: () {
              // Close the dialog
              Navigator.pop(dialogContext);
              
              // Dispatch the cancel event
              context.read<TaskBloc>().add(TaskCancel(task.id));
              
              // Navigate to home immediately
              context.go('/');
              
              // Show success message after a short delay (on home screen)
              Future.delayed(const Duration(milliseconds: 500), () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task cancelled successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Task'),
          ),
        ],
      ),
    );
  }
}

class _SpecPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SpecPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



