import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../services/card_service.dart';
import '../card_viewer/card_viewer_screen.dart';
import '../../services/analytics_service.dart';
import 'dart:io' show Platform;

class ScannedCardPreviewScreen extends StatefulWidget {
  final DigitalCard card;

  const ScannedCardPreviewScreen({
    super.key,
    required this.card,
  });

  @override
  State<ScannedCardPreviewScreen> createState() => _ScannedCardPreviewScreenState();
}

class _ScannedCardPreviewScreenState extends State<ScannedCardPreviewScreen> {
  final _cardService = CardService();
  final _analyticsService = AnalyticsService();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanned Card'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildPreview(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            widget.card.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          widget.card.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(widget.card.type.name.toUpperCase()),
            if (widget.card.jobTitle != null) Text(widget.card.jobTitle!),
            if (widget.card.companyName != null) Text(widget.card.companyName!),
            const SizedBox(height: 8),
            Text(widget.card.email),
            if (widget.card.phone != null) Text(widget.card.phone!),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardViewerScreen(card: widget.card),
                  ),
                ),
                child: const Text('View Details'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: _isSaving ? null : _saveCard,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Card'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCard() async {
    try {
      setState(() => _isSaving = true);
      await _cardService.saveCard(widget.card.id);
      
      await _analyticsService.recordScan(
        cardId: widget.card.id,
        eventType: CardAnalyticEvent.save,
        details: ScanDetails(
          deviceType: 'mobile',
          platform: Platform.isIOS ? 'iOS' : 'Android',
          source: 'preview_save',
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card saved successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving card: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving card: $e')),
        );
      }
    }
  }
} 