import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../models/card_template_model.dart';
import '../../services/card_service.dart';
import '../../services/template_service.dart';
import '../../config/theme.dart';
import '../../widgets/template_renderer_widget.dart';
import '../../utils/error_display.dart';
import '../../utils/app_error.dart';
import 'dart:math' show pi;

class CardTemplatesScreen extends StatefulWidget {
  final DigitalCard card;
  const CardTemplatesScreen({super.key, required this.card});

  @override
  State<CardTemplatesScreen> createState() => _CardTemplatesScreenState();
}

class _CardTemplatesScreenState extends State<CardTemplatesScreen> with TickerProviderStateMixin {
  final _templateService = TemplateService();
  final _cardService = CardService();
  late DigitalCard _selectedCard;
  List<DigitalCard> _userCards = [];
  List<CardTemplate> _templates = [];
  bool _isLoading = true;
  Map<String, AnimationController> _flipControllers = {};
  Set<String> _flippedCards = {};

  @override
  void initState() {
    super.initState();
    _selectedCard = widget.card;
    _userCards = [_selectedCard];
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in _flipControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final templates = await _templateService.getTemplates();
      
      for (var template in templates) {
        _flipControllers[template.id] = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 500),
        );
      }

      setState(() {
        _templates = templates;
        _isLoading = false;
      });

      _loadUserCards();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorDisplay.showError(context, AppError.handleError(e));
      }
    }
  }

  Future<void> _loadUserCards() async {
    try {
      final cards = await _cardService.getUserCards();
      if (mounted) {
        setState(() {
          _userCards = [_selectedCard, ...cards.where((c) => c.id != _selectedCard.id)];
        });
      }
    } catch (e) {
      debugPrint('Error loading user cards: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Choose Template'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Card Selector
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedCard.id,
                icon: const Icon(Icons.keyboard_arrow_down),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                items: _userCards.map((card) {
                  return DropdownMenuItem(
                    value: card.id,
                    child: Text(
                      '${card.name} (${card.type.name})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCard = _userCards.firstWhere((c) => c.id == value);
                    });
                  }
                },
              ),
            ),
          ),
          // Templates List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _templates.length,
                    itemBuilder: (context, index) => _buildTemplateCard(_templates[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(CardTemplate template) {
    final controller = _flipControllers[template.id];
    if (controller == null) return const SizedBox();
    final isFlipped = _flippedCards.contains(template.id);
    final isCurrentTemplate = _selectedCard.template_id == template.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Template Preview
          GestureDetector(
            onTap: () => _toggleCard(template.id),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(controller.value * pi),
                  alignment: Alignment.center,
                  child: AspectRatio(
                    aspectRatio: 1.75,
                    child: TemplateRendererWidget(
                      card: _selectedCard,
                      template: template,
                      showFront: !isFlipped,
                    ),
                  ),
                );
              },
            ),
          ),
          // Apply Button or Applied Label
          Positioned(
            right: 16,
            bottom: 16,
            child: isCurrentTemplate
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Applied',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => _applyTemplate(template),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
          ),
        ],
      ),
    );
  }

  void _toggleCard(String templateId) {
    final controller = _flipControllers[templateId];
    if (controller == null || controller.isAnimating) return;

    setState(() {
      if (_flippedCards.contains(templateId)) {
        _flippedCards.remove(templateId);
        controller.reverse();
      } else {
        _flippedCards.add(templateId);
        controller.forward();
      }
    },);
  }

  Future<void> _applyTemplate(CardTemplate template) async {
    try {
      setState(() => _isLoading = true);
      
      // Apply the template and get updated card
      final updatedCard = await _templateService.applyTemplate(_selectedCard.id, template.id);
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template applied successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Return the updated card to the previous screen
        Navigator.pop(context, updatedCard);
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplay.showError(context, AppError.handleError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 