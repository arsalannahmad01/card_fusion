import 'package:flutter/material.dart';
import '../../models/card_category.dart';
import '../../services/storage_service.dart';
import 'package:uuid/uuid.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final _storageService = StorageService();
  List<CardCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _storageService.loadCategories();
    setState(() {
      _categories = categories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return ListTile(
            title: Text(category.name),
            subtitle: Text(category.description ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteCategory(category),
            ),
            onTap: () => _editCategory(category),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createCategory,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createCategory() async {
    final category = await _showCategoryDialog();
    if (category != null) {
      await _storageService.saveCategory(category);
      await _loadCategories();
    }
  }

  Future<void> _editCategory(CardCategory category) async {
    final updatedCategory = await _showCategoryDialog(category);
    if (updatedCategory != null) {
      await _storageService.saveCategory(updatedCategory);
      await _loadCategories();
    }
  }

  Future<void> _deleteCategory(CardCategory category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
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
      await _storageService.deleteCategory(category.id);
      await _loadCategories();
    }
  }

  Future<CardCategory?> _showCategoryDialog([CardCategory? category]) async {
    final nameController = TextEditingController(text: category?.name);
    final descController = TextEditingController(text: category?.description);

    return showDialog<CardCategory>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Create Category' : 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
              ),
              autofocus: true,
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              Navigator.pop(
                context,
                CardCategory(
                  id: category?.id ?? const Uuid().v4(),
                  name: name,
                  description: descController.text.trim(),
                  cardIds: category?.cardIds ?? [],
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
} 