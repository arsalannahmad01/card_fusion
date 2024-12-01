import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ScanService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> recordScan({
    required String cardId,
    required String scannerUserId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.from('card_scans').insert({
        'card_id': cardId,
        'scanner_user_id': scannerUserId,
        'metadata': metadata,
        'scanned_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error recording scan: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getScans(String cardId) async {
    try {
      final response = await _supabase
          .from('card_scans')
          .select()
          .eq('card_id', cardId)
          .order('scanned_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching scans: $e');
      return [];
    }
  }
} 