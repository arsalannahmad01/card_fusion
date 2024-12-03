import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_template_model.dart';
import '../models/card_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class TemplateService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<CardTemplate>> getTemplates() async {
    try {
      final response = await _supabase
          .from('templates')
          .select()
          .order('name');

      return (response as List).map((json) {
        return CardTemplate(
          id: json['id'],
          name: json['name'],
          type: TemplateType.values.byName(json['type']),
          supportedCardTypes: (json['supported_card_types'] as List)
              .map((t) => CardType.values.byName(t.toString()))
              .toList(),
          styles: Map<String, dynamic>.from(json['styles']),
          previewImage: json['preview_image'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching templates: $e');
      return [];
    }
  }

  Future<CardTemplate?> getTemplateById(String templateId) async {
    try {
      final response = await _supabase
          .from('templates')
          .select()
          .eq('id', templateId)
          .single();

      return CardTemplate(
        id: response['id'],
        name: response['name'],
        type: TemplateType.values.byName(response['type']),
        supportedCardTypes: (response['supported_card_types'] as List)
            .map((t) => CardType.values.byName(t.toString()))
            .toList(),
        styles: Map<String, dynamic>.from(response['styles']),
        previewImage: response['preview_image'],
      );
    } catch (e) {
      debugPrint('Error fetching template: $e');
      return null;
    }
  }

  Future<void> applyTemplate(String cardId, String templateId) async {
    try {
      await _supabase
          .from('digital_cards')
          .update({'template_id': templateId})
          .eq('id', cardId);
    } catch (e) {
      debugPrint('Error applying template: $e');
      rethrow;
    }
  }
} 