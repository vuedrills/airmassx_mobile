import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'config/theme.dart';
import 'config/env.dart';
import 'core/service_locator.dart';
import 'core/router.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/welcome_screen.dart';
import 'screens/tasks/browse_tasks_screen.dart';
import 'screens/tasks/my_tasks_screen.dart';
import 'screens/messaging/conversations_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/wallet/wallet_screen.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/auth/auth_state.dart';
import 'bloc/task/task_bloc.dart';
import 'bloc/invoice/invoice_bloc.dart';
import 'bloc/inventory/inventory_bloc.dart';
import 'bloc/profile/profile_bloc.dart';
import 'bloc/profile/profile_event.dart';
import 'bloc/task/task_event.dart';
import 'bloc/task/task_state.dart';
import 'bloc/category/category_bloc.dart';
import 'bloc/category/category_event.dart';
import 'bloc/internet/internet_cubit.dart';
import 'bloc/map_settings/map_settings_cubit.dart';
import 'screens/tasks/post_review_screen.dart';
import 'services/notification_service.dart';
import 'services/realtime_service.dart';
import 'services/ad_service.dart';
import 'services/api_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'models/task.dart' as models;


void main() async {
  // Initialize App Config
  AppConfig.shared.initialize(
    env: kReleaseMode ? AppEnvironment.prod : AppEnvironment.dev
  );

  await SentryFlutter.init(
    (options) {
      options.dsn = AppConfig.shared.sentryDsn;
      options.tracesSampleRate = 1.0; // Captures 100% of transactions for performance monitoring
      options.reportSilentFlutterErrors = true;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('Flutter binding initialized.');
      
      // Initialize Service Locator
      setupServiceLocator();
      debugPrint('Service locator initialized.');
      
      // Initialize Firebase
      debugPrint('Initializing Firebase...');
      try {
        await Firebase.initializeApp();
        debugPrint('Firebase initialized successfully.');
      } catch (e) {
        debugPrint('Firebase initialization failed: $e');
      }
      
      // Initialize Notification Service (FCM)
      debugPrint('Initializing Notification Service...');
      try {
        await getIt<NotificationService>().initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Notification Service initialization timed out.');
            return;
          },
        );
        debugPrint('Notification Service initialized successfully.');
      } catch (e) {
        debugPrint('Failed to initialize notifications: $e');
      }

      // Initialize Google Mobile Ads via AdService
      debugPrint('Initializing AdService...');
      try {
        await getIt<AdService>().initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('AdService initialization timed out.');
            return;
          },
        );
        debugPrint('AdService initialized successfully.');
      } catch (e) {
        debugPrint('AdService initialization failed: $e');
      }

      // Reload auth state and wait for tokens to be ready
      debugPrint('Loading auth state...');
      final authBloc = getIt<AuthBloc>();
      authBloc.add(AuthLoadUser());
      
      // Give it a moment to load tokens from storage before starting UI
      await Future.delayed(const Duration(milliseconds: 100));

      // Load categories early
      debugPrint('Loading categories...');
      getIt<CategoryBloc>().add(const LoadCategories());
      
      debugPrint('App initialized, starting UI...');
      runApp(
        DefaultAssetBundle(
          bundle: SentryAssetBundle(),
          child: const MyApp(),
        ),
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authBloc = getIt<AuthBloc>();
    final appRouter = AppRouter(authBloc);
    
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<TaskBloc>.value(value: getIt<TaskBloc>()),
        BlocProvider<ProfileBloc>.value(value: getIt<ProfileBloc>()),
        BlocProvider<InvoiceBloc>(create: (_) => getIt<InvoiceBloc>()),
        BlocProvider<InventoryBloc>(create: (_) => getIt<InventoryBloc>()),
        BlocProvider<CategoryBloc>.value(value: getIt<CategoryBloc>()),
        BlocProvider<InternetCubit>.value(value: getIt<InternetCubit>()),
        BlocProvider<MapSettingsCubit>.value(value: getIt<MapSettingsCubit>()),
      ],
      child: MaterialApp.router(
        title: 'Airmass Xpress',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),
        routerConfig: appRouter.router,
        builder: (context, child) {
          return child ?? const SizedBox();
        },
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  final String? initialAction;
  const MainScaffold({this.initialIndex = 0, this.initialAction, super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;
  bool _reviewModalShown = false;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<void>? _syncUnreadCountSubscription;
  StreamSubscription<bool>? _connectionStatusSubscription;
  late final RealtimeService _realtimeService;
  
  // Unread counts for badge
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _realtimeService = getIt<RealtimeService>();
    // Load initial data for ribbon and review modal
    final taskBloc = context.read<TaskBloc>();
    taskBloc.add(const TaskLoadActive());
    taskBloc.add(const TaskLoadPendingReviews());
    
    // Listen for realtime notifications
    _setupRealtimeNotificationListener();
    
    // Load initial unread count
    _loadUnreadCount();

    // Handle deep link actions
    if (widget.initialAction == 'pro_registration') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.push('/profile/pro-registration');
      });
    }
  }
  
  Future<void> _loadUnreadCount() async {
    try {
      final apiService = getIt<ApiService>();
      final messageCount = await apiService.getUnreadMessageCount();
      final notificationCount = await apiService.getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          _unreadCount = messageCount + notificationCount;
        });
      }
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _messageSubscription?.cancel();
    _syncUnreadCountSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeNotificationListener() {
    _notificationSubscription = _realtimeService.notifications.listen((data) {
      if (!mounted) return;
      _loadUnreadCount();
      
      final type = data['type'] as String?;
      final title = data['title'] as String? ?? 'Notification';
      final message = data['message'] as String? ?? '';
      
      debugPrint('MainScaffold: Received realtime notification type: $type');
      
      // Refresh unread count from server for accuracy
      _loadUnreadCount();
      
      switch (type) {
        case 'new_offer':
          // Poster received a new offer - show snackbar and refresh my tasks
          _showNotificationSnackbar(title, message, Icons.local_offer, AppTheme.info);
          context.read<TaskBloc>().add(const TaskLoadMyTasks());
          break;
          
        case 'offer_accepted':
          // Tasker's offer was accepted - refresh active tasks (shows ribbon)
          _showNotificationSnackbar(title, message, Icons.check_circle, AppTheme.success);
          context.read<TaskBloc>().add(const TaskLoadActive());
          break;
          
        case 'task_completed':
          // Task was completed by tasker - poster should see review prompt
          _showNotificationSnackbar(title, message, Icons.done_all, AppTheme.success);
          // Refresh pending reviews to trigger review modal for poster
          context.read<TaskBloc>().add(const TaskLoadPendingReviews());
          // Also refresh active tasks (removes from ribbon)
          context.read<TaskBloc>().add(const TaskLoadActive());
          break;
          
        case 'review_received':
          // Someone reviewed the user
          _showNotificationSnackbar(title, message, Icons.star, Colors.amber);
          break;
          
        default:
          // For any other notification, just show a snackbar
          if (message.isNotEmpty) {
            _showNotificationSnackbar(title, message, Icons.notifications, AppTheme.navy);
          }
      }
    });
    
    // Listen for new messages to increment unread count
    _messageSubscription = _realtimeService.messageReceived.listen((data) {
      _loadUnreadCount();
    });

    // Listen for manual sync triggers (e.g. from ChatScreen)
    _syncUnreadCountSubscription = _realtimeService.syncUnreadCount.listen((_) {
      _loadUnreadCount();
    });

    // Connection status listener commented out to remove intrusive snackbars as requested
    /*
    _connectionStatusSubscription = _realtimeService.connectionStatus.listen((isConnected) {
      if (!mounted) return;
      if (isConnected) {
        _showNotificationSnackbar('Live Updates', 'Connected to Realtime Server', Icons.wifi, AppTheme.success);
      } else {
        _showNotificationSnackbar('Offline', 'Disconnected from Realtime Server', Icons.wifi_off, AppTheme.error);
      }
    });
    */
  }

  void _showNotificationSnackbar(String title, String message, IconData icon, Color color) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showForcedReviewModal(BuildContext context, List<models.Task> pendingTasks) {
    if (_reviewModalShown || pendingTasks.isEmpty) return;
    
    _reviewModalShown = true;
    
    // Use a small delay to ensure the scaffold is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: true, // Allow dismissal if stuck
        builder: (context) => Dialog.fullscreen(
          child: PostReviewScreen(
            task: pendingTasks.first,
            isForced: true,
            onReviewSubmitted: (success) {
              if (success) {
                // Show snackbar on the context that remains (the one above the dialog)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Review submitted! Thank you.'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ),
      ).then((_) {
        _reviewModalShown = false;
        // Refresh pending reviews in case there are more
        context.read<TaskBloc>().add(const TaskLoadPendingReviews());
      });
    });
  }

  final List<Widget> _screens = [
    const HomeTabNavigator(),
    const WalletScreen(),
    const MyTasksScreen(),
    const ConversationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TaskBloc, TaskState>(
          listenWhen: (previous, current) => previous.pendingReviews != current.pendingReviews,
          listener: (context, state) {
            if (state.pendingReviews.isNotEmpty && context.read<AuthBloc>().state is AuthAuthenticated) {
              _showForcedReviewModal(context, state.pendingReviews);
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              // If we are showing a modal, it will be dismissed by the router redirect
              // but we can also handle it here if needed.
              _reviewModalShown = false;
            }
          },
        ),
      ],
      child: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          return Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.neutral200.withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() => _currentIndex = index);
                  // Reset unread count when opening Messages tab
                  if (index == 3 && _unreadCount > 0) {
                    setState(() => _unreadCount = 0);
                  }
                },

                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: AppTheme.primary,
                unselectedItemColor: AppTheme.neutral700,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                showUnselectedLabels: true,
                iconSize: 22,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(LucideIcons.home),
                    label: 'Home',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(LucideIcons.wallet),
                    label: 'Wallet',
                  ),

                  const BottomNavigationBarItem(
                    icon: Icon(LucideIcons.clipboardList),
                    label: 'My Tasks',
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                      isLabelVisible: _unreadCount > 0,
                      label: Text(
                        _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: AppTheme.primary,
                      child: const Icon(LucideIcons.messageSquare),
                    ),
                    label: 'Messages',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(LucideIcons.user),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Nested navigator for the Home tab to switch between Welcome hub and Browse Jobs
class HomeTabNavigator extends StatefulWidget {
  const HomeTabNavigator({super.key});

  @override
  State<HomeTabNavigator> createState() => _HomeTabNavigatorState();
}

class _HomeTabNavigatorState extends State<HomeTabNavigator> {
  bool _showBrowseJobs = false;

  void _toggleView() {
    setState(() {
      _showBrowseJobs = !_showBrowseJobs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showBrowseJobs 
        ? HomeScreen(onBackPressed: _toggleView) 
        : WelcomeScreen(onBrowseJobsPressed: _toggleView);
  }
}

