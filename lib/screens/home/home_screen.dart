import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/task/task_bloc.dart';
import '../../bloc/task/task_event.dart';
import '../../bloc/task/task_state.dart';
import '../../bloc/browse/browse_bloc.dart';
import '../../bloc/browse/browse_event.dart';
import '../../bloc/browse/browse_state.dart';
import '../../bloc/search/search_bloc.dart';
import '../../bloc/filter/filter_bloc.dart';
import '../../bloc/filter/filter_event.dart';
import '../../bloc/filter/filter_state.dart';
import '../../models/task.dart';
import '../../models/filter_criteria.dart';
import '../../widgets/task/task_card.dart';
import '../../config/theme.dart';
import '../../core/service_locator.dart';
import '../../widgets/category_chips.dart';
import '../../models/ad.dart';
import '../../widgets/ad_card.dart';
import '../../widgets/home/feature_carousel.dart';
import '../../widgets/active_filters_list.dart';
import '../browse/search_modal.dart';
import '../browse/filter_bottom_sheet.dart';
import '../browse/sort_bottom_sheet.dart';
import '../browse/category_grid_view.dart';
import '../map/task_map_screen.dart';
import '../tasks/post_review_screen.dart';
import '../messaging/chat_screen.dart';
import '../../services/realtime_service.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  const HomeScreen({this.onBackPressed, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late BrowseBloc _browseBloc;
  late SearchBloc _searchBloc;
  late FilterBloc _filterBloc;
  late TabController _tabController;
  StreamSubscription? _taskCreatedSubscription;
  int _currentAdIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _browseBloc = getIt<BrowseBloc>();
    _searchBloc = getIt<SearchBloc>();
    _filterBloc = getIt<FilterBloc>();
    _tabController = TabController(length: 4, vsync: this);
    
    _tabController.addListener(_onTabChanged);

    // Initial load
    _fetchTasksForCurrentTab();
    
    // Original Home logic for active tasks and reviews
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskBloc>().add(const TaskLoadActive());
      context.read<TaskBloc>().add(const TaskLoadPendingReviews());
    });
    
    // Subscribe to real-time task creation events
    _setupRealtimeSubscription();
  }
  
  void _setupRealtimeSubscription() {
    final realtimeService = getIt<RealtimeService>();
    
    // Subscribe to browse_tasks room for new task notifications
    realtimeService.subscribeToBrowseTasks();
    
    // Listen for new tasks created by other users
    _taskCreatedSubscription = realtimeService.taskCreated.listen((data) {
      debugPrint('HomeScreen: New task created, refreshing list');
      _fetchTasksForCurrentTab();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _fetchTasksForCurrentTab();
    }
  }

  void _fetchTasksForCurrentTab() {
    switch (_tabController.index) {
      case 0: // Artisanal
        _browseBloc.add(const LoadBrowseTasksWithFilter(taskType: 'service', tier: 'artisanal'));
        break;
      case 1: // Professional
        _browseBloc.add(const LoadBrowseTasksWithFilter(taskType: 'service', tier: 'professional'));
        break;
      case 2: // Equipment
        _browseBloc.add(const LoadBrowseTasksWithFilter(taskType: 'equipment', tier: 'equipment'));
        break;
      case 3: // Projects
        _browseBloc.add(const LoadBrowseTasksWithFilter(taskType: 'project', tier: 'project'));
        break;
    }
  }

  @override
  void dispose() {
    // Clean up realtime subscription
    _taskCreatedSubscription?.cancel();
    
    // Note: If these are singletons from getIt, we should be careful about closing them here
    // unless this is the only place they are used. In this case, BrowseTasksScreen is gone.
    _browseBloc.close();
    _searchBloc.close();
    _filterBloc.close();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _browseBloc),
        BlocProvider.value(value: _searchBloc),
        BlocProvider.value(value: _filterBloc),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: RefreshIndicator(
          onRefresh: () async {
            _fetchTasksForCurrentTab();
            context.read<TaskBloc>().add(const TaskLoadActive());
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppTheme.navy,
          child: CustomScrollView(
            slivers: [
              // Row 1 & 2: Search and Tabs (Sticky)
              _buildStickyHeader(context),

              // Active Task Ribbon
              BlocBuilder<TaskBloc, TaskState>(
                builder: (context, state) {
                  if (state.activeTasks.isNotEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildActiveTaskRibbon(state.activeTasks.first),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),

              // Row 3: Category Chips
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 12.0, bottom: 4.0),
                  child: CategoryChips(),
                ),
              ),

              // Task List
              BlocBuilder<BrowseBloc, BrowseState>(
                builder: (context, state) {
                  if (state is BrowseLoading) {
                    return SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildLoadingCard(),
                          childCount: 3,
                        ),
                      ),
                    );
                  }

                  if (state is BrowseLoaded) {
                    if (state.tasks.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // Item 0 is always the Feature Carousel
                            if (index == 0) {
                              return FeatureCarousel(ads: state.ads);
                            }

                            // Calculate index relative to content (skipping Feature Carousel)
                            final int contentIndex = index - 1;
                            
                            final bool hasAds = state.ads.isNotEmpty;
                            final int adPosition = 4; // After 4 tasks

                            if (hasAds) {
                              // Ad should appear at adPosition or at end of list if shorter
                              final int effectiveAdIndex = state.tasks.length < adPosition 
                                  ? state.tasks.length 
                                  : adPosition;

                              if (contentIndex == effectiveAdIndex) {
                                return _buildAdCarousel(state.ads);
                              }
                              
                              // Map to task list
                              final int taskIndex = contentIndex > effectiveAdIndex 
                                  ? contentIndex - 1 
                                  : contentIndex;

                              if (taskIndex < state.tasks.length) {
                                return TaskCard(task: state.tasks[taskIndex]);
                              }
                            } else {
                              // No ads, simple mapping
                              if (contentIndex < state.tasks.length) {
                                return TaskCard(task: state.tasks[contentIndex]);
                              }
                            }
                            return null;
                          },
                          childCount: state.tasks.length + 1 + (state.ads.isNotEmpty ? 1 : 0),
                        ),
                      ),
                    );
                  }

                  if (state is BrowseError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(state.message)),
                    );
                  }

                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
              
              // Bottom padding for FAB
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'home_post_task_fab',
          onPressed: () => _showCreateOptions(context),
          backgroundColor: AppTheme.primary,
          elevation: 6,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
        bottomNavigationBar: const BannerAdWidget(),
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();
    
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: true,
      leading: (canPop || widget.onBackPressed != null)
          ? BackButton(
              color: AppTheme.primary,
              onPressed: widget.onBackPressed,
            )
          : null,
      toolbarHeight: 50,
      title: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Row(
          children: [
            const Spacer(),
            // Map icon
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TaskMapScreen(),
                  ),
                );
              },
              child: const Icon(Icons.location_on_outlined, size: 24, color: AppTheme.neutral500),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(42),
        child: TabBar(
          controller: _tabController,
          isScrollable: false,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppTheme.navy,
          unselectedLabelColor: AppTheme.neutral400,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.1),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          labelPadding: EdgeInsets.zero,
          tabs: const [
            Tab(text: 'Trades', height: 38),
            Tab(text: 'Professional', height: 38),
            Tab(text: 'Equipment', height: 38),
            Tab(text: 'Contractors', height: 38),
          ],
        ),
      ),
    );
  }


  Widget _buildActiveTaskRibbon(Task task) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(color: AppTheme.navy),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.engineering, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ACTIVE TASK', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                _navigateToChat(context, task, authState.user.id);
              }
            },
            icon: const Icon(Icons.message_outlined, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _showFinishTaskConfirmation(task),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('FINISH', style: TextStyle(color: AppTheme.navy, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFinishTaskConfirmation(Task task) {
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
              
              // Complete the task
              context.read<TaskBloc>().add(TaskComplete(task.id));
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task marked as complete! Please leave a review.'),
                  backgroundColor: AppTheme.success,
                  duration: Duration(seconds: 2),
                ),
              );
              
              // Wait a moment for the API call
              await Future.delayed(const Duration(milliseconds: 1000));
              
              if (!mounted) return;
              
              // Show review form to tasker
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => PostReviewScreen(
                    task: task,
                    isForced: false,
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
              
              // Refresh active tasks to remove ribbon
              if (mounted) {
                context.read<TaskBloc>().add(const TaskLoadActive());
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

  Widget _buildLoadingCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge placeholder at top right
            Align(
              alignment: Alignment.topRight,
              child: Container(width: 60, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 12),
            // Avatar and name row
            Row(
              children: [
                Container(width: 36, height: 36, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 100, height: 12, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(width: 60, height: 10, color: Colors.white),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Title
            Container(width: double.infinity, height: 16, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: 200, height: 16, color: Colors.white),
            const SizedBox(height: 12),
            // Description
            Container(width: double.infinity, height: 12, color: Colors.white),
            const SizedBox(height: 6),
            Container(width: 150, height: 12, color: Colors.white),
            const SizedBox(height: 16),
            // Bottom row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 60, height: 24, color: Colors.white),
                Container(width: 80, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.work_outline_rounded,
              size: 64,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No tasks available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Be the first to post a task or try adjusting your filters to find more opportunities.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              _browseBloc.add(const LoadBrowseTasksWithFilter(taskType: 'service'));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.navy,
              side: const BorderSide(color: AppTheme.navy),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Removed redundant _showReviewPrompt (handled by MainScaffold)

  void _navigateToChat(BuildContext context, Task task, String currentUserId) {
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
        ),
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'What do you need?',
              style: GoogleFonts.oswald(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the type of service you are looking for',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _buildCreateOption(
              context,
              title: 'On-demand Services',
              subtitle: 'Hire skilled professionals for tasks like plumbing, cleaning, or repairs',
              icon: Icons.handyman_outlined,
              onTap: () {
                Navigator.pop(context);
                context.push('/create-task');
              },
            ),
            const SizedBox(height: 16),
            _buildCreateOption(
              context,
              title: 'Equipment Hires',
              subtitle: 'Rent heavy machinery and tools for construction or industrial projects',
              icon: Icons.construction_outlined,
              onTap: () {
                Navigator.pop(context);
                context.push('/create-equipment-request');
              },
            ),
            const SizedBox(height: 16),
            _buildCreateOption(
              context,
              title: 'Contractors-Projects',
              subtitle: 'For complex projects with defined size, scope, and requirements',
              icon: Icons.apartment_outlined,
              onTap: () {
                Navigator.pop(context);
                context.push('/create-project');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCarousel(List<Ad> ads) {
    if (ads.isEmpty) return const SizedBox.shrink();

    // If only one ad, just show it
    if (ads.length == 1) {
      return SizedBox(
        height: 160,
        child: AdCard(ad: ads.first),
      );
    }

    return SizedBox(
      height: 160, // Matches TaskCard height
      child: Stack(
        children: [
          PageView.builder(
            controller: PageController(viewportFraction: 0.96),
            onPageChanged: (index) {
              setState(() {
                _currentAdIndex = index;
              });
            },
            itemCount: ads.length,
            itemBuilder: (context, index) {
              return AdCard(ad: ads[index]);
            },
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(ads.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentAdIndex == index ? 16 : 6,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: _currentAdIndex == index 
                        ? AppTheme.primary 
                        : AppTheme.neutral300,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}


