import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart' show Icons;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';
import '../models/user.dart';
import '../models/ad.dart';
import '../models/task.dart';
import '../models/offer.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/question.dart';
import '../models/category.dart';
import '../models/search_history.dart';
import '../models/filter_criteria.dart';
import '../models/profession.dart';
import '../models/tasker_profile.dart';
import '../models/equipment.dart';
import '../models/review.dart';
import '../models/badge.dart';
import '../models/payment_transaction.dart';
import '../models/wallet.dart';
import '../models/dispute.dart';
import '../models/escrow.dart';
import '../models/portfolio_item.dart';

import 'dart:io';

class ApiService {
  // Determine the correct base URL dynamically
  static String get baseUrl {
    if (kIsWeb) return AppConfig.shared.apiUrl;
    if (Platform.isAndroid) {
        // Android Emulator loopback
        final current = AppConfig.shared.apiUrl;
        if (current.contains('localhost') || current.contains('127.0.0.1')) {
            return current.replaceAll(RegExp(r'localhost|127\.0\.0\.1'), '10.0.2.2');
        }
        return current;
    }
    return AppConfig.shared.apiUrl;
  }

  // Asset base URL for images
  static String get assetBaseUrl {
    if (kIsWeb) return AppConfig.shared.assetBaseUrl;
    if (Platform.isAndroid) {
        // Android Emulator loopback
        final current = AppConfig.shared.assetBaseUrl;
        if (current.contains('localhost') || current.contains('127.0.0.1')) {
            return current.replaceAll(RegExp(r'localhost|127\.0\.0\.1'), '10.0.2.2');
        }
        return current;
    }
    return AppConfig.shared.assetBaseUrl;
  }

