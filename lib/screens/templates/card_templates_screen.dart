import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../models/card_template_model.dart';
import 'template_preview_screen.dart';
import '../../services/card_service.dart';
import '../../services/template_service.dart';

class CardTemplatesScreen extends StatefulWidget {
  final DigitalCard card;

  const CardTemplatesScreen({super.key, required this.card});

  @override
  State<CardTemplatesScreen> createState() => _CardTemplatesScreenState();
}

class _CardTemplatesScreenState extends State<CardTemplatesScreen> {
  final _cardService = CardService();
  final _templateService = TemplateService();
  late DigitalCard _selectedCard;
  List<CardTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCard = widget.card;
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await _templateService.getTemplates();
      if (mounted) {
        setState(() {
          _templates = templates;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading templates: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Templates'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                return _buildTemplateCard(context, template);
              },
            ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, CardTemplate template) {
    final isSupported = template.supportsCardType(_selectedCard.type);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isSupported
            ? () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TemplatePreviewScreen(
                      card: _selectedCard,
                      template: template,
                    ),
                  ),
                );
                if (result == true && mounted) {
                  await _templateService.applyTemplate(_selectedCard.id, template.id);
                  final updatedCard = await _cardService.getCardById(_selectedCard.id);
                  if (updatedCard != null && mounted) {
                    Navigator.pop(context, updatedCard);
                  }
                }
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    template.previewImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey[400]),
                      );
                    },
                  ),
                  if (!isSupported)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text(
                          'Not available for this card type',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    template.type.name.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 