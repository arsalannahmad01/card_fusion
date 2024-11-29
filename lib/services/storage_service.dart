import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/business_card.dart';
import '../models/card_category.dart';

class StorageService {
  static const String _cardsFileName = 'business_cards.json';
  static const String _categoriesFileName = 'categories.json';
  
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  // Card methods
  Future<List<BusinessCard>> loadCards() async {
    try {
      final file = await _getFile(_cardsFileName);
      if (!await file.exists()) {
        return [];
      }
      
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList.map((json) => BusinessCard.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveCards(List<BusinessCard> cards) async {
    final file = await _getFile(_cardsFileName);
    final jsonList = cards.map((card) => card.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }

  Future<void> saveCard(BusinessCard card) async {
    final cards = await loadCards();
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index >= 0) {
      cards[index] = card;
    } else {
      cards.add(card);
    }
    await saveCards(cards);
  }

  Future<void> deleteCard(String id) async {
    final cards = await loadCards();
    cards.removeWhere((card) => card.id == id);
    await saveCards(cards);

    // Remove card from all categories
    final categories = await loadCategories();
    for (var category in categories) {
      if (category.cardIds.contains(id)) {
        final updatedIds = category.cardIds.where((cardId) => cardId != id).toList();
        await updateCategoryCards(category.id, updatedIds);
      }
    }
  }

  // Category methods
  Future<List<CardCategory>> loadCategories() async {
    try {
      final file = await _getFile(_categoriesFileName);
      if (!await file.exists()) {
        return [];
      }
      
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList.map((json) => CardCategory.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveCategories(List<CardCategory> categories) async {
    final file = await _getFile(_categoriesFileName);
    final jsonList = categories.map((category) => category.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }

  Future<void> saveCategory(CardCategory category) async {
    final categories = await loadCategories();
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index >= 0) {
      categories[index] = category;
    } else {
      categories.add(category);
    }
    await saveCategories(categories);
  }

  Future<void> deleteCategory(String id) async {
    final categories = await loadCategories();
    categories.removeWhere((category) => category.id == id);
    await saveCategories(categories);
  }

  Future<void> updateCategoryCards(String categoryId, List<String> cardIds) async {
    final categories = await loadCategories();
    final index = categories.indexWhere((c) => c.id == categoryId);
    if (index >= 0) {
      final category = categories[index];
      final updatedCategory = CardCategory(
        id: category.id,
        name: category.name,
        description: category.description,
        cardIds: cardIds,
      );
      categories[index] = updatedCategory;
      await saveCategories(categories);
    }
  }
} 