  String? _accessToken;
  String? _refreshToken;
  User? _currentUser;
  late final Dio _dio;
  final _authFailureController = StreamController<void>.broadcast();
  Stream<void> get authFailures => _authFailureController.stream;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    
    // Add interceptor for auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && _refreshToken != null) {
          try {
            // Avoid infinite loop if refresh token itself is 401
            if (error.requestOptions.path.contains('/auth/refresh')) {
              debugPrint('ApiService: Refresh token itself returned 401, clearing tokens');
              await clearTokens();
              return handler.next(error);
            }

            debugPrint('ApiService: Got 401, attempting token refresh...');
            
            // Attempt to refresh token
            // Use a separate Dio instance or lock to avoid interceptor recursion
            final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
            final response = await refreshDio.post('/auth/refresh', data: {
              'refresh_token': _refreshToken,
            });
            
            final newAccessToken = response.data['access_token'];
            // Backend might or might not return a new refresh token
            final newRefreshToken = response.data['refresh_token'] ?? _refreshToken;
            
            if (newAccessToken != null) {
              debugPrint('ApiService: Token refresh successful');
              await saveTokens(newAccessToken, newRefreshToken);
              
              // Re-try the original request
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $newAccessToken';
              
              final retryResponse = await _dio.request(
                options.path,
                options: Options(
                  method: options.method,
                  headers: options.headers,
                ),
                data: options.data,
                queryParameters: options.queryParameters,
              );
              
              return handler.resolve(retryResponse);
            } else {
              throw Exception('No access token in refresh response');
            }
          } catch (e) {
            debugPrint('ApiService: Token refresh failed: $e');
            // If refresh fails, clear tokens (logout)
            await clearTokens();
            final path = error.requestOptions.path;
            if (!path.contains('/auth/login') && 
                !path.contains('/auth/register') && 
                !path.contains('/auth/logout')) {
              _authFailureController.add(null);
            }
          }
        } else if (error.response?.statusCode == 401) {
          // 401 but no refresh token
          debugPrint('ApiService: Got 401 with no refresh token, clearing tokens');
          await clearTokens();
          final path = error.requestOptions.path;
          if (!path.contains('/auth/login') && 
              !path.contains('/auth/register') && 
              !path.contains('/auth/logout')) {
            _authFailureController.add(null);
          }
        }
        return handler.next(error);
      },
    ));
  }



  // ============ MAP SETTINGS ============

  Future<String> getMapProvider() async {
    try {
      final data = await _get('/settings/map-provider');
      return data['provider'] ?? 'osm';
    } catch (e) {
      debugPrint('Error fetching map provider: $e');
      return 'osm';
    }
  }

  Future<bool> getGoogleSignInStatus() async {
    try {
      final data = await _get('/settings/google-signin');
      return data['enabled'] == true;
    } catch (e) {
      debugPrint('Error fetching Google Sign-In status: $e');
      return true; // Default to enabled on error
    }
  }

  /// Reports Google Maps API usage to backend. Returns true if limit NOT reached.
  Future<bool> reportMapUsage() async {
    try {
      final response = await _post('/settings/map-usage', {});
      if (response is Map) {
        final limitReached = response['limit_reached'] == true;
        if (limitReached) {
          debugPrint('Google Maps daily limit reached!');
          return false;
        }
      }
      return true;
    } catch (e) {
      // Fail silently, metrics are not critical for functionality
      debugPrint('Error reporting map usage: $e');
      return true; // Allow usage on error
    }
  }

  // ============ TOKEN MANAGEMENT ============

  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    _authFailureController.add(null);
  }

  /// Clear cached user data without clearing auth tokens
  void clearUserCache() {
    _currentUser = null;
  }

  bool get isAuthenticated => _accessToken != null;
  String? get accessToken => _accessToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // ============ HTTP HELPERS (using Dio) ============

  Future<dynamic> _get(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> _post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(endpoint, data: body);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> _patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch(endpoint, data: body);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> _delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> _uploadFile(String endpoint, File file, {String? type}) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        if (type != null) 'type': type,
      });

      final response = await _dio.post(endpoint, data: formData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiException _handleDioError(DioException e) {
    debugPrint('ApiService Error: ${e.requestOptions.path} [${e.response?.statusCode}]');
    debugPrint('ApiService Response: ${e.response?.data}');
    
    final statusCode = e.response?.statusCode ?? 0;
    String message = 'Network error. Please check your connection.';
    String? code;
    
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      message = 'Connection timed out. Please check your internet.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Unable to connect to server. Please check your internet.';
    } else if (e.response?.data != null && e.response?.data is Map) {
      message = e.response?.data['error'] ?? e.message ?? 'Unknown error';
      code = e.response?.data['code'];
    } else if (e.message != null && !e.message!.contains('ApiException')) {
      // Only use the raw message if we really have nothing else, but cleaner to default to generic
      // message = e.message!; 
    }
    
    if (statusCode == 401) {
      if (message == 'Network error. Please check your connection.' || message == 'Unknown error') {
        message = 'Unauthorized';
      }
    }
    
    return ApiException(message, statusCode, code: code);
  }

  Future<void> replyToQuestion(String questionId, String content) async {
    await _post('/questions/$questionId/reply', {
      'content': content,
    });
  }

  // ============ AUTHENTICATION ============

  Future<User?> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? location,
  }) async {
    final data = await _post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
      if (phone != null) 'phone': phone,
      if (location != null) 'location': location,
    });

    await saveTokens(data['access_token'], data['refresh_token']);
    _currentUser = _mapUser(data['user']);
    return _currentUser;
  }

  Future<User?> login(String email, String password) async {
    final data = await _post('/auth/login', {
      'email': email,
      'password': password,
    });

    await saveTokens(data['access_token'], data['refresh_token']);
    _currentUser = _mapUser(data['user']);
    return _currentUser;
  }
  Future<User?> googleLogin(String idToken) async {
    final data = await _post('/auth/google', {
      'id_token': idToken,
    });

    await saveTokens(data['access_token'], data['refresh_token']);
    _currentUser = _mapUser(data['user']);
    return _currentUser;
  }

  Future<User?> getCurrentUser({bool forceRefresh = false}) async {
    print('ApiService: getCurrentUser called (forceRefresh=$forceRefresh)');
    if (_currentUser != null && !forceRefresh) {
      print('ApiService: returning cached _currentUser: ${_currentUser?.name}');
      return _currentUser;
    }
    try {
      print('ApiService: Fetching /auth/me');
      final data = await _get('/auth/me');
      print('ApiService: /auth/me response received');
      _currentUser = _mapUser(data);
      print('ApiService: mapped user: ${_currentUser?.name}');
      return _currentUser;
    } on ApiException catch (e) {
      print('ApiService: Auth error in getCurrentUser: $e');
      if (e.statusCode == 401 || e.statusCode == 404) {
        // Clear tokens if we're definitively unauthorized or user no longer exists (404)
        await clearTokens();
      }
      return null;
    } catch (e) {
      print('ApiService: error in getCurrentUser: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _post('/auth/logout', {});
    } finally {
      await clearTokens();
    }
  }

  Future<void> forgotPassword(String email) async {
    await _post('/auth/forgot-password', {
      'email': email,
    });
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _post('/auth/reset-password', {
      'email': email,
      'code': code,
      'new_password': newPassword,
    });
  }

  Future<User?> getUser(String userId) async {
    try {
      final data = await _get('/users/$userId');
      return _mapUser(data);
    } catch (e) {
      return null;
    }
  }

  Future<List<PaymentTransaction>> getPaymentHistory() async {
    try {
      final List<dynamic> data = await _get('/payments/history');
      return data.map((e) => _mapTransaction(e)).toList();
    } catch (e) {
      debugPrint('Error fetching payment history: $e');
      return [];
    }
  }

  PaymentTransaction _mapTransaction(Map<String, dynamic> data) {
    // Backend returns models.EscrowTransaction + TaskTitle
    return PaymentTransaction(
      id: data['id']?.toString() ?? '',
      taskId: data['task_id']?.toString() ?? '',
      taskTitle: data['task_title'] ?? 'Task',
      amount: (data['amount'] ?? 0).toDouble(),
      type: TransactionType.payment, // Released escrow is a payment
      status: TransactionStatus.completed,
      date: data['updated_at'] != null ? DateTime.parse(data['updated_at']) : DateTime.now(),
      description: 'Earning from task completion',
    );
  }

  // ============ TASKS ============

  Future<List<Task>> getTasks({
    FilterCriteria? criteria,
    String? sortBy,
    String? posterId,
    String? taskType,
    String? tier,
    int limit = 20,
    int offset = 0,
  }) async {
    String endpoint = '/tasks?limit=$limit&offset=$offset&';
    
    if (criteria != null) {
      if (criteria.taskStatus.isNotEmpty) {
        endpoint += 'status=${criteria.taskStatus.join(",")}&';
      }
      if (criteria.minPrice != null) endpoint += 'min_price=${criteria.minPrice}&';
      if (criteria.maxPrice != null) endpoint += 'max_price=${criteria.maxPrice}&';
      if (criteria.distanceKm != null) {
        endpoint += 'distance=${criteria.distanceKm}&';
        if (criteria.latitude != null) endpoint += 'lat=${criteria.latitude}&';
        if (criteria.longitude != null) endpoint += 'lng=${criteria.longitude}&';
      }
      if (criteria.fromDate != null) endpoint += 'from_date=${criteria.fromDate!.toIso8601String()}&';
      if (criteria.toDate != null) endpoint += 'to_date=${criteria.toDate!.toIso8601String()}&';
    }

    if (sortBy != null) endpoint += 'sort=$sortBy&';
    if (posterId != null) endpoint += 'poster_id=$posterId&';
    if (taskType != null) endpoint += 'task_type=$taskType&';
    if (tier != null) endpoint += 'tier=$tier&';

    debugPrint('ApiService: Fetching $endpoint');
    final data = await _get(endpoint);
    debugPrint('ApiService: Received ${data is List ? data.length : 0} tasks');
    if (data is List) {
      return data.map((t) => _mapTask(t)).toList();
    }
    return [];
  }

  Future<Task?> getTaskById(String id) async {
    try {
      final data = await _get('/tasks/$id');
      return _mapTask(data);
    } catch (e) {
      return null;
    }
  }

  Future<List<Task>> getActiveTasks() async {
    try {
      final data = await _get('/tasks/active');
      if (data is List) {
        return data.map((t) => _mapTask(t)).toList();
      }
      return [];
    } catch (e) {
      print('ApiService: Error fetching active tasks: $e');
      return [];
    }
  }

  Future<void> completeTask(String id) async {
    await _post('/tasks/$id/complete', {});
  }

  Future<List<Ad>> getAds() async {
    try {
      final data = await _get('/ads');
      if (data is List) {
        return data.map((json) => Ad.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('ApiService: Error fetching ads: $e');
      return [];
    }
  }

  Future<void> trackAdImpression(String adId) async {
    try {
      await _dio.post('/ads/$adId/impression');
    } catch (e) {
      debugPrint('ApiService: Error tracking ad impression: $e');
    }
  }

  Future<void> trackAdClick(String adId) async {
    try {
      await _dio.post('/ads/$adId/click');
    } catch (e) {
      debugPrint('ApiService: Error tracking ad click: $e');
    }
  }

  Future<List<Task>> getPendingReviews() async {
    try {
      final data = await _get('/reviews/pending');
      if (data is List) {
        return data.map((t) => _mapTask(t)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> createReview({
    required String taskId,
    required int communication,
    required int time,
    required int professionalism,
    String? comment,
  }) async {
    await _post('/reviews', {
      'task_id': taskId,
      'rating_communication': communication,
      'rating_time': time,
      'rating_professionalism': professionalism,
      if (comment != null) 'comment': comment,
    });
  }

  Future<void> replyReview(String reviewId, String reply) async {
    await _post('/reviews/$reviewId/reply', {
      'reply': reply,
    });
  }

  Future<List<Task>> getTasksWithFilter({
    String? taskType,
    String? category,
    String? location,
  }) async {
    String endpoint = '/tasks?';
    if (taskType != null) endpoint += 'task_type=$taskType&';
    if (category != null && category != 'All') endpoint += 'category=$category&';
    if (location != null) endpoint += 'location=$location&';

    final data = await _get(endpoint);
    if (data is List) {
      return data.map((t) => _mapTask(t)).toList();
    }
    return [];
  }


  Future<String> createTask(Map<String, dynamic> taskData) async {
    final data = await _post('/tasks', taskData);
    return data['taskId'] ?? data['task_id'] ?? data['id'] ?? '';
  }

  Future<void> updateTask(String id, Map<String, dynamic> updates) async {
    await _patch('/tasks/$id', updates);
  }

  Future<void> deleteTask(String id) async {
    await _delete('/tasks/$id');
  }

  Future<List<String>> uploadTaskImages(String taskId, List<String> filePaths) async {
    if (filePaths.isEmpty) return [];

    try {
      FormData formData = FormData();
      for (String path in filePaths) {
        String fileName = path.split('/').last;
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(path, filename: fileName),
        ));
      }

      final response = await _dio.post('/tasks/$taskId/images', data: formData);
      final List<dynamic> urls = response.data['urls'] ?? [];
      return urls.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<String>> uploadTaskAttachments(String taskId, List<String> filePaths) async {
    if (filePaths.isEmpty) return [];

    try {
      FormData formData = FormData();
      for (String path in filePaths) {
        String fileName = path.split('/').last;
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(path, filename: fileName),
        ));
      }

      final response = await _dio.post('/tasks/$taskId/attachments', data: formData);
      final List<dynamic> urls = response.data['urls'] ?? [];
      return urls.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String?> uploadProjectBOQ(String taskId, String filePath) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
      });

      final response = await _dio.post('/tasks/$taskId/project-boq', data: formData);
      return response.data['url']?.toString();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<String>> uploadProjectPlans(String taskId, List<String> filePaths) async {
    if (filePaths.isEmpty) return [];

    try {
      FormData formData = FormData();
      for (String path in filePaths) {
        String fileName = path.split('/').last;
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(path, filename: fileName),
        ));
      }

      final response = await _dio.post('/tasks/$taskId/project-plans', data: formData);
      final List<dynamic> urls = response.data['urls'] ?? [];
      return urls.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ============ OFFERS ============

  Future<List<Offer>> getOffersForTask(String taskId) async {
    try {
      print('ApiService: Fetching offers for task $taskId');
      final data = await _get('/tasks/$taskId/offers');
      print('ApiService: Received offers data: $data');
      if (data is List) {
        final offers = data.map((o) => _mapOffer(o)).toList();
        print('ApiService: Mapped ${offers.length} offers');
        return offers;
      }
      print('ApiService: Data is not a list, returning empty');
      return [];
    } catch (e) {
      print('ApiService: Error fetching offers: $e');
      // Rethrow to let the bloc handle it properly
      rethrow;
    }
  }

  Future<Offer> createOffer({
    required String taskId,
    required double amount,
    required String description,
    String availability = 'Flexible',
    String? invoiceFilePath,
  }) async {
    try {
      if (invoiceFilePath != null && invoiceFilePath.isNotEmpty) {
        // Use multipart/form-data if invoice is attached
        final formData = FormData.fromMap({
          'task_id': taskId,
          'amount': amount.toString(),
          'description': description,
          'availability': availability,
          'estimated_duration': 'Not specified',
          'invoice': await MultipartFile.fromFile(
            invoiceFilePath,
            filename: invoiceFilePath.split('/').last,
          ),
        });

        final response = await _dio.post(
          '$baseUrl/offers',
          data: formData,
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'multipart/form-data',
            },
          ),
        );

        return _mapOffer(response.data);
      } else {
        // Regular JSON POST
        final response = await _dio.post(
          '$baseUrl/offers',
          data: {
            'task_id': taskId,
            'amount': amount,
            'description': description,
            'availability': availability,
            'estimated_duration': 'Not specified',
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          ),
        );
        return _mapOffer(response.data);
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map 
          ? e.response?.data['error'] ?? e.message 
          : e.message;
      throw Exception(message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> acceptOffer(String offerId, String taskId, {String paymentMethod = 'escrow'}) async {
    await _post('/offers/$offerId/accept', {
      'payment_method': paymentMethod,
    });
  }

  Future<void> withdrawOffer(String offerId) async {
    await _delete('/offers/$offerId');
  }

  /// Check if current user already has an offer on a task
  Future<bool> hasOfferOnTask(String taskId) async {
    try {
      final data = await _get('/tasks/$taskId/my-offer');
      return data['has_offer'] == true;
    } catch (e) {
      debugPrint('ApiService: Error checking offer: $e');
      return false;
    }
  }

  /// Get unread message count across all conversations
  Future<int> getUnreadMessageCount() async {
    try {
      final conversations = await getConversations();
      int count = 0;
      for (final conv in conversations) {
        count += conv.unreadCount;
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final notifications = await getNotifications();
      return notifications.where((n) => n['read'] != true).length;
    } catch (e) {
      return 0;
    }
  }



  // ============ USERS ============

  Future<User?> getUserById(String id) async {
    try {
      final data = await _get('/users/$id');
      return _mapUser(data);
    } catch (e) {
      return null;
    }
  }

  // Alias for getUserById
  // Future<User?> getUser(String id) => getUserById(id); // DUPLICATE REMOVED

  Future<User> updateUser(String id, Map<String, dynamic> updates) async {
    final data = await _patch('/users/$id', updates);
    return _mapUser(data);
  }

  // ============ CONVERSATIONS & MESSAGES ============

  Future<List<Conversation>> getConversations() async {
    try {
      final data = await _get('/conversations');
      if (data is List) {
        return data.map((c) => _mapConversation(c)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Conversation?> getConversation(String id) async {
    try {
      final data = await _get('/conversations/$id');
      return _mapConversation(data);
    } catch (e) {
      return null;
    }
  }

  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final data = await _get('/conversations/$conversationId/messages');
      if (data is List) {
        return data.map((m) => _mapMessage(m)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Message> sendMessage(Message message) async {
    final data = await _post('/conversations/${message.conversationId}/messages', {
      'content': message.content,
    });
    return _mapMessage(data);
  }

  Future<void> markMessageAsRead(String messageId) async {
    await _patch('/messages/$messageId/read', {});
  }

  Future<void> markConversationAsRead(String conversationId) async {
    await _post('/conversations/$conversationId/read', {});
  }

  // ============ NOTIFICATIONS ============

  Future<void> updateFCMToken(String token) async {
    await _post('/users/fcm-token', {'token': token});
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final data = await _get('/notifications');
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    await _patch('/notifications/$id/read', {});
  }

  // ============ QUESTIONS ============

  Future<List<Question>> getQuestions(String taskId) async {
    try {
      final data = await _get('/tasks/$taskId/questions');
      if (data is List) {
        return data.map((q) => _mapQuestion(q)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Question> askQuestion(String taskId, String questionText) async {
    final data = await _post('/tasks/$taskId/questions', {
      'content': questionText,
    });
    return _mapQuestion(data);
  }

  // ============ CATEGORIES ============

  Future<List<Category>> getCategories({String? type}) async {
    String endpoint = '/categories';
    if (type != null) {
      endpoint += '?type=$type';
    }
    final data = await _get(endpoint);
    if (data is List) {
      return data.map((c) => Category.fromJson(c)).toList();
    }
    return [];
  }

  Future<List<Category>> getEquipmentCategories() async {
    return getCategories(type: 'equipment');
  }

  Future<List<Category>> getServiceCategories() async {
    return getCategories(type: 'service');
  }

  // ============ SEARCH ============

  Future<List<SearchHistory>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    return history.asMap().entries.map((e) => SearchHistory(
      id: e.key.toString(),
      query: e.value,
      timestamp: DateTime.now().subtract(Duration(days: e.key)),
    )).toList();
  }

  Future<void> addSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    history.remove(query);
    history.insert(0, query);
    if (history.length > 10) history.removeLast();
    await prefs.setStringList('search_history', history);
  }

  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    // Return suggestions based on task titles
    try {
      final tasks = await getTasks();
      final suggestions = tasks
          .where((t) => t.title.toLowerCase().contains(query.toLowerCase()))
          .map((t) => t.title)
          .take(5)
          .toList();
      return suggestions;
    } catch (e) {
      return [];
    }
  }

  // ============ PROFESSIONS ============

  Future<List<Profession>> getProfessions() async {
    try {
      final data = await _get('/professions');
      if (data is List) {
        return data.map((e) => Profession.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ============ UNITS OF MEASUREMENT ============

  Future<List<Map<String, dynamic>>> getUnitsOfMeasurement({String status = 'approved'}) async {
    try {
      final data = await _get('/units-of-measurement?status=$status');
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('ApiService: Error fetching units: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> submitUnitOfMeasurement(String name, String symbol) async {
    final data = await _post('/units-of-measurement', {
      'name': name,
      'symbol': symbol,
    });
    return data;
  }

  Future<void> updateTaskerProfile(Map<String, dynamic> data) async {
    await _post('/tasker/profile', data);
  }

  Future<String> uploadTaskerFile(File file, String type) async {
    final data = await _uploadFile('/tasker/upload', file, type: type);
    final url = data['url'] ?? '';
    
    // After upload, sync metadata
    await uploadTaskerFileMetadata(url, type);
    
    return url;
  }

  Future<String> uploadUserAvatar(File file) async {
    final data = await _uploadFile('/users/avatar', file);
    return data['url'] ?? data['avatar_url'] ?? '';
  }

  Future<void> uploadTaskerFileMetadata(String fileUrl, String type) async {
    await _post('/tasker/upload-metadata', {
      'file_url': fileUrl,
      'type': type,
    });
  }

  // ============ MAPPERS ============

  User _mapUser(Map<String, dynamic> data) {
    String? avatarUrl = data['avatar_url'];
    if (avatarUrl != null && !avatarUrl.startsWith('http')) {
      avatarUrl = '$assetBaseUrl$avatarUrl';
    }

    List<Review> reviews = [];
    if (data['reviews_received'] != null) {
      reviews = (data['reviews_received'] as List).map((r) {
        // Ensure reviewer avatar is processed
        if (r['reviewer'] != null && r['reviewer']['avatar_url'] != null) {
          String url = r['reviewer']['avatar_url'];
          if (!url.startsWith('http')) {
            r['reviewer']['avatar_url'] = '$assetBaseUrl$url';
          }
        }
        return Review.fromJson(r);
      }).toList();
    }

    // Map portfolio items from tasker_profile.portfolio_urls
    List<PortfolioItem> portfolio = [];
    if (data['tasker_profile'] != null && data['tasker_profile']['portfolio_urls'] != null) {
      portfolio = (data['tasker_profile']['portfolio_urls'] as List).map((url) {
        String finalUrl = url.toString();
        if (!finalUrl.startsWith('http')) {
          finalUrl = '$assetBaseUrl$finalUrl';
        }
        return PortfolioItem(
          id: url.toString(),
          imageUrl: finalUrl,
          title: 'Project Item', // Fallback title since backend doesn't provide one
        );
      }).toList();
    }

    return User(
      id: data['id'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      profileImage: avatarUrl,
      bio: data['bio'],
      rating: (data['rating'] ?? 0).toDouble(),
      totalReviews: data['review_count'] ?? 0,
      isVerified: data['is_verified'] ?? false,
      verificationType: data['verification_type'],
      isTasker: data['is_tasker'] ?? false,
      userType: (data['is_tasker'] == true) ? 'tasker' : 'poster',
      reviews: reviews,
      portfolio: portfolio,
      taskerProfile: data['tasker_profile'] != null
          ? TaskerProfile.fromJson(data['tasker_profile'])
          : null,
      memberSince: data['member_since'] != null
          ? DateTime.parse(data['member_since'])
          : DateTime.now(),
      address: data['address'],
      city: data['city'],
      businessName: data['business_name'],
      businessAddress: data['business_address'],
      suburb: data['suburb'],
      country: data['country'],
      postcode: data['postcode'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      dateOfBirth: data['date_of_birth'] != null
          ? DateTime.parse(data['date_of_birth'])
          : null,
      badges: (data['badges'] as List?)
              ?.map((e) => UserBadge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tasksCompleted: data['tasks_completed'] ?? 0,
      tasksCompletedOnTime: data['tasks_completed_on_time'] ?? 0,
    );
  }

  Task _mapTask(Map<String, dynamic> data) {
    // Process photos/attachments
    List<TaskAttachment> attachments = [];
    List<String> photos = [];
    
    if (data['attachments'] != null) {
      for (var a in (data['attachments'] as List)) {
        String url = a['url'] ?? '';
        if (url.isNotEmpty && !url.startsWith('http')) {
          url = '$assetBaseUrl$url';
        }
        
        // Use the model's fromJson but with our processed URL
        final attachmentData = Map<String, dynamic>.from(a);
        attachmentData['url'] = url;
        final attachment = TaskAttachment.fromJson(attachmentData);
        
        attachments.add(attachment);
        if (attachment.type == 'image') {
          photos.add(url);
        }
      }
    }

    String? posterImage = data['poster']?['avatar_url'];
    if (posterImage != null && !posterImage.startsWith('http')) {
      posterImage = '$assetBaseUrl$posterImage';
    }

    // Parse date (backend sends 'date', not 'due_date')
    DateTime? deadline;
    if (data['date'] != null) {
      try {
        deadline = DateTime.parse(data['date'].toString());
      } catch (e) {
        // Ignore parse errors
      }
    } else if (data['due_date'] != null) {
      try {
        deadline = DateTime.parse(data['due_date'].toString());
      } catch (e) {
        // Ignore parse errors
      }
    }

    // Parse lat/lng
    double? lat;
    double? lng;
    if (data['lat'] != null) {
      lat = (data['lat'] is num) ? (data['lat'] as num).toDouble() : double.tryParse(data['lat'].toString());
    }
    if (data['lng'] != null) {
      lng = (data['lng'] is num) ? (data['lng'] as num).toDouble() : double.tryParse(data['lng'].toString());
    }


    return Task(
      id: data['id'] ?? '',
      posterId: data['poster_id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      locationAddress: data['location'] ?? '',
      locationLat: lat,
      locationLng: lng,
      city: data['city'] as String?,
      suburb: data['suburb'] as String?,
      addressDetails: data['address_details'] as String?,
      budget: (data['budget'] ?? 0).toDouble(),
      deadline: deadline,
      dateType: data['date_type'] as String?,
      timeOfDay: data['time_of_day'] as String?,
      status: data['status'] ?? 'open',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      taskType: data['task_type'] as String? ?? 'service',
      posterName: data['poster']?['name'] ?? '',
      posterImage: posterImage,
      posterVerified: data['poster']?['is_verified'] ?? false,
      posterRating: (data['poster']?['rating'] ?? 0).toDouble(),
      offersCount: data['offer_count'] ?? 0,
      questionsCount: data['question_count'] ?? 0,
      views: data['views'] ?? 0,
      photos: photos,
      attachments: attachments,
      conversationId: data['conversation_id'],
      assignedToName: data['accepted_offer']?['tasker']?['name'],
      assignedToImage: data['accepted_offer']?['tasker']?['avatar_url'] != null && !(data['accepted_offer']?['tasker']?['avatar_url'] as String).startsWith('http')
          ? '$assetBaseUrl${data['accepted_offer']!['tasker']!['avatar_url']}'
          : data['accepted_offer']?['tasker']?['avatar_url'],
      poster: data['poster'] != null ? _mapUser(data['poster']) : null,
      assignee: data['accepted_offer']?['tasker'] != null ? _mapUser(data['accepted_offer']['tasker']) : null,
      
      // Equipment fields
      costingBasis: data['costing_basis'] as String?,
      hireDurationType: data['hire_duration_type'] as String?,
      estimatedHours: data['estimated_hours'] != null ? (data['estimated_hours'] as num).toDouble() : null,
      estimatedDuration: data['estimated_duration'] != null ? (data['estimated_duration'] as num).toDouble() : null,
      equipmentUnits: data['equipment_units'] as int?,
      numberOfTrips: data['number_of_trips'] as int?,
      distancePerTrip: data['distance_per_trip'] != null ? (data['distance_per_trip'] as num).toDouble() : null,
      fuelIncluded: data['fuel_included'] as bool?,
      operatorPreference: data['operator_preference'] as String?,
      capacityValue: data['capacity_value'] != null ? (data['capacity_value'] as num).toDouble() : null,
      capacityUnit: data['capacity_unit'] as String?,
      requiresSiteVisit: data['requires_site_visit'] as bool? ?? false,
      boqUrl: data['boq_url'] as String?,
      plansUrls: data['plans_urls'] as String?,
      timelineStart: data['timeline_start'] != null ? DateTime.tryParse(data['timeline_start']) : null,
      timelineEnd: data['timeline_end'] != null ? DateTime.tryParse(data['timeline_end']) : null,
      siteReadiness: data['site_readiness'] as String?,
      projectSize: data['project_size'] as String?,
    );
  }

  Offer _mapOffer(Map<String, dynamic> data) {
    String? taskerImage = data['tasker']?['avatar_url'];
    if (taskerImage != null && !taskerImage.startsWith('http')) {
      taskerImage = '$assetBaseUrl$taskerImage';
    }

    final tasker = data['tasker'] as Map<String, dynamic>?;
    
    return Offer(
      id: data['id'] ?? '',
      taskId: data['task_id'] ?? '',
      taskerId: data['tasker_id'] ?? '',
      amount: data['amount'] != null ? (data['amount'] as num).toDouble() : null,
      message: data['description'] ?? data['message'] ?? '', // API uses 'description'
      status: data['status'] ?? 'pending',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      taskerName: tasker?['name'] ?? '',
      taskerImage: taskerImage,
      taskerVerified: tasker?['is_verified'] ?? false,
      taskerRating: (tasker?['rating'] ?? 0).toDouble(),
      reviewCount: tasker?['review_count'] ?? 0,
      taskerCompletedTasks: tasker?['tasks_completed'] ?? 0,
      availability: data['availability'],
      invoiceUrl: data['invoice_url'],
      invoiceFileName: data['invoice_file_name'],
      completionRate: tasker?['tasks_completed_on_time'] != null 
          ? ((tasker!['tasks_completed_on_time'] as int) * 10).clamp(0, 100) 
          : null,
      tasker: tasker != null ? _mapUser(tasker) : null,
    );
  }

  Conversation _mapConversation(Map<String, dynamic> data) {
    String? otherUserImage = data['other_user']?['avatar_url'];
    if (otherUserImage != null && !otherUserImage.startsWith('http')) {
      otherUserImage = '$assetBaseUrl$otherUserImage';
    }

    return Conversation(
      id: data['id'] ?? '',
      taskId: data['task_id'] ?? '',
      otherUserId: data['other_user']?['id'] ?? '',
      otherUserName: data['other_user']?['name'] ?? '',
      otherUserImage: otherUserImage,
      lastMessage: data['last_message'] ?? '',
      lastMessageTime: data['last_message_at'] != null
          ? DateTime.parse(data['last_message_at'])
          : DateTime.now(),
      unreadCount: data['unread_count'] ?? 0,
      taskTitle: data['task']?['title'],
    );
  }

  // ============ INVENTORY ============

  Future<List<Equipment>> getMyInventory() async {
    final List data = await _get('/inventory');
    return data.map((json) => Equipment.fromJson(json)).toList();
  }

  Future<Equipment> createInventoryItem(Map<String, dynamic> data) async {
    final result = await _post('/inventory', data);
    return Equipment.fromJson(result);
  }

  Future<Equipment> updateInventoryItem(String id, Map<String, dynamic> data) async {
    final result = await _patch('/inventory/$id', data);
    return Equipment.fromJson(result);
  }

  Future<void> deleteInventoryItem(String id) async {
    await _delete('/inventory/$id');
  }

  Future<String> uploadInventoryFile(File file) async {
    final data = await _uploadFile('/inventory/upload', file);
    return data['url'] ?? '';
  }

  Message _mapMessage(Map<String, dynamic> data) {
    return Message(
      id: data['id'] ?? '',
      conversationId: data['conversation_id'] ?? data['conversationId'] ?? '',
      senderId: data['sender_id'] ?? data['senderId'] ?? '',
      receiverId: data['receiver_id'] ?? data['receiverId'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : (data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now()),
      read: data['is_read'] ?? data['read'] ?? false,
    );
  }

  Question _mapQuestion(Map<String, dynamic> data) {
    String? userImage = data['asker']?['avatar_url'] ?? data['user']?['avatar_url'];
    if (userImage != null && !userImage.startsWith('http')) {
      userImage = '$assetBaseUrl$userImage';
    }

    // Process nested replies (children)
    // For now, we'll take the first reply as the "answer" if it exists
    String? answer;
    DateTime? answerTimestamp;
    if (data['children'] != null && (data['children'] as List).isNotEmpty) {
      final firstReply = (data['children'] as List).first;
      answer = firstReply['content'];
      if (firstReply['created_at'] != null) {
        answerTimestamp = DateTime.parse(firstReply['created_at']);
      }
    }

    return Question(
      id: data['id'] ?? '',
      taskId: data['task_id'] ?? data['taskId'] ?? '',
      userId: data['asker_id'] ?? data['user_id'] ?? data['userId'] ?? '',
      userName: data['asker']?['name'] ?? data['user']?['name'] ?? data['userName'] ?? '',
      userImage: userImage,
      question: data['content'] ?? data['question'] ?? '',
      timestamp: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : (data['timestamp'] != null ? DateTime.parse(data['timestamp']) : DateTime.now()),
      answer: answer,
      answerTimestamp: answerTimestamp,
      isVerified: data['asker']?['is_verified'] ?? data['user']?['is_verified'] ?? false,
      user: data['user'] != null ? _mapUser(data['user']) : (data['asker'] != null ? _mapUser(data['asker']) : null),
    );
  }

  // ============ WALLET ============

  Future<Map<String, dynamic>?> getWallet() async {
    try {
      final data = await _get('/wallet');
      return data;
    } catch (e) {
      debugPrint('Error fetching wallet: $e');
      return null;
    }
  }

  Future<List<WalletTransaction>> getWalletTransactions() async {
    try {
      final data = await _get('/wallet/transactions');
      if (data is List) {
        return data.map((e) => WalletTransaction.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> initiateTopUp({
    required double amount,
    required String phone,
    required String paymentMethod,
  }) async {
    try {
      final data = await _post('/wallet/topup', {
        'amount': amount,
        'phone': phone,
        'payment_method': paymentMethod,
      });
      return data;
    } catch (e) {
      debugPrint('Error initiating top-up: $e');
      throw e;
    }
  }

  Future<WalletTransaction?> checkTransactionStatus(String transactionId) async {
    try {
      final data = await _get('/wallet/transactions/$transactionId');
      return WalletTransaction.fromJson(data);
    } catch (e) {
      debugPrint('Error checking transaction status: $e');
      return null;
    }
  }

  Future<double> getCommissionRate() async {
    try {
      final data = await _get('/settings/commission-rate');
      return (data['rate'] as num?)?.toDouble() ?? 3.0;
    } catch (e) {
      debugPrint('Error fetching commission rate: $e');
      return 3.0; // Default
    }
  }

  // ============ WITHDRAWALS ============

  Future<WithdrawalRequest> requestWithdrawal({
    required double amount,
    required String paymentMethod,
    required String accountNumber,
    String? accountName,
  }) async {
    final data = await _post('/wallet/withdraw', {
      'amount': amount,
      'payment_method': paymentMethod,
      'account_number': accountNumber,
      if (accountName != null) 'account_name': accountName,
    });
    return WithdrawalRequest.fromJson(data['withdrawal']);
  }

  Future<List<WithdrawalRequest>> getWithdrawals() async {
    try {
      final data = await _get('/wallet/withdrawals');
      if (data is List) {
        return data.map((e) => WithdrawalRequest.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching withdrawals: $e');
      return [];
    }
  }

  Future<WithdrawalRequest?> getWithdrawalById(String id) async {
    try {
      final data = await _get('/wallet/withdrawals/$id');
      return WithdrawalRequest.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching withdrawal: $e');
      return null;
    }
  }

  Future<WithdrawalRequest?> cancelWithdrawal(String id) async {
    try {
      final data = await _delete('/wallet/withdrawals/$id');
      return WithdrawalRequest.fromJson(data['withdrawal']);
    } catch (e) {
      debugPrint('Error cancelling withdrawal: $e');
      rethrow;
    }
  }

  // ============ DISPUTES ============

  Future<Dispute> createDispute({
    required String taskId,
    required String reason,
    required String description,
    List<String>? evidenceUrls,
  }) async {
    final data = await _post('/disputes', {
      'task_id': taskId,
      'reason': reason,
      'description': description,
      if (evidenceUrls != null) 'evidence_urls': evidenceUrls,
    });
    return Dispute.fromJson(data);
  }

  Future<List<Dispute>> getDisputes() async {
    try {
      final data = await _get('/disputes');
      if (data is List) {
        return data.map((e) => Dispute.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching disputes: $e');
      return [];
    }
  }

  Future<Dispute?> getDisputeById(String id) async {
    try {
      final data = await _get('/disputes/$id');
      return Dispute.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching dispute: $e');
      return null;
    }
  }

  Future<List<DisputeMessage>> getDisputeMessages(String disputeId) async {
    try {
      final data = await _get('/disputes/$disputeId/messages');
      if (data is List) {
        return data.map((e) => DisputeMessage.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching dispute messages: $e');
      return [];
    }
  }

  Future<DisputeMessage> sendDisputeMessage(String disputeId, String message) async {
    final data = await _post('/disputes/$disputeId/messages', {
      'message': message,
    });
    return DisputeMessage.fromJson(data);
  }

  // ============ ESCROW ============

  Future<List<EscrowTransaction>> getEscrows({String? role}) async {
    try {
      final queryParams = role != null ? '?role=$role' : '';
      final data = await _get('/escrow$queryParams');
      if (data is List) {
        return data.map((e) => EscrowTransaction.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching escrows: $e');
      return [];
    }
  }

  Future<EscrowTransaction?> getEscrowForTask(String taskId) async {
    try {
      final data = await _get('/escrow/task/$taskId');
      return EscrowTransaction.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching escrow for task: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> confirmEscrowCompletion(String escrowId) async {
    final data = await _post('/escrow/$escrowId/confirm', {});
    return data;
  }

  Future<void> requestEscrowRelease(String escrowId) async {
    await _post('/escrow/$escrowId/request-release', {});
  }

  Future<void> requestEscrowRefund(String escrowId, String reason) async {
    await _post('/escrow/$escrowId/request-refund', {
      'reason': reason,
    });
  }

  // ============= CURATED DATA =============

  // Fallback Zimbabwean qualification types
  static const List<Map<String, dynamic>> _fallbackQualificationTypes = [
    {'id': '1', 'name': 'National Certificate (NC)'},
    {'id': '2', 'name': 'National Diploma (ND)'},
    {'id': '3', 'name': 'Higher National Diploma (HND)'},
    {'id': '4', 'name': 'Bachelor\'s Degree'},
    {'id': '5', 'name': 'Master\'s Degree'},
    {'id': '6', 'name': 'Trade Certificate'},
    {'id': '7', 'name': 'Journeyman Certificate'},
    {'id': '8', 'name': 'City & Guilds'},
    {'id': '9', 'name': 'HEXCO Certificate'},
    {'id': '10', 'name': 'Professional Certification'},
  ];

  // Fallback Zimbabwean institutions
  static const List<Map<String, dynamic>> _fallbackInstitutions = [
    {'id': '1', 'name': 'University of Zimbabwe'},
    {'id': '2', 'name': 'National University of Science and Technology (NUST)'},
    {'id': '3', 'name': 'Harare Polytechnic'},
    {'id': '4', 'name': 'Bulawayo Polytechnic'},
    {'id': '5', 'name': 'Chinhoyi University of Technology'},
    {'id': '6', 'name': 'Midlands State University'},
    {'id': '7', 'name': 'Zimbabwe Ezekiel Guti University (ZEGU)'},
    {'id': '8', 'name': 'Women\'s University in Africa'},
    {'id': '9', 'name': 'Speciss College'},
    {'id': '10', 'name': 'Belvedere Technical Teachers College'},
    {'id': '11', 'name': 'Gweru Polytechnic'},
    {'id': '12', 'name': 'Msasa Vocational Training Centre'},
  ];

  /// Get all qualification types
  Future<List<Map<String, dynamic>>> getQualificationTypes() async {
    try {
      final data = await _get('/qualification-types');
      final result = List<Map<String, dynamic>>.from(data);
      return result.isEmpty ? _fallbackQualificationTypes : result;
    } catch (e) {
      debugPrint('Error fetching qualification types: $e');
      return _fallbackQualificationTypes;
    }
  }

  /// Get all institutions with optional search
  Future<List<Map<String, dynamic>>> getInstitutions({String? search}) async {
    try {
      String endpoint = '/institutions';
      if (search != null && search.isNotEmpty) {
        endpoint += '?search=$search';
      }
      final data = await _get(endpoint);
      final result = List<Map<String, dynamic>>.from(data);
      return result.isEmpty ? _fallbackInstitutions : result;
    } catch (e) {
      debugPrint('Error fetching institutions: $e');
      return _fallbackInstitutions;
    }
  }

  /// Submit a new institution for admin approval
  Future<Map<String, dynamic>?> submitInstitution(String name, String type) async {
    try {
      final data = await _post('/institutions', {
        'name': name,
        'type': type,
      });
      return data;
    } catch (e) {
      debugPrint('Error submitting institution: $e');
      return null;
    }
  }

  /// Get all locations (cities and suburbs)
  Future<List<Map<String, dynamic>>> getLocations({String? type, String? parentId}) async {
    try {
      String endpoint = '/locations';
      List<String> params = [];
      if (type != null) params.add('type=$type');
      if (parentId != null) params.add('parent_id=$parentId');
      if (params.isNotEmpty) endpoint += '?${params.join('&')}';
      final data = await _get(endpoint);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching locations: $e');
      return [];
    }
  }


  /// Get AdMob status
  Future<bool> getAdMobStatus() async {
    try {
      final data = await _get('/settings/admob-status');
      return data['enabled'] ?? true;
    } catch (e) {
      debugPrint('Error fetching AdMob status: $e');
      return true;
    }
  }

  /// Get ads frequency (number of tasks between ads)
  Future<int> getAdsFrequency() async {
    try {
      final data = await _get('/settings/ads-frequency');
      return data['frequency'] ?? 3;
    } catch (e) {
      debugPrint('Error fetching ads frequency: $e');
      return 3;
    }
  }

  // Support
  Future<void> sendSupportMessage({required String subject, required String message}) async {
    try {
      await _dio.post('/support/tickets', data: {
        'subject': subject, 
        'message': message,
      });
    } catch (e) {
      debugPrint('ApiService: Error sending support message: $e');
      rethrow;
    }
  }
}


class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? code;

  ApiException(this.message, this.statusCode, {this.code});

  /// Returns a user-friendly error message suitable for display in the UI.
  String get userFriendlyMessage {
    // Map specific error codes to friendly messages
    switch (code) {
      case 'OFFER_ACCEPTANCE_FAILED':
        if (statusCode == 402) {
          return 'Insufficient wallet balance. Please top up your wallet to continue.';
        }
        return 'Could not accept this offer. Please try again.';
      case 'ESCROW_CREATION_FAILED':
        return 'Could not secure payment. Please check your wallet balance.';
      case 'VERIFICATION_REQUIRED':
        return 'Identity verification required. Please verify your account first.';
      case 'INVENTORY_REQUIRED':
        return 'You need registered equipment to bid on this task.';
      case 'ACTIVE_JOB_RESTRICTION':
        return 'Complete your current job before bidding on urgent tasks.';
      default:
        break;
    }
    
    // Map status codes to friendly messages
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        // Use the backend message if it's more specific than 'Unauthorized'
        if (message != 'Unauthorized' && message.isNotEmpty && !message.contains('Network error')) {
          return message;
        }
        return 'Session expired. Please log in again.';
      case 402:
        return 'Insufficient wallet balance. Please top up your wallet.';
      case 403:
        return 'You don\'t have permission for this action.';
      case 404:
        return 'The requested item was not found.';
      case 500:
        return 'Something went wrong. Please try again later.';
      default:
        // If we have a clean backend message, use it
        if (!message.contains('ERROR:') && !message.contains('SQLSTATE')) {
          return message;
        }
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() => 'ApiException: $message (Code: $code, Status: $statusCode)';
}
