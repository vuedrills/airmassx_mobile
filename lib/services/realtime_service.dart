import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:get_it/get_it.dart';
import '../services/api_service.dart';
import '../config/env.dart';

/// Service for handling WebSocket connections for realtime updates
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  WebSocketChannel? _channel;
  String? _currentToken;
  bool _isConnected = false;
  
  // Stream controllers for different event types
  final _offerCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _questionCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _taskUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _taskCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageReceivedController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  final _syncUnreadCountController = StreamController<void>.broadcast();
  final _walletUpdatedController = StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get offerCreated => _offerCreatedController.stream;
  Stream<Map<String, dynamic>> get questionCreated => _questionCreatedController.stream;
  Stream<Map<String, dynamic>> get taskUpdated => _taskUpdatedController.stream;
  Stream<Map<String, dynamic>> get taskCreated => _taskCreatedController.stream;
  Stream<Map<String, dynamic>> get messageReceived => _messageReceivedController.stream;
  Stream<Map<String, dynamic>> get notifications => _notificationController.stream;
  Stream<void> get syncUnreadCount => _syncUnreadCountController.stream;
  Stream<Map<String, dynamic>> get walletUpdated => _walletUpdatedController.stream;


  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  bool get isConnected => _isConnected;


  static String get _wsBaseUrl {
    final apiUrl = AppConfig.shared.apiUrl;
    if (apiUrl.startsWith('https')) {
      return apiUrl.replaceFirst('https', 'wss');
    } else {
      return apiUrl.replaceFirst('http', 'ws');
    }
  }

  /// Connect to WebSocket with auth token
  Future<void> connect(String token) async {
    if (_isConnected && _currentToken == token) {
      return; // Already connected with same token
    }

    // Disconnect existing connection
    await disconnect();

    _currentToken = token;
    final wsUrl = '$_wsBaseUrl/ws?token=$token';

    try {
      print('RealtimeService: Connecting to WebSocket...');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      _connectionStatusController.add(true);
      _resetReconnectCounter(); // Reset on successful connect

      // Listen for messages (non-blocking)
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      print('RealtimeService: Connected to WebSocket');
    } catch (e) {
      print('RealtimeService: Failed to connect: $e');
      _isConnected = false;
      // Don't throw - let login continue without realtime
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      print('RealtimeService: Received message type: $type');

      switch (type) {
        case 'offer_created':
          _offerCreatedController.add(data);
          break;
        case 'new_question':
        case 'question_created':
        case 'reply_created':
          _questionCreatedController.add(data);
          break;
        case 'task_created':
          _taskCreatedController.add(data);
          break;
        case 'task_updated':
        case 'task_status_changed':
          _taskUpdatedController.add(data);
          break;

        case 'new_message':
          _messageReceivedController.add(data);
          break;
        case 'new_notification':
          // Backend sends notifications wrapped in new_notification type
          // The actual notification data is in the 'message' field
          final notificationData = data['message'] as Map<String, dynamic>?;
          if (notificationData != null) {
            print('RealtimeService: Received new_notification: ${notificationData['type']}');
            _notificationController.add(notificationData);
          }
          break;
        case 'notification':
        case 'new_offer':
        case 'offer_accepted':
        case 'task_completed':
        case 'review_received':
          _notificationController.add(data);
          break;
        case 'wallet_updated':
          print('RealtimeService: Received wallet_updated event');
          _walletUpdatedController.add(data);
          break;
        default:
          print('RealtimeService: Unknown message type: $type');
      }
    } catch (e) {
      print('RealtimeService: Error parsing message: $e');
    }
  }

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;

  void _onError(Object error) {
    print('RealtimeService: WebSocket error: $error');
    _isConnected = false;
    _connectionStatusController.add(false);
    
    // Check if it's a 401 error - we might need to refresh
    final errorStr = error.toString();
    if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
      print('RealtimeService: Auth error noticed. Will attempt to get fresh token via scheduleReconnect.');
    }
    
    _scheduleReconnect();
  }

  void _onDone() {
    print('RealtimeService: WebSocket connection closed');
    _isConnected = false;
    _connectionStatusController.add(false);
    // Attempt to reconnect after a delay
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = Duration(seconds: 2 * _reconnectAttempts); // Exponential backoff starting faster
      print('RealtimeService: Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');
      
      _reconnectTimer = Timer(delay, () async {
        if (!_isConnected) {
          // Try to get fresh token from ApiService
          try {
            final apiService = GetIt.instance<ApiService>();
            final freshToken = apiService.accessToken;
            if (freshToken != null) {
              print('RealtimeService: Attempting reconnection with fresh token');
              await connect(freshToken);
            } else {
              print('RealtimeService: No token available for reconnection');
            }
          } catch (e) {
            print('RealtimeService: Error during reconnection: $e');
          }
        }
      });
    } else {
      print('RealtimeService: Max reconnect attempts reached');
      _reconnectAttempts = 0;
    }
  }

  /// Reset reconnection counter (call this on successful connect)
  void _resetReconnectCounter() {
    _reconnectAttempts = 0;
  }

  /// Subscribe to task updates (room-based)
  void subscribeToTask(String taskId) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'action': 'subscribe',
        'room': 'task_updates:$taskId',
      }));
      print('RealtimeService: Subscribed to task $taskId');
    }
  }

  /// Unsubscribe from task updates
  void unsubscribeFromTask(String taskId) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'action': 'unsubscribe',
        'room': 'task_updates:$taskId',
      }));
      print('RealtimeService: Unsubscribed from task $taskId');
    }
  }

  /// Subscribe to browse tasks (all new tasks)
  void subscribeToBrowseTasks() {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'action': 'subscribe',
        'room': 'browse_tasks',
      }));
    }
  }

  /// Subscribe to conversation messages
  void subscribeToConversation(String conversationId) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'action': 'subscribe',
        'room': 'conversation:$conversationId',
      }));
      print('RealtimeService: Subscribed to conversation $conversationId');
    }
  }

  /// Unsubscribe from conversation messages
  void unsubscribeFromConversation(String conversationId) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'action': 'unsubscribe',
        'room': 'conversation:$conversationId',
      }));
      print('RealtimeService: Unsubscribed from conversation $conversationId');
    }
  }

  /// Trigger a global sync of unread counts
  void triggerUnreadCountSync() {
    _syncUnreadCountController.add(null);
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _isConnected = false;
    _connectionStatusController.add(false);
    await _channel?.sink.close();
    _channel = null;
    _currentToken = null;
    print('RealtimeService: Disconnected');
  }

  /// Dispose of resources
  void dispose() {
    disconnect();
    _offerCreatedController.close();
    _questionCreatedController.close();
    _taskUpdatedController.close();
    _taskCreatedController.close();
    _messageReceivedController.close();
    _notificationController.close();
    _walletUpdatedController.close();
    _connectionStatusController.close();
  }

}
