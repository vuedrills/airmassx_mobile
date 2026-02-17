import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
      return 'Unable to connect to server. Please check your internet.';
    }

    if (error.type == DioExceptionType.badResponse) {
        final statusCode = error.response?.statusCode;
        
        if (statusCode != null) {
          if (statusCode >= 500) {
            return 'Server error. We are working to fix it.';
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
          
          // Try to extract a message from the response body if it's a 400 or similar
          final data = error.response?.data;
          if (data is Map<String, dynamic> && data.containsKey('message')) {
             return data['message'].toString();
          }
          if (data is Map<String, dynamic> && data.containsKey('error')) {
             return data['error'].toString();
          }
        }
    }
    
    if (error.error is SocketException) {
        return 'No internet connection.';
    }

    return 'Network error. Please try again.';
  }
}
