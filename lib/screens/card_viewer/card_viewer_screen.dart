import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import '../../models/business_card.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../widgets/business_card_preview.dart';
import 'dart:typed_data';

class CardViewerScreen extends StatefulWidget {
  final BusinessCard card;

  const CardViewerScreen({super.key, required this.card});

  @override
  State<CardViewerScreen> createState() => _CardViewerScreenState();
}

class _CardViewerScreenState extends State<CardViewerScreen> {
  bool _showFront = true;
  final GlobalKey _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareCard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RepaintBoundary(
              key: _cardKey,
              child: BusinessCardPreview(
                card: widget.card,
                showFront: _showFront,
                onFlip: () => setState(() => _showFront = !_showFront),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tap card to see ${_showFront ? 'back' : 'front'} side',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () => _launchUrl('mailto:${widget.card.email}'),
          icon: const Icon(Icons.email),
          label: const Text('Email'),
        ),
        ElevatedButton.icon(
          onPressed: () => _launchUrl('tel:${widget.card.phone}'),
          icon: const Icon(Icons.phone),
          label: const Text('Call'),
        ),
        if (widget.card.website.isNotEmpty)
          ElevatedButton.icon(
            onPressed: () => _launchUrl(widget.card.website),
            icon: const Icon(Icons.web),
            label: const Text('Website'),
          ),
      ],
    );
  }

  Future<Uint8List?> _captureCard() async {
    try {
      final RenderRepaintBoundary boundary = _cardKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing card: $e');
      return null;
    }
  }

  Future<void> _shareCard() async {
    try {
      // Save current state
      final currentState = _showFront;

      // Capture front side
      setState(() => _showFront = true);
      await Future.delayed(const Duration(milliseconds: 100));
      final frontBytes = await _captureCard();

      // Capture back side
      setState(() => _showFront = false);
      await Future.delayed(const Duration(milliseconds: 100));
      final backBytes = await _captureCard();

      // Restore original state
      setState(() => _showFront = currentState);

      if (frontBytes == null || backBytes == null) {
        throw Exception('Failed to capture card image');
      }

      // Save and share images
      final tempDir = await getTemporaryDirectory();
      final frontPath = '${tempDir.path}/card_front.png';
      final backPath = '${tempDir.path}/card_back.png';
      
      await File(frontPath).writeAsBytes(frontBytes);
      await File(backPath).writeAsBytes(backBytes);

      await Share.shareXFiles(
        [XFile(frontPath), XFile(backPath)],
        text: '${widget.card.name}\'s Business Card',
        subject: 'Digital Business Card',
      );

      // Clean up
      await File(frontPath).delete();
      await File(backPath).delete();
    } catch (e) {
      debugPrint('Error sharing card: $e');
      final cardData = jsonEncode(widget.card.toShareJson());
      await Share.share(
        'My Business Card\n\n$cardData',
        subject: '${widget.card.name}\'s Business Card',
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
} 