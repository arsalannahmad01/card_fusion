import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/card_model.dart';
import '../../models/template_definition.dart';
import '../../widgets/card_template_widget.dart';
import '../../widgets/code_editor.dart';
import '../../services/card_service.dart';
import '../../utils/app_error.dart';
import '../../utils/error_display.dart' show ErrorDisplay;
import 'dart:typed_data';

class TemplateBuilderScreen extends StatefulWidget {
  const TemplateBuilderScreen({super.key});

  @override
  State<TemplateBuilderScreen> createState() => _TemplateBuilderScreenState();
}

class _TemplateBuilderScreenState extends State<TemplateBuilderScreen> {
  late DigitalCard previewCard;
  late TemplateDefinition currentTemplate;
  late String templateMarkup;
  late Map<String, dynamic> currentStyles;
  final _cardService = CardService();
  bool _isLoading = false;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    previewCard = DigitalCard(
      id: 'preview',
      userId: '',
      name: 'John Doe',
      email: 'john@example.com',
      type: CardType.individual,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    currentStyles = {
      'primaryColor': '#1E3D59',
      'secondaryColor': '#17B794',
    };

    templateMarkup = '''
<card>
  <name>{{name}}</name>
  <email>{{email}}</email>
  <phone>{{phone}}</phone>
  <website>{{website}}</website>
  <image>{{image}}</image>
</card>
''';

    currentTemplate = TemplateDefinition(
      template: templateMarkup,
      styles: currentStyles,
      supportedFields: const ['name', 'email', 'phone', 'website', 'image'],
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() => _isLoading = true);

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      // Read file as bytes
      final bytes = await pickedFile.readAsBytes();

      // Generate a unique filename
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';

      // Upload image to Supabase storage
      final imageUrl = await _cardService.uploadImage(fileName, bytes);

      if (mounted) {
        setState(() {
          _imageUrl = imageUrl;
          // Update preview card with new image
          previewCard = DigitalCard(
            id: previewCard.id,
            userId: previewCard.userId,
            name: previewCard.name,
            email: previewCard.email,
            type: previewCard.type,
            user_image_url: imageUrl,
            createdAt: previewCard.createdAt,
            updatedAt: previewCard.updatedAt,
          );
        });
      }
    } catch (e, stackTrace) {
      final error = AppError.handleError(e, stackTrace);
      if (mounted) {
        ErrorDisplay.showError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _isLoading ? null : _pickAndUploadImage,
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                CardTemplateWidget(
                  card: previewCard,
                  styles: currentTemplate.styles,
                  showFront: true,
                ),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: CodeEditor(
              code: templateMarkup,
              onChanged: (newMarkup) {
                setState(() {
                  currentTemplate = TemplateDefinition(
                    template: newMarkup,
                    styles: currentStyles,
                    supportedFields: const [
                      'name',
                      'email',
                      'phone',
                      'website',
                      'image'
                    ],
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
