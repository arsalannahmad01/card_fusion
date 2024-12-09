import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:typed_data' show Uint8List;
import '../utils/error_handler.dart';

class CardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<DigitalCard>> getCards() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw AppError(
          message: 'You must be signed in to view cards',
          type: ErrorType.authentication,
        );
      }

      final response = await _supabase
          .from('digital_cards')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DigitalCard.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to load cards',
        type: ErrorType.database,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<DigitalCard?> getCardById(String cardId) async {
    try {
      final response = await _supabase.from('digital_cards').select('''
            *,
            template:templates(
              id,
              name,
              type,
              supported_card_types,
              styles,
              preview_image,
              front_layout,
              back_layout,
              created_at,
              updated_at
            )
          ''').eq('id', cardId).single();

      return DigitalCard.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching card: $e');
      return null;
    }
  }

  Future<DigitalCard> createCard(DigitalCard card) async {
    debugPrint('Creating card in service: ${card.toJson()}');
    final cardData = card.toJson();
    // Remove any fields that might not exist in the database
    cardData.remove('shares');
    cardData.remove('views');
    // Ensure image URL is properly set
    if (cardData['user_image_url'] != null && cardData['user_image_url'].isEmpty) {
      cardData.remove('user_image_url');
    }

    try {
      final response = await _supabase
          .from('digital_cards')
          .insert(cardData)
          .select()
          .single();

      debugPrint('Card creation response: $response');
      return DigitalCard.fromJson(response);
    } catch (e) {
      debugPrint('Error in createCard: $e');
      rethrow;
    }
  }

  Future<DigitalCard> updateCard(DigitalCard card) async {
    final cardData = card.toJson();
    cardData.remove('shares');
    cardData.remove('views');
    if (cardData['user_image_url'] != null && cardData['user_image_url'].isEmpty) {
      cardData.remove('user_image_url');
    }

    try {
      final response = await _supabase
          .from('digital_cards')
          .update(cardData)
          .eq('id', card.id)
          .select()
          .single();

      return DigitalCard.fromJson(response);
    } catch (e) {
      debugPrint('Error updating card: $e');
      rethrow;
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw AppError(
          message: 'You must be signed in to delete cards',
          type: ErrorType.authentication,
        );
      }

      // First delete from saved_cards (references)
      await _supabase
          .from('saved_cards')
          .delete()
          .eq('card_id', cardId);

      // Then delete analytics
      await _supabase
          .from('card_analytics')
          .delete()
          .eq('card_id', cardId);

      // Finally delete the card itself
      await _supabase
          .from('digital_cards')
          .delete()
          .eq('id', cardId)
          .eq('user_id', userId);  // Ensure user owns the card

      debugPrint('Card and related data deleted successfully');
    } catch (e) {
      debugPrint('Error deleting card: $e');
      rethrow;
    }
  }

  Future<List<DigitalCard>> searchCards({
    String? query,
    CardType? type,
    String? companyName,
  }) async {
    try {
      var queryBuilder = _supabase.from('digital_cards').select();

      // If searching by ID, use exact match
      if (query?.length == 36) {
        // UUID length
        queryBuilder = queryBuilder.eq('id', query);
      } else if (query != null && query.isNotEmpty) {
        queryBuilder =
            queryBuilder.or('name.ilike.%$query%,email.ilike.%$query%');
      }

      if (type != null) {
        queryBuilder = queryBuilder.eq('type', type.name);
      }

      if (companyName != null && companyName.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('company_name', '%$companyName%');
      }

      final response = await queryBuilder.order('created_at');

      return (response as List)
          .map((json) => DigitalCard.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching cards: $e');
      return [];
    }
  }

  Future<String> uploadImage(String fileName, Uint8List bytes) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final path = 'user_$userId/$fileName';

      await _supabase.storage.from('card_images').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final imageUrl = _supabase.storage.from('card_images').getPublicUrl(path);

      return imageUrl;
    } catch (e) {
      debugPrint('Error in uploadImage: $e');
      rethrow;
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final path = imageUrl.split('card_images/').last;
      await _supabase.storage.from('card_images').remove([path]);
    } catch (e) {
      debugPrint('Error deleting image: $e');
      rethrow;
    }
  }

  Future<String?> getTestCardId() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('digital_cards')
          .select('id')
          .eq('user_id', userId)
          .limit(1)
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Error getting test card: $e');
      return null;
    }
  }

  Future<List<DigitalCard>> getSavedCards() async {
    try {
      final response = await _supabase
          .from('saved_cards')
          .select('''
            digital_cards!card_id (
              *,
              templates!template_id (
                id,
                name,
                type,
                front_markup,
                back_markup,
                styles,
                supported_card_types,
                preview_image
              )
            )
          ''')
          .eq('user_id', _supabase.auth.currentUser!.id);

      debugPrint('Saved cards response: $response');

      return (response as List)
          .where((json) => json['digital_cards'] != null)
          .map((json) => DigitalCard.fromJson(json['digital_cards']))
          .toList();
    } catch (e) {
      debugPrint('Error fetching saved cards: $e');
      return [];
    }
  }

  Future<void> saveCard(String cardId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw AppError(
          message: 'You must be signed in to save cards',
          type: ErrorType.authentication,
        );
      }

      // First check if card is already saved
      final existing = await _supabase
          .from('saved_cards')
          .select()
          .match({
            'card_id': cardId,
            'user_id': userId,
          })
          .maybeSingle();

      if (existing != null) {
        throw AppError(
          message: 'Card is already saved',
          type: ErrorType.validation,
        );
      }

      // Create a new entry in saved_cards table
      await _supabase.from('saved_cards').insert({
        'card_id': cardId,
        'user_id': userId,
        'saved_at': DateTime.now().toIso8601String(),
        'notes': '',
        'tags': [],
      });

      debugPrint('Card saved successfully: $cardId');

    } catch (e, stackTrace) {
      debugPrint('Error saving card: $e');
      if (e is AppError) rethrow;
      throw AppError(
        message: 'Failed to save card',
        type: ErrorType.database,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> removeSavedCard(String cardId) async {
    try {
      // Remove from saved_cards table in database
      await _supabase.from('saved_cards').delete().match({
        'card_id': cardId,
        'user_id': _supabase.auth.currentUser!.id,
      });

      // Also remove from digital_cards if it's a saved card (not owned by user)
      final card = await _supabase
          .from('digital_cards')
          .select()
          .eq('id', cardId)
          .single();

      if (card['user_id'] != _supabase.auth.currentUser!.id) {
        await _supabase.from('digital_cards').delete().match({
          'id': cardId,
          'user_id': _supabase.auth.currentUser!.id,
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error removing saved card: $e');
      throw AppError(
        message: 'Failed to remove saved card',
        type: ErrorType.database,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<String?> getRandomCardForTesting() async {
    try {
      final currentUserId = _supabase.auth.currentUser!.id;

      // First get all cards to debug
      var card = await _supabase
          .from('digital_cards')
          .select('id')
          .neq('user_id', currentUserId)
          .order('created_at', ascending: false)
          .limit(1);

      final cardId = card[0]['id'] as String;
      return cardId;
    } catch (e) {
      debugPrint('Error getting random card: $e');
      return null;
    }
  }

  Future<List<DigitalCard>> getUserCards() async {
    try {
      final response = await _supabase
          .from('digital_cards')
          .select('''
            *,
            templates:template_id (
              id,
              name,
              type,
              front_markup,
              back_markup,
              styles,
              supported_card_types
            )
          ''')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('created_at');

      return (response as List)
          .map((json) => DigitalCard.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user cards: $e');
      rethrow;
    }
  }
}
