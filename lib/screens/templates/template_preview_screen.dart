import 'package:flutter/material.dart';
import '../../models/card_model.dart';
import '../../models/card_template_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class TemplatePreviewScreen extends StatelessWidget {
  final DigitalCard card;
  final CardTemplate template;

  const TemplatePreviewScreen({
    super.key,
    required this.card,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(template.name),
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
      body: PageView(
        children: [
          _buildFrontSide(context),
          _buildBackSide(context),
        ],
      ),
    );
  }

  Widget _buildFrontSide(BuildContext context) {
    switch (card.type) {
      case CardType.individual:
        return _buildIndividualFront(context);
      case CardType.business:
        return _buildBusinessFront(context);
      case CardType.company:
        return _buildCompanyFront(context);
    }
  }

  Widget _buildBackSide(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          QrImageView(
            data: jsonEncode({
              'type': 'digital_card',
              'id': card.id,
            }),
            version: QrVersions.auto,
            size: 200,
          ),
          const SizedBox(height: 16),
          Text(
            'Scan to connect',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  // Add specific template layouts for each card type...
  Widget _buildIndividualFront(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (card.userImageUrl != null)
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(card.userImageUrl!),
            ),
          const SizedBox(height: 16),
          Text(card.name, style: Theme.of(context).textTheme.headlineSmall),
          Text(card.email),
          if (card.phone != null) Text(card.phone!),
          if (card.jobTitle != null) Text(card.jobTitle!),
        ],
      ),
    );
  }

  Widget _buildBusinessFront(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(card.name, style: Theme.of(context).textTheme.headlineSmall),
          Text(card.email),
          if (card.phone != null) Text(card.phone!),
          if (card.companyName != null) Text(card.companyName!),
          if (card.businessType != null) Text(card.businessType!),
          if (card.logoUrl != null)
            Image.network(card.logoUrl!, height: 80, width: 80),
        ],
      ),
    );
  }

  Widget _buildCompanyFront(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(card.companyName ?? '', style: Theme.of(context).textTheme.headlineSmall),
          if (card.businessType != null) Text(card.businessType!),
          Text(card.email),
          if (card.website != null) Text(card.website!),
          if (card.phone != null) Text(card.phone!),
        ],
      ),
    );
  }
} 