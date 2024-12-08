import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/card_template_model.dart';
import '../../services/template_service.dart';
import '../../models/card_model.dart';
import '../../widgets/template_renderer_widget.dart';
import 'template_preview_screen.dart';

class TemplatesScreen extends StatefulWidget {
  final CardType cardType;
  
  const TemplatesScreen({
    super.key,
    required this.cardType,
  });

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cardType.name} Templates'),
      ),
      body: FutureBuilder<List<CardTemplate>>(
        future: TemplateService().getTemplates(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final templates = snapshot.data!
              .where((t) => t.supportsCardType(widget.cardType))
              .toList();

          if (templates.isEmpty) {
            return const Center(
              child: Text('No templates available for this card type'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return _buildTemplateCard(template);
            },
          );
        },
      ),
    );
  }

  Widget _buildTemplateCard(CardTemplate template) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onTemplateSelected(template),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.75,
                child: TemplateRendererWidget(
                  card: DigitalCard(
                    id: 'preview',
                    userId: '',
                    name: 'John Doe',
                    email: 'john@example.com',
                    type: widget.cardType,
                    jobTitle: 'Software Engineer',
                    companyName: 'Tech Corp',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                  template: template,
                  showFront: true,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Text(
                template.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTemplateSelected(CardTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplatePreviewScreen(
          card: DigitalCard(
            id: 'preview',
            userId: '',
            name: 'John Doe',
            email: 'john@example.com',
            type: widget.cardType,
            jobTitle: 'Software Engineer',
            companyName: 'Tech Corp',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          template: template,
        ),
      ),
    );
  }
} 