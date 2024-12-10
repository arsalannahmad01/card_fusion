import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../utils/error_handler.dart';

enum CardAnalyticEvent {
  scan,
  save,
  view,
  share
}

class CardAnalytics {
  final String cardId;
  final String cardName;
  final String cardType;
  final int totalScans;
  final int totalSaves;
  final int totalViews;
  final int uniqueScanners;
  final DateTime lastInteraction;
  final int uniqueCities;
  final int uniqueCountries;
  final Map<String, int> scansByCity;
  final Map<String, dynamic> lastScanDetails;

  CardAnalytics({
    required this.cardId,
    required this.cardName,
    required this.cardType,
    required this.totalScans,
    required this.totalSaves,
    required this.totalViews,
    required this.uniqueScanners,
    required this.lastInteraction,
    required this.uniqueCities,
    required this.uniqueCountries,
    required this.scansByCity,
    required this.lastScanDetails,
  });

  factory CardAnalytics.fromJson(Map<String, dynamic> json) {
    return CardAnalytics(
      cardId: json['card_id'],
      cardName: json['card_name'] ?? 'Unknown',
      cardType: json['card_type'] ?? 'Unknown',
      totalScans: json['total_scans'] ?? 0,
      totalSaves: json['total_saves'] ?? 0,
      totalViews: json['total_views'] ?? 0,
      uniqueScanners: json['unique_scanners'] ?? 0,
      lastInteraction: json['last_interaction'] != null 
        ? DateTime.parse(json['last_interaction'])
        : DateTime.now(),
      uniqueCities: json['unique_cities'] ?? 0,
      uniqueCountries: json['unique_countries'] ?? 0,
      scansByCity: Map<String, int>.from(json['scans_by_city'] ?? {}),
      lastScanDetails: json['last_scan_details'] ?? {},
    );
  }
}

class ScanDetails {
  final String deviceType;
  final String platform;
  final String source;
  final String? city;
  final String? country;
  final Map<String, dynamic>? location;
  final bool isTestScan;

  ScanDetails({
    required this.deviceType,
    required this.platform,
    required this.source,
    this.city,
    this.country,
    this.location,
    this.isTestScan = false,
  });

  Map<String, dynamic> toJson() => {
    'device_type': deviceType,
    'platform': platform,
    'source': source,
    'city': city,
    'country': country,
    'location': location,
    'is_test_scan': isTestScan,
  };
}

class AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> trackEvent({
    required String cardId,
    required CardAnalyticEvent eventType,
    String? scannerId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final ownerId = await _getCardOwnerId(cardId);
      if (ownerId == null) {
        throw AppError(
          message: 'Card not found',
          type: ErrorType.analytics,
        );
      }

      await _supabase.from('card_analytics').insert({
        'card_id': cardId,
        'owner_id': ownerId,
        'scanner_user_id': scannerId ?? _supabase.auth.currentUser?.id,
        'event_type': eventType.name,
        'device_info': {
          'type': metadata?['device_type'] ?? 'web',
          'platform': metadata?['platform'] ?? 'web',
        },
        'scan_source': metadata?['source'] ?? 'direct',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e, stackTrace) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to track analytics event',
        type: ErrorType.analytics,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<String?> _getCardOwnerId(String cardId) async {
    try {
      final response = await _supabase
          .from('digital_cards')
          .select('user_id')
          .eq('id', cardId)
          .single();
      return response['user_id'] as String;
    } catch (e) {
      debugPrint('Error getting card owner: $e');
      return null;
    }
  }

  Future<List<CardAnalytics>> getCardAnalytics(String cardId) async {
    try {
      debugPrint('Fetching analytics for card: $cardId');
      final cardDetails = await _supabase
          .from('digital_cards')
          .select('id, name, type')
          .eq('id', cardId)
          .single();

      final response = await _supabase
          .from('card_analytics')
          .select('''
            id,
            card_id,
            event_type,
            city,
            country,
            device_info,
            location,
            scan_source,
            created_at,
            scanner_user_id
          ''')
          .eq('card_id', cardId)
          .order('created_at', ascending: false);

      debugPrint('Analytics response length: ${(response as List).length}');
      if (response.isEmpty) return [];
      
      final summary = {
        'card_id': cardId,
        'card_name': cardDetails['name'],
        'card_type': cardDetails['type'],
        'total_scans': response.where((r) => r['event_type'] == 'scan').length,
        'total_views': response.where((r) => r['event_type'] == 'view').length,
        'total_saves': response.where((r) => r['event_type'] == 'save').length,
        'unique_scanners': response.map((r) => r['scanner_user_id']).toSet().length,
        'last_interaction': response.first['created_at'],
        'unique_cities': response.map((r) => r['city']).where((c) => c != null).toSet().length,
        'unique_countries': response.map((r) => r['country']).where((c) => c != null).toSet().length,
        'scans_by_city': _calculateScansByCity(response),
        'last_scan_details': response.first,
      };

      debugPrint('Created summary: $summary');
      return [CardAnalytics.fromJson(summary)];
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
      return [];
    }
  }

  Map<String, int> _calculateScansByCity(List<dynamic> records) {
    final Map<String, int> scansByCity = {};
    for (var record in records) {
      final city = record['city']?.toString() ?? 'Unknown';
      scansByCity[city] = (scansByCity[city] ?? 0) + 1;
    }
    return scansByCity;
  }

  Future<List<CardAnalytics>> getMyCardsAnalytics() async {
    try {
      final response = await _supabase
          .from('card_analytics_summary')
          .select()
          .eq('owner_id', _supabase.auth.currentUser!.id);
      
      return (response as List)
          .map((json) => CardAnalytics.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting cards analytics: $e');
      return [];
    }
  }

  Future<void> recordScan({
    required String cardId,
    required CardAnalyticEvent eventType,
    String? scannerId,
    required ScanDetails details,
  }) async {
    try {
      final ownerId = await _getCardOwnerId(cardId);
      if (ownerId == null) return;

      final data = {
        'card_id': cardId,
        'owner_id': ownerId,
        'scanner_user_id': scannerId ?? _supabase.auth.currentUser?.id,
        'event_type': eventType.name,
        'device_info': {
          'type': details.deviceType,
          'platform': details.platform,
        },
        'city': details.city,
        'country': details.country,
        'location': details.location,
        'scan_source': details.source,
        'created_at': DateTime.now().toIso8601String(),
      };

      debugPrint('Recording analytics with location data: ${details.city}, ${details.country}');
      await _supabase.from('card_analytics').insert(data);
      debugPrint('Analytics recorded successfully');
    } catch (e) {
      debugPrint('Error recording scan: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDetailedAnalytics(
    String cardId, {
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _supabase
          .from('card_analytics_details')
          .select()
          .eq('card_id', cardId)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }
      
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 50) - 1);
      }
      
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting detailed analytics: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTimeSeriesAnalytics(String cardId) async {
    try {
      final response = await _supabase
          .from('card_analytics')
          .select('created_at, event_type')
          .eq('card_id', cardId)
          .order('created_at');

      final data = List<Map<String, dynamic>>.from(response);
      if (data.isEmpty) return [];

      // Calculate date range
      final firstDate = DateTime.parse(data.first['created_at']);
      final lastDate = DateTime.parse(data.last['created_at']);
      final diffInDays = lastDate.difference(firstDate).inDays;

      // Determine interval based on date range
      if (diffInDays == 0) {
        // Single day - group by hours
        return _groupByHours(data);
      } else if (diffInDays <= 7) {
        // Week or less - group by days
        return _groupByDays(data);
      } else if (diffInDays <= 30) {
        // Month or less - group by weeks
        return _groupByWeeks(data);
      } else {
        // More than a month - group by months
        return _groupByMonths(data);
      }
    } catch (e) {
      debugPrint('Error getting time series analytics: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _groupByHours(List<Map<String, dynamic>> data) {
    final Map<String, int> hourlyData = {};
    
    for (var record in data) {
      final date = DateTime.parse(record['created_at']);
      final hour = DateTime(date.year, date.month, date.day, date.hour);
      final key = hour.toIso8601String();
      hourlyData[key] = (hourlyData[key] ?? 0) + 1;
    }

    return hourlyData.entries.map((e) => {
      'date': e.key,
      'count': e.value,
    }).toList()..sort((a, b) => 
      (a['date'] as String).compareTo(b['date'] as String)
    );
  }

  List<Map<String, dynamic>> _groupByDays(List<Map<String, dynamic>> data) {
    final Map<String, int> dailyData = {};
    
    for (var record in data) {
      final date = DateTime.parse(record['created_at']);
      final day = DateTime(date.year, date.month, date.day);
      final key = day.toIso8601String();
      dailyData[key] = (dailyData[key] ?? 0) + 1;
    }

    return dailyData.entries.map((e) => {
      'date': e.key,
      'count': e.value,
    }).toList()..sort((a, b) => 
      (a['date'] as String).compareTo(b['date'] as String)
    );
  }

  List<Map<String, dynamic>> _groupByWeeks(List<Map<String, dynamic>> data) {
    final Map<String, int> weeklyData = {};
    
    for (var record in data) {
      final date = DateTime.parse(record['created_at']);
      // Get start of week
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      final key = DateTime(weekStart.year, weekStart.month, weekStart.day).toIso8601String();
      weeklyData[key] = (weeklyData[key] ?? 0) + 1;
    }

    return weeklyData.entries.map((e) => {
      'date': e.key,
      'count': e.value,
    }).toList()..sort((a, b) => 
      (a['date'] as String).compareTo(b['date'] as String)
    );
  }

  List<Map<String, dynamic>> _groupByMonths(List<Map<String, dynamic>> data) {
    final Map<String, int> monthlyData = {};
    
    for (var record in data) {
      final date = DateTime.parse(record['created_at']);
      final month = DateTime(date.year, date.month);
      final key = month.toIso8601String();
      monthlyData[key] = (monthlyData[key] ?? 0) + 1;
    }

    return monthlyData.entries.map((e) => {
      'date': e.key,
      'count': e.value,
    }).toList()..sort((a, b) => 
      (a['date'] as String).compareTo(b['date'] as String)
    );
  }
} 