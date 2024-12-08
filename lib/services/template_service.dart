import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_model.dart';
import '../models/card_template_model.dart';
import '../models/template_element_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../utils/app_error.dart';

class TemplateService {
  final _supabase = Supabase.instance.client;

  Future<List<CardTemplate>> getTemplates() async {
    try {
      debugPrint('Fetching templates from database...');
      final response = await _supabase
          .from('templates')
          .select('''
            id,
            name,
            type,
            front_markup,
            back_markup,
            styles,
            supported_card_types,
            preview_image
          ''')
          .order('created_at');
      
      debugPrint('Templates response: $response');
      final templates = (response as List).map((json) => CardTemplate.fromJson(json)).toList();
      debugPrint('Parsed ${templates.length} templates');
      return templates;
    } catch (e, stackTrace) {
      debugPrint('Error fetching templates: $e');
      debugPrint(stackTrace.toString());
      rethrow;  // Rethrow to handle in UI
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

  Future<DigitalCard> applyTemplate(String cardId, String templateId) async {
    try {
      // First get the complete template details
      final template = await _supabase
          .from('templates')
          .select('''
            id,
            name,
            type,
            front_markup,
            back_markup,
            styles,
            supported_card_types,
            preview_image
          ''')
          .eq('id', templateId)
          .single();

      // Update the card
      await _supabase
          .from('digital_cards')
          .update({
            'template_id': templateId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', cardId);

      // Get the updated card with complete template data
      final response = await _supabase
          .from('digital_cards')
          .select('''
            *,
            template:templates!template_id (
              id,
              name,
              type,
              front_markup,
              back_markup,
              styles,
              supported_card_types,
              preview_image
            )
          ''')
          .eq('id', cardId)
          .single();

      return DigitalCard.fromJson(response);
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

  Future<DigitalCard> createCardWithTemplate({
    required DigitalCard card,
    required String templateId,
  }) async {
    try {
      final template = await getTemplateById(templateId);
      if (template == null) {
        throw AppError(
          message: 'Template not found',
          type: ErrorType.database,
        );
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw AppError(
          message: 'User not authenticated',
          type: ErrorType.authentication,
        );
      }

      final response = await _supabase
          .from('digital_cards')
          .insert({
            'user_id': userId,
            'name': card.name,
            'email': card.email,
            'type': card.type.name,
            'job_title': card.jobTitle,
            'company_name': card.companyName,
            'phone': card.phone,
            'website': card.website,
            'template_id': templateId,
            'template_styles': template.styles,
          })
          .select()
          .single();

      return DigitalCard.fromJson(response);
    } catch (e) {
      debugPrint('Error creating card with template: $e');
      rethrow;
    }
  }
} 