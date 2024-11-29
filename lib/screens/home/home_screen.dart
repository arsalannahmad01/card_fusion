import 'package:flutter/material.dart';
import '../card_editor/card_editor_screen.dart';
import '../../models/business_card.dart';
import '../../models/card_category.dart';
import '../../services/storage_service.dart';
import '../card_viewer/card_viewer_screen.dart';
import '../category_manager/category_manager_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storageService = StorageService();
  List<BusinessCard> _cards = [];
  List<CardCategory> _categories = [];
  CardCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cards = await _storageService.loadCards();
    final categories = await _storageService.loadCategories();
    setState(() {
      _cards = cards;
      _categories = categories;
    });
  }

  List<BusinessCard> get _filteredCards {
    if (_selectedCategory == null) return _cards;
    return _cards.where((card) => 
      _selectedCategory!.cardIds.contains(card.id)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Fusion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: _manageCategoriesPressed,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _buildCardsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createCardPressed,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DropdownButton<CardCategory?>(
          isExpanded: true,
          value: _selectedCategory,
          hint: const Text('All Cards'),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('All Cards'),
            ),
            ..._categories.map((category) => DropdownMenuItem(
              value: category,
              child: Text(category.name),
            )),
          ],
          onChanged: (category) {
            setState(() {
              _selectedCategory = category;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCardsList() {
    return _filteredCards.isEmpty
        ? const Center(
            child: Text('Create your first business card!'),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _filteredCards.length,
            itemBuilder: (context, index) {
              final card = _filteredCards[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(card.name[0]),
                  ),
                  title: Text(card.name),
                  subtitle: Text(card.jobTitle),
                  onTap: () => _viewCard(card),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Manage Categories'),
                        onTap: () => _manageCardCategories(card),
                      ),
                      PopupMenuItem(
                        child: const Text('Delete'),
                        onTap: () => _deleteCard(card),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Future<void> _createCardPressed() async {
    final result = await Navigator.push<BusinessCard>(
      context,
      MaterialPageRoute(
        builder: (context) => const CardEditorScreen(),
      ),
    );
    if (result != null) {
      debugPrint('Saving card: ${result.toJson()}');
      
      await _storageService.saveCard(result);
      setState(() {
        _cards = [..._cards, result];
      });
      await _loadData();
    }
  }

  Future<void> _viewCard(BusinessCard card) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardViewerScreen(card: card),
      ),
    );
  }

  Future<void> _manageCategoriesPressed() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagerScreen(),
      ),
    );
    await _loadData();
  }

  Future<void> _manageCardCategories(BusinessCard card) async {
    final selectedCategories = _categories
        .where((cat) => cat.cardIds.contains(card.id))
        .toList();

    final result = await showDialog<List<CardCategory>>(
      context: context,
      builder: (context) => _buildCategoryDialog(selectedCategories),
    );

    if (result != null) {
      // Update categories
      for (var category in _categories) {
        final cardIds = List<String>.from(category.cardIds);
        if (result.contains(category)) {
          if (!cardIds.contains(card.id)) {
            cardIds.add(card.id);
          }
        } else {
          cardIds.remove(card.id);
        }
        await _storageService.updateCategoryCards(category.id, cardIds);
      }
      await _loadData();
    }
  }

  Widget _buildCategoryDialog(List<CardCategory> selectedCategories) {
    return AlertDialog(
      title: const Text('Manage Categories'),
      content: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _categories.map((category) {
                return CheckboxListTile(
                  title: Text(category.name),
                  value: selectedCategories.contains(category),
                  onChanged: (checked) {
                    setState(() {
                      if (checked ?? false) {
                        selectedCategories.add(category);
                      } else {
                        selectedCategories.remove(category);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, selectedCategories),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _deleteCard(BusinessCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: const Text('Are you sure you want to delete this card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      await _storageService.deleteCard(card.id);
      await _loadData();
    }
  }
} 