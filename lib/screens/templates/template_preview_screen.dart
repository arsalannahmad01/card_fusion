import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../models/card_template_model.dart';
import '../../widgets/template_renderer_widget.dart';
import '../../services/template_service.dart';
import '../../utils/error_display.dart';
import '../../utils/app_error.dart';
import '../../config/theme.dart';

class TemplatePreviewScreen extends StatefulWidget {
  final DigitalCard card;
  final CardTemplate template;

  const TemplatePreviewScreen({
    super.key,
    required this.card,
    required this.template,
  });

  @override
  State<TemplatePreviewScreen> createState() => _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState extends State<TemplatePreviewScreen> {
  bool _isLoading = false;
  bool _showFront = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip),
            onPressed: () => setState(() => _showFront = !_showFront),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 1.75,
                  child: TemplateRendererWidget(
                    card: widget.card,
                    template: widget.template,
                    showFront: _showFront,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _applyTemplate,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.primary,
                ),
                child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Use This Template',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyTemplate() async {
    try {
      setState(() => _isLoading = true);
      await TemplateService().applyTemplate(widget.card.id, widget.template.id);
      if (mounted) {
        Navigator.pop(context, true);
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
}
