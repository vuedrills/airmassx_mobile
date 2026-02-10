import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../services/notification_service.dart';
import '../../core/service_locator.dart';
import '../profile/profile_bloc.dart';
import '../profile/profile_event.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../config/env.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService = getIt<ApiService>();
  final RealtimeService _realtimeService = getIt<RealtimeService>();

  AuthBloc() : super(AuthInitial()) {
    on<AuthLoadUser>(_onLoadUser);
    on<AuthLogin>(_onLogin);
    on<AuthRegister>(_onRegister);
    on<AuthLogout>(_onLogout);
    on<AuthGoogleLogin>(_onGoogleLogin);
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthResetPasswordSubmitted>(_onResetPassword);

    // Listen for global auth failures - only logout if currently authenticated
    _apiService.authFailures.listen((_) {
      if (state is AuthAuthenticated) {
        add(AuthLogout());
      }
    });
  }

  Future<void> _onLoadUser(
    AuthLoadUser event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _apiService.loadTokens();
      if (_apiService.isAuthenticated) {
        final user = await _apiService.getCurrentUser();
        if (user != null) {
          // Connect to realtime service
          await _connectRealtime();
          // Update FCM token
          getIt<NotificationService>().updateToken();
          
          // Trigger profile load
          getIt<ProfileBloc>().add(LoadProfile());
          
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogout(
    AuthLogout event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _apiService.logout();
      await _realtimeService.disconnect();
    } catch (_) {}
    emit(AuthUnauthenticated());
  }

  Future<void> _onLogin(
    AuthLogin event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _apiService.login(event.email, event.password);
      if (user != null) {
        // Connect to realtime service (fire-and-forget, don't block login)
        _connectRealtime().catchError((e) {
          print('AuthBloc: Realtime connection failed: $e');
        });
        
        // Update FCM token for push notifications (fire-and-forget)
        getIt<NotificationService>().updateToken().catchError((e) {
          print('AuthBloc: Failed to update FCM token: $e');
        });
        
        // Trigger profile load
        getIt<ProfileBloc>().add(LoadProfile());
        
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      String message = e.toString();
      if (e is ApiException) {
        message = e.userFriendlyMessage;
      }
      emit(AuthError('Login failed: $message'));
    }
  }

  Future<void> _onRegister(
    AuthRegister event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _apiService.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      if (user != null) {
        // Connect to realtime service
        await _connectRealtime();
        
        // Trigger profile load
        getIt<ProfileBloc>().add(LoadProfile());
        
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      String message = e.toString();
      if (e is ApiException) {
        message = e.userFriendlyMessage;
      }
      emit(AuthError('Registration failed: $message'));
    }
  }

  static bool _googleSignInInitialized = false;

  Future<void> _initGoogleSignIn() async {
    if (_googleSignInInitialized) return;
    
    try {
      final googleSignIn = GoogleSignIn.instance;
      
      /*
        On Android:
        - clientId should be null (it uses google-services.json).
        - serverClientId should be the Web Client ID (to get the idToken).
      */
      await googleSignIn.initialize(
        clientId: Platform.isIOS ? AppConfig.shared.googleIosClientId : null,
        serverClientId: AppConfig.shared.googleWebClientId,
      );
      _googleSignInInitialized = true;
      print('AuthBloc: Google Sign-In initialized successfully');
    } catch (e) {
      print('AuthBloc: Google Sign-In initialization failed: $e');
    }
  }

  Future<void> _onGoogleLogin(
    AuthGoogleLogin event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _initGoogleSignIn();
      
      final googleSignIn = GoogleSignIn.instance;
      
      // Clean up any stale session before starting a new one
      try {
        await googleSignIn.signOut();
      } catch (_) {}
      
      // Use authenticate() as per version 7.x patterns
      final GoogleSignInAccount? account = await googleSignIn.authenticate(
        scopeHint: ['email', 'profile', 'openid'],
      );
      
      if (account == null) {
        print('AuthBloc: Google Sign-In cancelled by user');
        emit(AuthUnauthenticated());
        return;
      }

      final GoogleSignInAuthentication googleAuth = account.authentication;
      final String? idToken = googleAuth.idToken;

      print('AuthBloc: Google Sign-In Successful for ${account.email}');
      print('AuthBloc: ID Token Length: ${idToken?.length}');

      if (idToken == null) {
        emit(AuthError('Failed to get ID token from Google'));
        return;
      }

      final user = await _apiService.googleLogin(idToken);
      if (user != null) {
        _connectRealtime().catchError((e) => print('AuthBloc: Realtime failed: $e'));
        getIt<NotificationService>().updateToken().catchError((e) => print('AuthBloc: FCM failed: $e'));
        getIt<ProfileBloc>().add(LoadProfile());
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      print('AuthBloc: Google login exception: $e');
      
      // Handle user cancellation gracefully
      final errorString = e.toString();
      if (errorString.contains('canceled') || errorString.contains('cancelled')) {
        print('AuthBloc: Google Sign-In cancelled by user (exception)');
        emit(AuthUnauthenticated());
        return;
      }
      
      // If we get "reauth failed", advise the user to try again or check Play Services
      String message = errorString;
      if (message.contains('16')) {
        message = 'Google re-authentication failed. Please ensure your Google Play Services are up to date and try again.';
      }
      emit(AuthError('Google login failed: $message'));
    }
  }

  Future<void> _connectRealtime() async {
    final token = _apiService.accessToken;
    if (token != null) {
      await _realtimeService.connect(token);
    }
  }

  Future<void> _onForgotPassword(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthForgotPasswordLoading());
    try {
      await _apiService.forgotPassword(event.email);
      emit(AuthForgotPasswordSuccess());
    } catch (e) {
      String message = e.toString();
      if (e is ApiException) {
        message = e.userFriendlyMessage;
      }
      emit(AuthForgotPasswordError(message));
    }
  }

  Future<void> _onResetPassword(
    AuthResetPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthResetPasswordLoading());
    try {
      await _apiService.resetPassword(
        email: event.email,
        code: event.code,
        newPassword: event.newPassword,
      );
      emit(AuthResetPasswordSuccess());
    } catch (e) {
      String message = e.toString();
      if (e is ApiException) {
        message = e.userFriendlyMessage;
      }
      emit(AuthResetPasswordError(message));
    }
  }
}
