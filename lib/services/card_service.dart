import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:io';
import 'dart:typed_data' show Uint8List;

class CardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<DigitalCard>> getCards() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return [];
      }

      debugPrint('Fetching cards for user: ${user.id}');
      final response = await _supabase
          .from('digital_cards')
          .select('''
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
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      debugPrint('Raw response: $response');
      
      if (response == null || response is! List) {
        debugPrint('Invalid response format: ${response.runtimeType}');
        return [];
      }

      final cards = <DigitalCard>[];
      for (final json in response) {
        try {
          debugPrint('Processing card: ${json['id']}');
          if (json['template'] != null) {
            debugPrint('Template data: ${json['template']}');
          }
          final card = DigitalCard.fromJson(json);
          cards.add(card);
        } catch (e, stackTrace) {
          debugPrint('Error parsing card ${json['id']}: $e');
          debugPrint('Card data: $json');
          debugPrint('Stack trace: $stackTrace');
        }
      }
          
      debugPrint('Successfully parsed ${cards.length} cards');
      return cards;
    } catch (e, stackTrace) {
      debugPrint('Error fetching cards: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<DigitalCard?> getCardById(String cardId) async {
    try {
      final response = await _supabase
          .from('digital_cards')
          .select('''
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
          ''')
          .eq('id', cardId)
          .single();

      return DigitalCard.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching card: $e');
      return null;
    }
  }

  Future<DigitalCard> createCard(DigitalCard card) async {
    final cardData = card.toJson();
    // Remove any fields that might not exist in the database
    cardData.remove('shares');
    cardData.remove('views');
    
    final response = await _supabase
        .from('digital_cards')
        .insert(cardData)
        .select('''
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
        ''')
        .single();

    return DigitalCard.fromJson(response);
  }

  Future<DigitalCard> updateCard(DigitalCard card) async {
    final cardData = card.toJson();
    // Remove any fields that might not exist in the database
    cardData.remove('shares');
    cardData.remove('views');
    
    final response = await _supabase
        .from('digital_cards')
        .update(cardData)
        .eq('id', card.id)
        .select('''
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
        ''')
        .single();

    return DigitalCard.fromJson(response);
  }

  Future<void> deleteCard(String cardId) async {
    await _supabase.from('digital_cards').delete().eq('id', cardId);
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
          .select('card_id')
          .eq('user_id', _supabase.auth.currentUser!.id);

      final cardIds =
          (response as List).map((r) => r['card_id'] as String).toList();

      if (cardIds.isEmpty) return [];

      final cards = await _supabase
          .from('digital_cards')
          .select('''
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
          ''')
          .in_('id', cardIds);

      return (cards as List).map((json) => DigitalCard.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching saved cards: $e');
      return [];
    }
  }

  Future<void> saveCard(String cardId) async {
    await _supabase.from('saved_cards').insert({
      'card_id': cardId,
      'user_id': _supabase.auth.currentUser!.id,
    });
  }

  Future<void> removeSavedCard(String cardId) async {
    await _supabase
        .from('saved_cards')
        .delete()
        .eq('card_id', cardId)
        .eq('user_id', _supabase.auth.currentUser!.id);
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
}
