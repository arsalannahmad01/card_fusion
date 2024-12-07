import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'app_error.dart';

class ErrorDisplay {
  static void showError(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getErrorIcon(error.type), color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(error.message)),
          ],
        ),
        backgroundColor: _getErrorColor(error.type),
      ),
    );
  }

  static IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network: return Icons.wifi_off;
      case ErrorType.authentication: return Icons.security;
      case ErrorType.permission: return Icons.no_accounts;
      case ErrorType.capture: return Icons.image_not_supported;
      case ErrorType.sharing: return Icons.share;
      case ErrorType.storage: return Icons.storage;
      case ErrorType.database: return Icons.data_array;
      case ErrorType.analytics: return Icons.analytics;
      case ErrorType.template: return Icons.style;
      case ErrorType.scan: return Icons.qr_code_scanner;
      case ErrorType.validation: return Icons.error_outline;
      case ErrorType.unknown: return Icons.error_outline;
    }
  }

  static Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network: return Colors.orange;
      case ErrorType.authentication: return Colors.red;
      case ErrorType.permission: return Colors.red;
      case ErrorType.capture: return AppColors.secondary;
      case ErrorType.sharing: return AppColors.primary;
      case ErrorType.storage: return Colors.purple;
      case ErrorType.database: return Colors.indigo;
      case ErrorType.analytics: return Colors.blue;
      case ErrorType.template: return Colors.teal;
      case ErrorType.scan: return Colors.green;
      case ErrorType.validation: return Colors.orange;
      case ErrorType.unknown: return Colors.red;
    }
  }
} 