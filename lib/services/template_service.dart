import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_template_model.dart';
import '../models/template_element_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class TemplateService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<CardTemplate>> getTemplates() async {
    try {
      final response = await _supabase
          .from('templates')
          .select()
          .order('name');

      return (response as List).map((json) => CardTemplate.fromJson(json)).toList();
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

      return CardTemplate.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching template: $e');
      return null;
    }
  }

  Future<List<TemplateElement>> getTemplateElements(String templateId) async {
    try {
      final response = await _supabase
          .from('template_elements')
          .select()
          .eq('template_id', templateId)
          .order('created_at');

      return (response as List).map((json) => TemplateElement.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching template elements: $e');
      return [];
    }
  }

  Future<TemplateCustomization?> getTemplateCustomization(String cardId, String templateId) async {
    try {
      final response = await _supabase
          .from('template_customizations')
          .select()
          .eq('card_id', cardId)
          .eq('template_id', templateId)
          .single();

      return TemplateCustomization.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching template customization: $e');
      return null;
    }
  }

  Future<void> saveTemplateCustomization(TemplateCustomization customization) async {
    try {
      await _supabase
          .from('template_customizations')
          .upsert(customization.toJson());
    } catch (e) {
      debugPrint('Error saving template customization: $e');
      rethrow;
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

  Future<void> createTemplate(CardTemplate template) async {
    try {
      await _supabase
          .from('templates')
          .insert(template.toJson());
    } catch (e) {
      debugPrint('Error creating template: $e');
      rethrow;
    }
  }

  Future<void> updateTemplate(CardTemplate template) async {
    try {
      await _supabase
          .from('templates')
          .update(template.toJson())
          .eq('id', template.id);
    } catch (e) {
      debugPrint('Error updating template: $e');
      rethrow;
    }
  }

  Future<void> deleteTemplate(String templateId) async {
    try {
      await _supabase
          .from('templates')
          .delete()
          .eq('id', templateId);
    } catch (e) {
      debugPrint('Error deleting template: $e');
      rethrow;
    }
  }
} 