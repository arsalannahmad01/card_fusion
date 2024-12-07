import 'package:flutter/material.dart';
import '../config/theme.dart';

enum ErrorType {
  network,
  authentication,
  permission,
  capture,
  sharing,
  storage,
  database,
  analytics,
  template,
  scan,
  validation,
  unknown
}

class AppError {
  final String message;
  final ErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError({
    required this.message,
    required this.type,
    this.originalError,
    this.stackTrace,
  });

  static AppError handleError(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppError) return error;

    // Network errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException')) {
      return AppError(
        message: 'Network connection error. Please check your internet connection.',
        type: ErrorType.network,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Authentication errors
    if (error.toString().contains('authentication') ||
        error.toString().contains('AuthException')) {
      return AppError(
        message: 'Authentication error. Please sign in again.',
        type: ErrorType.authentication,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Permission errors
    if (error.toString().contains('Permission')) {
      return AppError(
        message: 'Permission denied. Please check app permissions.',
        type: ErrorType.permission,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Card capture errors
    if (error.toString().contains('capture')) {
      return AppError(
        message: 'Failed to capture card image. Please try again.',
        type: ErrorType.capture,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Sharing errors
    if (error.toString().contains('share')) {
      return AppError(
        message: 'Failed to share card. Please try again.',
        type: ErrorType.sharing,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Storage errors
    if (error.toString().contains('storage') ||
        error.toString().contains('file')) {
      return AppError(
        message: 'Storage error. Please check device storage.',
        type: ErrorType.storage,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Default unknown error
    return AppError(
      message: 'An unexpected error occurred. Please try again.',
      type: ErrorType.unknown,
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}

class ErrorDisplay {
  static void showError(BuildContext context, AppError error) {
    debugPrint('Error: ${error.message}');
    debugPrint('Original error: ${error.originalError}');
    if (error.stackTrace != null) {
      debugPrint('Stack trace: ${error.stackTrace}');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(error.type),
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _getErrorColor(error.type),
        duration: const Duration(seconds: 4),
        action: error.type == ErrorType.network
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  // Implement retry logic
                },
              )
            : null,
      ),
    );
  }

  static IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.security;
      case ErrorType.permission:
        return Icons.no_accounts;
      case ErrorType.capture:
        return Icons.image_not_supported;
      case ErrorType.sharing:
        return Icons.share;
      case ErrorType.storage:
        return Icons.storage;
      case ErrorType.database:
        return Icons.data_array;
      case ErrorType.analytics:
        return Icons.analytics;
      case ErrorType.template:
        return Icons.style;
      case ErrorType.scan:
        return Icons.qr_code_scanner;
      case ErrorType.validation:
        return Icons.error_outline;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }

  static Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.authentication:
        return Colors.red;
      case ErrorType.permission:
        return Colors.red;
      case ErrorType.capture:
        return AppColors.secondary;
      case ErrorType.sharing:
        return AppColors.primary;
      case ErrorType.storage:
        return Colors.purple;
      case ErrorType.database:
        return Colors.indigo;
      case ErrorType.analytics:
        return Colors.blue;
      case ErrorType.template:
        return Colors.teal;
      case ErrorType.scan:
        return Colors.green;
      case ErrorType.validation:
        return Colors.orange;
      case ErrorType.unknown:
        return Colors.red;
    }
  }
} 