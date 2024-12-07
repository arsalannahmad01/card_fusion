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

    final errorStr = error.toString().toLowerCase();

    // Handle Postgrest/Database errors
    if (errorStr.contains('postgrest') || errorStr.contains('relation')) {
      if (errorStr.contains('valid_email')) {
        return AppError(
          message: 'Please enter a valid email address',
          type: ErrorType.validation,
          originalError: error,
          stackTrace: stackTrace,
        );
      }
      
      if (errorStr.contains('unique') || errorStr.contains('already exists')) {
        return AppError(
          message: 'This record already exists',
          type: ErrorType.database,
          originalError: error,
          stackTrace: stackTrace,
        );
      }

      if (errorStr.contains('foreign key') || errorStr.contains('references')) {
        return AppError(
          message: 'Referenced record does not exist',
          type: ErrorType.database,
          originalError: error,
          stackTrace: stackTrace,
        );
      }

      if (errorStr.contains('check constraint')) {
        return AppError(
          message: 'Invalid data format',
          type: ErrorType.validation,
          originalError: error,
          stackTrace: stackTrace,
        );
      }

      return AppError(
        message: 'Database error occurred',
        type: ErrorType.database,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException')) {
      return AppError(
        message: 'Network connection error',
        type: ErrorType.network,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return AppError(
      message: error.toString(),
      type: ErrorType.unknown,
      originalError: error,
      stackTrace: stackTrace,
    );
  }
} 