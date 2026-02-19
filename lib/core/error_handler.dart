import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../services/api_service.dart';

class ErrorHandler {
  /// Converts complex/verbose exceptions into user-friendly messages.
  /// Logs the full error for debugging purposes.
  static String getUserFriendlyMessage(dynamic error) {
    // Log the full error for developers
    debugPrint('ErrorHandler caught: $error');
    if (error is Error) {
       debugPrint('Stack trace: ${error.stackTrace}');
    }

    // Report to Sentry in non-debug mode (or always if configured)
    if (!kDebugMode) {
      Sentry.captureException(
        error, 
        stackTrace: error is Error ? error.stackTrace : null,
      );
    }

    if (error is ApiException) {
      return error.userFriendlyMessage;
    }

    if (error is DioException) {
      return _handleDioError(error);
    }
    
    if (error is PlatformException) {
      final message = error.message?.toLowerCase() ?? '';
      if (message.contains('network') || message.contains('connection lost')) {
        return 'Connection lost. Please check your internet.';
      }
      if (message.contains('cancel')) {
        return 'Sign-in cancelled.';
      }
      return 'An external service error occurred. Please try again.';
    }

    if (error is SocketException) {
      return 'No internet connection. Please check your network settings.';
    }

    if (error is FormatException) {
      return 'Data unavailable. Please try again later.';
    }

    // Default fallback
    return 'Something went wrong. Please try again.';
  }

  static String _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Please check your internet.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect. Please check your internet.';
    }

    if (error.type == DioExceptionType.badResponse) {
        final statusCode = error.response?.statusCode;
        
        if (statusCode != null) {
          if (statusCode >= 500) {
            return 'Something went wrong on our end. We are working to fix it.';
          }
          if (statusCode == 404) {
             return 'Resource not found.';
          }
          if (statusCode == 403) {
             return 'Access denied.';
          }
          if (statusCode == 401) {
             return 'Session expired. Please log in again.';
          }
          
          final data = error.response?.data;
          
          // Case 1: Standard 'message' field
          if (data is Map<String, dynamic> && data['message'] != null) {
             return data['message'].toString();
          }
          
          // Case 2: Standard 'error' field 
          if (data is Map<String, dynamic> && data['error'] != null) {
             return data['error'].toString();
          }

          // Case 3: Validation 'errors' map (Laravel/Rails style)
          // e.g. {"errors": {"password": ["Too short"]}}
          if (data is Map<String, dynamic> && data['errors'] is Map) {
            final errors = data['errors'] as Map;
            if (errors.isNotEmpty) {
              // Return the first error message found
              final firstKey = errors.keys.first;
              final firstValue = errors[firstKey];
              if (firstValue is List && firstValue.isNotEmpty) {
                return firstValue.first.toString();
              }
              return firstValue.toString();
            }
          }
          
          // Case 4: Raw string response
          if (data is String && data.isNotEmpty) {
            return data;
          }
        }
    }
    
    if (error.error is SocketException) {
        return 'No internet connection.';
    }

    return 'Network error. Please try again.';
  }
}
