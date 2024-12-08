import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/card_model.dart';
import '../models/card_template_model.dart';
import '../config/theme.dart';

class TemplateRendererWidget extends StatelessWidget {
  final DigitalCard card;
  final CardTemplate template;
  final bool showFront;

  const TemplateRendererWidget({
    super.key,
    required this.card,
    required this.template,
    this.showFront = true,
  });

  @override
  Widget build(BuildContext context) {
    if (template == null) {
      debugPrint('Template is null in TemplateRendererWidget');
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _parseColor(template.styles['primaryColor']),
            _parseColor(template.styles['secondaryColor']),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: showFront ? _buildFront() : _buildBack(),
    );
  }

  Color _parseColor(String? hexColor) {
    try {
      if (hexColor == null || hexColor.isEmpty) return AppColors.primary;
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) hexColor = 'FF$hexColor';
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }

  Widget _buildFront() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  card.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    color: _parseColor(template.styles['primaryColor']),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (card.jobTitle != null)
                      Text(
                        card.jobTitle!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildContactInfo(),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.email,
          style: const TextStyle(color: Colors.white),
        ),
        if (card.phone != null)
          Text(
            card.phone!,
            style: const TextStyle(color: Colors.white),
          ),
        if (card.website != null)
          Text(
            card.website!,
            style: const TextStyle(color: Colors.white),
          ),
      ],
    );
  }

  Widget _buildBack() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: QrImageView(
          data: card.id,
          version: QrVersions.auto,
          size: 200,
          backgroundColor: Colors.white,
          foregroundColor: _parseColor(template.styles['primaryColor']),
        ),
      ),
    );
  }
} 