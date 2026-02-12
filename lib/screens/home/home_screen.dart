import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
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
  late ScrollController _scrollController;
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
    _scrollController = ScrollController();
    
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    // Initial load from preferences
    _loadStateFromPrefs();
    
    // Original Home logic for active tasks and reviews
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskBloc>().add(const TaskLoadActive());
      context.read<TaskBloc>().add(const TaskLoadPendingReviews());
    });
    
    // Subscribe to real-time task creation events
    _setupRealtimeSubscription();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      _browseBloc.add(LoadMoreTasks());
    }
  }

  Future<void> _loadStateFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTab = prefs.getInt('home_tab_index') ?? 0;
    final savedCategory = prefs.getString('home_selected_category_id');

    if (mounted) {
      if (savedTab >= 0 && savedTab < _tabController.length) {
        _tabController.index = savedTab;
        _lastFetchedIndex = savedTab;
      }
      
      // Perform initial fetch
      _fetchTasksForCurrentTab(initialCategoryId: savedCategory);
    }
  }

  Future<void> _saveTabToPrefs(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('home_tab_index', index);
  }

  Future<void> _saveCategoryToPrefs(String? categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    if (categoryId != null) {
      await prefs.setString('home_selected_category_id', categoryId);
    } else {
      await prefs.remove('home_selected_category_id');
    }
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

  int _lastFetchedIndex = -1;

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _saveTabToPrefs(_tabController.index);
    }

    // Only fetch if index changed or current list is empty
    bool isEmpty = false;
    final state = _browseBloc.state;
    if (state is BrowseLoaded && state.tasks.isEmpty) {
      isEmpty = true;
    }

    if (_tabController.index == _lastFetchedIndex && !isEmpty) return;
    
    _lastFetchedIndex = _tabController.index;
    _fetchTasksForCurrentTab();
  }

  void _fetchTasksForCurrentTab({String? initialCategoryId}) {
    String? taskType;
    String? tier;

    switch (_tabController.index) {
      case 0: // Trades
        taskType = 'service';
        tier = 'artisanal';
        break;
      case 1: // Professional
        taskType = 'service';
        tier = 'professional';
        break;
      case 2: // Equipment
        taskType = 'equipment';
        tier = 'equipment';
        break;
      case 3: // Contractors
        taskType = 'project';
        tier = 'project';
        break;
    }

    if (taskType != null) {
      _browseBloc.add(LoadBrowseTasksWithFilter(
        taskType: taskType, 
        tier: tier,
      ));
      
      // If we have a saved category, apply it after the categories are loaded
      if (initialCategoryId != null && initialCategoryId != 'all') {
        // We need to wait for BrowseLoaded state to have the categories
        // or just fire it and let BrowseBloc handle it if possible.
        // Actually SelectCategory requires BrowseLoaded.
        // So we'll fire it after a small delay or better, listen to the state.
        _applyInitialCategory(initialCategoryId);
      }
    }
  }

  void _applyInitialCategory(String categoryId) {
    StreamSubscription? sub;
    sub = _browseBloc.stream.listen((state) {
      if (state is BrowseLoaded) {
        _browseBloc.add(SelectCategory(categoryId));
        sub?.cancel();
      }
    });
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
    _scrollController.dispose();
    super.dispose();
  }

  BrowseLoaded? _lastLoadedState;

  Widget _buildHomeContent(BuildContext context) {
    return BlocListener<BrowseBloc, BrowseState>(
      listener: (context, state) {
        if (state is BrowseLoaded) {
          _saveCategoryToPrefs(state.selectedCategoryId);
          setState(() {
            _lastLoadedState = state;
          });
        }
      },
      child: RefreshIndicator(
        onRefresh: () async {
          final state = _browseBloc.state;
          String? currentCat;
          if (state is BrowseLoaded) {
            currentCat = state.selectedCategoryId;
          }
          
          _fetchTasksForCurrentTab(initialCategoryId: currentCat);
          context.read<TaskBloc>().add(const TaskLoadActive());
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AppTheme.navy,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Row 1 & 2: Search and Tabs (Sticky)
            _buildStickyHeader(context),

            // Active Task Ribbon
            BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state.activeTasks.isNotEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildActiveTaskRibbon(state.activeTasks.first)
                        .animate()
                        .fadeIn()
                        .slideY(begin: -0.5, end: 0, duration: 500.ms, curve: Curves.easeOutCirc),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),

            // Row 3: Category Chips
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.only(top: 12.0, bottom: 4.0),
                child: CategoryChips(),
              ),
            ),

            // Feature Carousel & Task List / Empty State
            BlocBuilder<BrowseBloc, BrowseState>(
              builder: (context, state) {
                // Update last loaded state for stability
                if (state is BrowseLoaded) {
                  _lastLoadedState = state;
                }

                // Determine if we should show the carousel
                // Use cached ads and current tab index for immediate, non-flickering updates
                Widget? carouselSliver;
                final displayAds = (state is BrowseLoaded) ? state.ads : _lastLoadedState?.ads;
                
                if (displayAds != null) {
                  carouselSliver = SliverToBoxAdapter(
                    child: FeatureCarousel(
                      ads: displayAds,
                      tabIndex: _tabController.index,
                    ),
                  );
                } else if (state is BrowseLoading || state is BrowseInitial) {
                  // Only show placeholder if we have NO cached data at all (first load)
                  carouselSliver = SliverToBoxAdapter(
                    child: Container(
                      height: 124,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }

                // Determine the task list or loading/error sliver
                Widget contentSliver;
                if (state is BrowseLoading || state is BrowseInitial) {
                  contentSliver = SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildLoadingCard().animate().fadeIn(delay: 200.ms),
                        childCount: 3,
                      ),
                    ),
                  );
                } else if (state is BrowseLoaded) {
                  if (state.tasks.isEmpty) {
                    contentSliver = SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    );
                  } else {
                    contentSliver = SliverPadding(
                      padding: const EdgeInsets.only(bottom: 12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final int taskCount = state.tasks.length;
                            final bool hasInternalAds = state.ads.isNotEmpty;
                            // Internal Ad position (from Admin)
                            final int internalAdPosition = state.adsFrequency;

                            // Handle Internal Platform Ad
                            if (hasInternalAds && index == internalAdPosition && taskCount >= internalAdPosition) {
                              return _AdCarouselItem(ads: state.ads);
                            }

                            // Adjust index for internal ad
                            int adjustedIndex = (hasInternalAds && index > internalAdPosition) ? index - 1 : index;

                            // Handle AdMob Ad every 15 tasks
                            // Logic: 15 tasks -> 1 Ad -> 15 tasks -> 1 Ad
                            // Block size = 16 (15 tasks + 1 ad)
                            // Ad slots at adjustedIndex: 15, 31, 47...
                            // (adjustedIndex + 1) % 16 == 0
                            
                            // Check if this adjusted slot is effectively an AdMob slot
                            // We need to map the list index to "content index vs ad index"
                            // But wait, the list index is linear.
                            // Let's count items:
                            // Items: T0..T14 (15 items) -> AdMob1 -> T15..T29 -> AdMob2
                            // Indices: 0..14 -> 15 -> 16..30 -> 31
                            
                            // We need to account for the internal ad shift too.
                            // Let's simplify: 
                            // 1. Check if it's the internal ad slot first (done above).
                            // 2. If not, it's either a task or an AdMob ad.
                            // 3. Let's look at `adjustedIndex`. This is the index in the stream of (Tasks + AdMobAds).
                            //    We want an AdMob ad at indices 15, 31, 47... of this stream.
                            
                            if ((adjustedIndex + 1) % 16 == 0) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: BannerAdWidget(),
                              );
                            }

                            // It's a task.
                            // Map adjustedIndex to taskIndex.
                            // Blocks of 16 contain 15 tasks.
                            // taskIndex = (adjustedIndex / 16) * 15 + (adjustedIndex % 16)
                            // But since the last item in block (15) is ad, we only get 0..14 per block.
                            
                            final int blockIndex = adjustedIndex ~/ 16;
                            final int indexInBlock = adjustedIndex % 16;
                            final int taskIndex = (blockIndex * 15) + indexInBlock;

                            if (taskIndex < taskCount) {
                              return TaskCard(task: state.tasks[taskIndex])
                                  .animate(delay: (100 * (index % 5)).ms)
                                  .fadeIn(duration: 400.ms)
                                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
                            }
                            return null;
                          },
                          // Calculate child count:
                          // Total Tasks = T
                          // Internal Ad = 1 (if T >= freq)
                          // AdMob Ads = floor(T / 15)
                          // Total = T + 1 + floor(T / 15)
                          childCount: state.tasks.length 
                              + (state.ads.isNotEmpty && state.tasks.length >= state.adsFrequency ? 1 : 0)
                              + (state.tasks.length ~/ 15),
                        ),
                      ),
                    );
                  }
                } else if (state is BrowseError) {
                  contentSliver = SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red)
                              .animate()
                              .shake(duration: 500.ms),
                          const SizedBox(height: 16),
                          Text(state.message),
                        ],
                      ).animate().fadeIn(),
                    ),
                  );
                } else {
                  contentSliver = const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                return SliverMainAxisGroup(
                  slivers: [
                    if (carouselSliver != null) carouselSliver,
                    contentSliver,
                  ],
                );
              },
            ),
            
            // Bottom padding for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
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
        body: _buildHomeContent(context),
        floatingActionButton: FloatingActionButton(
          heroTag: 'home_post_task_fab',
          onPressed: () => _showCreateOptions(context),
          backgroundColor: AppTheme.primary,
          elevation: 6,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 1500.ms, curve: Curves.easeInOut),
        // Removed fixed bottomNavigationBar
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();
    
    return SliverAppBar(
      pinned: true,
      floating: false,
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
      /*
      // Premium Segmented Tabs (Commented out for later)
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6), // Very light grey surface
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: AppTheme.navy,
            unselectedLabelColor: AppTheme.neutral500,
            labelStyle: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.nunitoSans(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Trades', height: 40),
              Tab(text: 'Pro', height: 40),
              Tab(text: 'Equipment', height: 40),
              Tab(text: 'Projects', height: 40),
            ],
          ),
        ),
      ),
      */
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
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, letterSpacing: 0.1),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
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
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showCreateOptions(context),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Post a Task'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              final state = _browseBloc.state;
              String? currentCategoryId;
              if (state is BrowseLoaded) {
                currentCategoryId = state.selectedCategoryId;
              }
              _fetchTasksForCurrentTab(initialCategoryId: currentCategoryId);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.navy,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
}

class _AdCarouselItem extends StatefulWidget {
  final List<Ad> ads;
  const _AdCarouselItem({required this.ads});

  @override
  State<_AdCarouselItem> createState() => _AdCarouselItemState();
}

class _AdCarouselItemState extends State<_AdCarouselItem> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.96);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ads.isEmpty) return const SizedBox.shrink();

    if (widget.ads.length == 1) {
      return Container(
        height: 160,
        margin: const EdgeInsets.only(bottom: 12),
        child: AdCard(ad: widget.ads.first),
      );
    }

    return Container(
      height: 160,
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.ads.length,
            itemBuilder: (context, index) {
              return AdCard(ad: widget.ads[index]);
            },
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.ads.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentIndex == index ? 16 : 6,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: _currentIndex == index 
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


