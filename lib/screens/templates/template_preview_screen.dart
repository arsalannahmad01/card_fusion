import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../models/card_model.dart';
import '../../models/card_template_model.dart';
import '../../widgets/card_template_widget.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data' show Uint8List;
import '../../services/template_service.dart';

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
  final GlobalKey _frontCardKey = GlobalKey();
  final GlobalKey _backCardKey = GlobalKey();
  final _templateService = TemplateService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // TODO: Save template selection
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Front side preview
            RepaintBoundary(
              key: _frontCardKey,
              child: Container(
                width: 380,
                height: 220,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Color(int.parse(widget.template.styles['primaryColor'].substring(1, 7), radix: 16) + 0xFF000000),
                      Color(int.parse(widget.template.styles['secondaryColor'].substring(1, 7), radix: 16) + 0xFF000000),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CardTemplateWidget(
                  card: widget.card,
                  styles: widget.template.styles,
                  showFront: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Back side preview
            RepaintBoundary(
              key: _backCardKey,
              child: Container(
                width: 380,
                height: 220,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Color(int.parse(widget.template.styles['primaryColor'].substring(1, 7), radix: 16) + 0xFF000000),
                      Color(int.parse(widget.template.styles['secondaryColor'].substring(1, 7), radix: 16) + 0xFF000000),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CardTemplateWidget(
                  card: widget.card,
                  styles: widget.template.styles,
                  showFront: false,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Share button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _shareCardTemplate,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share),
                      label: const Text('Share Card Preview'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Apply Template button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        try {
                          setState(() => _isLoading = true);
                          await _templateService.applyTemplate(widget.card.id, widget.template.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Template applied successfully')),
                            );
                            Navigator.pop(context, true);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error applying template: $e')),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Apply Template'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Customize Colors button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showColorCustomizationDialog,
                      icon: const Icon(Icons.palette),
                      label: const Text('Customize Colors'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Font Selection button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showFontSelectionDialog,
                      icon: const Icon(Icons.font_download),
                      label: const Text('Change Font'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _shareCardTemplate() async {
    try {
      setState(() => _isLoading = true);

      // Capture front side
      final frontImage = await _captureCard(_frontCardKey);
      // Capture back side
      final backImage = await _captureCard(_backCardKey);

      if (frontImage == null || backImage == null) {
        throw 'Failed to capture card images';
      }

      // Save images to temporary files
      final tempDir = await getTemporaryDirectory();
      final frontFile = File('${tempDir.path}/card_front.png');
      final backFile = File('${tempDir.path}/card_back.png');

      await frontFile.writeAsBytes(frontImage);
      await backFile.writeAsBytes(backImage);

      // Share both images
      await Share.shareXFiles(
        [
          XFile(frontFile.path),
          XFile(backFile.path),
        ],
        text: '''${widget.card.name}'s Digital Card
        
Template: ${widget.template.name}
Type: ${widget.card.type.name}

Scan QR code on the back to save this contact.''',
      );
    } catch (e) {
      debugPrint('Error sharing template: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing template: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Uint8List?> _captureCard(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      final image = await boundary?.toImage(pixelRatio: 3.0);
      final byteData = await image?.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing card: $e');
      return null;
    }
  }

  void _showColorCustomizationDialog() {
    // TODO: Implement color customization dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customize Colors'),
        content: const Text('Color customization coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFontSelectionDialog() {
    // TODO: Implement font selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Font'),
        content: const Text('Font selection coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 