import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../models/card_template_model.dart';
import 'template_preview_screen.dart';

class CardTemplatesScreen extends StatelessWidget {
  final DigitalCard card;

  const CardTemplatesScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Templates'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: availableTemplates.length,
        itemBuilder: (context, index) {
          final template = availableTemplates[index];
          return _buildTemplateCard(context, template);
        },
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, CardTemplate template) {
    final isSupported = template.supportsCardType(card.type);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isSupported
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TemplatePreviewScreen(
                      card: card,
                      template: template,
                    ),
                  ),
                )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
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

// Sample templates
final availableTemplates = [
  CardTemplate(
    id: 'modern_individual',
    name: 'Modern Individual',
    type: TemplateType.modern,
    supportedCardTypes: [CardType.individual],
    styles: {
      'primaryColor': '#2196F3',
      'fontFamily': 'Roboto',
      'layout': 'vertical',
    },
    previewImage: 'assets/templates/placeholder.png',
  ),
  CardTemplate(
    id: 'classic_business',
    name: 'Classic Business',
    type: TemplateType.classic,
    supportedCardTypes: [CardType.business],
    styles: {
      'primaryColor': '#333333',
      'fontFamily': 'Times New Roman',
      'layout': 'horizontal',
    },
    previewImage: 'assets/templates/placeholder.png',
  ),
  CardTemplate(
    id: 'minimal_company',
    name: 'Minimal Company',
    type: TemplateType.minimal,
    supportedCardTypes: [CardType.company],
    styles: {
      'primaryColor': '#000000',
      'fontFamily': 'Helvetica',
      'layout': 'grid',
    },
    previewImage: 'assets/templates/placeholder.png',
  ),
]; 