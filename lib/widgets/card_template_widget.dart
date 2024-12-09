import 'package:flutter/material.dart';
import '../models/card_model.dart';

class CardTemplateWidget extends StatelessWidget {
  final DigitalCard card;
  final Map<String, dynamic> styles;
  final bool showFront;

  const CardTemplateWidget({
    super.key,
    required this.card,
    required this.styles,
    this.showFront = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _parseColor(styles['primaryColor']),
            _parseColor(styles['secondaryColor']),
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

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  Widget _buildFront() {
    debugPrint('Building card front with image URL: ${card.user_image_url}');
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[200],
            backgroundImage: card.user_image_url != null 
              ? NetworkImage(card.user_image_url!)
              : null,
            onBackgroundImageError: (e, stackTrace) {
              debugPrint('Error loading image: $e');
            },
            child: card.user_image_url == null
              ? Icon(
                  Icons.person,
                  size: 40,
                  color: _parseColor(styles['primaryColor']),
                )
              : null,
          ),
          const SizedBox(height: 16),
          Text(
            card.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (card.jobTitle != null) ...[
            const SizedBox(height: 8),
            Text(
              card.jobTitle!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
          const Spacer(),
          _buildContactInfo(),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return const Center(
      child: Text(
        'Back Side',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
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
} 