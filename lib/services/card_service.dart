import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:io';
import 'dart:typed_data' show Uint8List;

class CardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<DigitalCard>> getCards() async {
    try {
      final response = await _supabase
          .from('digital_cards')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('created_at');

      return (response as List)
          .map((json) => DigitalCard.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching cards: $e');
      return [];
    }
  }

  Future<DigitalCard> createCard(DigitalCard card) async {
    final response = await _supabase
        .from('digital_cards')
        .insert(card.toJson())
        .select()
        .single();

    return DigitalCard.fromJson(response);
  }

  Future<DigitalCard> updateCard(DigitalCard card) async {
    final response = await _supabase
        .from('digital_cards')
        .update(card.toJson())
        .eq('id', card.id)
        .select()
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

      debugPrint('Image uploaded successfully: $imageUrl');
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

      final cards =
          await _supabase.from('digital_cards').select().in_('id', cardIds);

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
      debugPrint('Current user ID: $currentUserId');

      // First get all cards to debug
      var card = await _supabase
          .from('digital_cards')
          .select('id')
          .neq('user_id', currentUserId)
          .order('created_at', ascending: false)
          .limit(1);

      print('Card: $card');

    

      final cardId = card[0]['id'] as String;
      return cardId;
    } catch (e) {
      debugPrint('Error getting random card: $e');
      return null;
    }
  }
}
