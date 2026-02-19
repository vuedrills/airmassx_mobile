import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/task/task_bloc.dart';
import '../bloc/task/task_state.dart';
import '../models/task.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/personal_info_screen.dart';
import '../screens/profile/work_info_screen.dart';
import '../screens/profile/payment_settings_screen.dart';
import '../screens/profile/payment_history_screen.dart';
import '../screens/profile/notifications_settings_screen.dart';
import '../screens/profile/help_support_screen.dart';
import '../screens/profile/professional_onboarding_screen.dart';
import '../screens/pro_registration/pro_registration_screen.dart';
import '../screens/profile/pro_profile_management_screen.dart';
import '../screens/inventory/inventory_management_screen.dart';
import '../screens/inventory/add_inventory_item_screen.dart';
import '../models/equipment.dart';
import '../screens/tasks/task_detail_screen.dart';
import '../screens/tasks/create_task_screen.dart';
import '../screens/equipment/post_equipment_request_screen.dart';
import '../screens/projects/post_project_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/disputes/dispute_list_screen.dart';
import '../screens/disputes/dispute_detail_screen.dart';
import '../screens/tasks/make_offer_screen.dart';
import '../screens/home/welcome_screen.dart';
import '../screens/home/home_screen.dart';
import '../main.dart';

/// App router configuration using go_router
/// Implements declarative routing with auth state-based redirects
class AppRouter {
  final AuthBloc authBloc;
  final bool isFirstLaunch;

  AppRouter(this.authBloc, {this.isFirstLaunch = false});

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authBloc.state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isOnboarding = state.matchedLocation.startsWith('/onboarding') ||
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signup') ||
          state.matchedLocation.startsWith('/forgot-password') ||
          state.matchedLocation.startsWith('/reset-password') ||
          state.matchedLocation == '/';

      // If user is authenticated and trying to access auth/onboarding screens
      if (isAuthenticated && isOnboarding) {
        return '/home';
      }

      // If user is not authenticated and trying to access protected screens
      if (!isAuthenticated && !isOnboarding) {
        return isFirstLaunch ? '/signup' : '/login';
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          final accountType = state.uri.queryParameters['type'];
          return RegisterScreen(accountType: accountType);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final initialIndex = int.tryParse(tabStr ?? '0') ?? 0;
          final action = state.uri.queryParameters['action'];
          return MainScaffold(initialIndex: initialIndex, initialAction: action);
        },
      ),
      GoRoute(
        path: '/browse-jobs',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/create-task',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialTitle = extra?['title'] as String?;
          final task = extra?['task'] as Task?;
          return CreateTaskScreen(initialTitle: initialTitle, task: task);
        },
      ),
      GoRoute(
        path: '/create-equipment-request',
        builder: (context, state) => const PostEquipmentRequestScreen(),
      ),
      GoRoute(
        path: '/create-project',
        builder: (context, state) => const PostProjectScreen(),
      ),
      GoRoute(
        path: '/tasks/:id',
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return TaskDetailScreen(taskId: taskId);
        },
        routes: [
          GoRoute(
            path: 'make-offer',
            builder: (context, state) {
              final task = state.extra as Task?;
              if (task != null) {
                return MakeOfferScreen(task: task);
              }
              // Fallback if task is not passed as extra
              final taskId = state.pathParameters['id']!;
              return BlocBuilder<TaskBloc, TaskState>(
                builder: (context, taskState) {
                  final t = taskState.selectedTask;
                  if (t != null && t.id == taskId) {
                    return MakeOfferScreen(task: t);
                  }
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                },
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/projects/:id',
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return TaskDetailScreen(taskId: taskId);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'onboarding',
            builder: (context, state) => const ProfessionalOnboardingScreen(),
          ),
          GoRoute(
            path: 'pro-registration',
            builder: (context, state) => const ProRegistrationScreen(),
          ),
          GoRoute(
            path: 'personal-info',
            builder: (context, state) => const PersonalInfoScreen(),
          ),
          GoRoute(
            path: 'work',
            builder: (context, state) => const WorkInfoScreen(),
          ),
          GoRoute(
            path: 'payment-settings',
            builder: (context, state) => const PaymentSettingsScreen(),
          ),
          GoRoute(
            path: 'payment-history',
            builder: (context, state) => const PaymentHistoryScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsSettingsScreen(),
          ),
          GoRoute(
            path: 'pro-profile',
            builder: (context, state) => const ProProfileManagementScreen(),
          ),
          GoRoute(
            path: 'help',
            builder: (context, state) => const HelpSupportScreen(),
          ),
          GoRoute(
            path: 'inventory',
            builder: (context, state) => const InventoryManagementScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddInventoryItemScreen(),
              ),
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final item = state.extra as Equipment;
                  return AddInventoryItemScreen(editingItem: item);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'disputes',
            builder: (context, state) => DisputeListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return DisputeDetailScreen(disputeId: id);
                },
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}

/// Helper class to refresh GoRouter when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    stream.listen((_) => notifyListeners());
  }
}
