import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;

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
      cardName: json['card_name'],
      cardType: json['card_type'],
      totalScans: json['total_scans'] ?? 0,
      totalSaves: json['total_saves'] ?? 0,
      totalViews: json['total_views'] ?? 0,
      uniqueScanners: json['unique_scanners'] ?? 0,
      lastInteraction: DateTime.parse(json['last_interaction']),
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
  final String? city;
  final String? country;
  final String source;
  final bool isTestScan;
  final Map<String, dynamic>? location;

  ScanDetails({
    required this.deviceType,
    required this.platform,
    this.city,
    this.country,
    required this.source,
    this.isTestScan = false,
    this.location,
  });

  Map<String, dynamic> toJson() => {
    'device_type': deviceType,
    'platform': platform,
    'city': city,
    'country': country,
    'source': source,
    'is_test_scan': isTestScan,
    'location': location,
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
      if (ownerId == null) return;

      await _supabase.from('card_analytics').insert({
        'card_id': cardId,
        'owner_id': ownerId,
        'scanner_id': scannerId ?? _supabase.auth.currentUser?.id,
        'event_type': eventType.name,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      debugPrint('Error tracking analytics event: $e');
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

  Future<CardAnalytics?> getCardAnalytics(String cardId) async {
    try {
      debugPrint('Fetching analytics for card: $cardId');
      final response = await _supabase
          .from('card_analytics_summary')
          .select()
          .eq('card_id', cardId)
          .single();
      debugPrint('Analytics response: $response');
      return CardAnalytics.fromJson(response);
    } catch (e) {
      debugPrint('Error getting card analytics: $e');
      return null;
    }
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
      debugPrint('Recording scan - Card ID: $cardId, Owner ID: $ownerId');
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
        'location': details.location != null ? {'address': details.location} : null,
        'scan_source': details.source,
        'created_at': DateTime.now().toIso8601String(),
      };
      debugPrint('Analytics data to insert: $data');

      await _supabase.from('card_analytics').insert(data);
      debugPrint('Analytics recorded successfully');
    } catch (e) {
      debugPrint('Error recording scan: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDetailedAnalytics(String cardId) async {
    try {
      debugPrint('Fetching detailed analytics for card: $cardId');
      final response = await _supabase
          .from('card_analytics_details')
          .select()
          .eq('card_id', cardId)
          .order('created_at', ascending: false)
          .limit(50);
      
      debugPrint('Detailed analytics response: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting detailed analytics: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTimeSeriesAnalytics(String cardId) async {
    try {
      final response = await _supabase
          .from('card_analytics_time_series')
          .select()
          .eq('card_id', cardId)
          .order('date');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting time series analytics: $e');
      return [];
    }
  }
} 