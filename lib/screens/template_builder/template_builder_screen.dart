import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../models/template_definition.dart';
import '../../widgets/card_template_widget.dart';
import '../../widgets/code_editor.dart';

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

  @override
  void initState() {
    super.initState();
    currentStyles = {
      'primaryColor': '#1E3D59',
      'secondaryColor': '#17B794',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: CardTemplateWidget(
              card: previewCard,
              styles: currentTemplate.styles,
              showFront: true,
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
                    supportedFields: const ['name', 'email', 'phone', 'website'],
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