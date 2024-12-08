import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/card_model.dart';
import '../models/card_template_model.dart';
import '../config/theme.dart';
import 'dart:convert';

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
    final qrData = {
      'type': 'digital_card',
      'id': card.id,
      'name': card.name,
    };

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        // color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _parseColor(template.styles['primaryColor']),
            _parseColor(template.styles['secondaryColor']),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Watermark Layer
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              painter: WatermarkPainter(
                text: 'Card Fusion',
                color: _parseColor(template.styles['primaryColor'])
                    .withOpacity(0.25),
              ),
            ),
          ),
          // QR Code Layer
          Center(
            child: Container(
              width: 160,
              height: 160,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _parseColor(template.styles['primaryColor'])
                      .withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: QrImageView(
                data: jsonEncode(qrData),
                version: QrVersions.auto,
                backgroundColor: Colors.white,
                foregroundColor: _parseColor(template.styles['primaryColor']),
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.circle,
                  color: _parseColor(template.styles['primaryColor']),
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: _parseColor(template.styles['primaryColor']),
                ),
                padding: const EdgeInsets.all(8),
                size: 120,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WatermarkPainter extends CustomPainter {
  final String text;
  final Color color;

  WatermarkPainter({
    required this.text,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final double textWidth = textPainter.width;
    final double textHeight = textPainter.height;
    final double spacingMultiplier = 1.2;
    final int rowCount = (size.height / (textHeight * spacingMultiplier)).ceil() + 2;
    final int columnCount = (size.width / (textWidth * spacingMultiplier)).ceil() + 2;

    for (int i = -1; i < rowCount; i++) {
      for (int j = -1; j < columnCount; j++) {
        final offset = Offset(
          j * textWidth * spacingMultiplier,
          i * textHeight * spacingMultiplier,
        );
        canvas.save();
        canvas.translate(offset.dx, offset.dy);
        canvas.rotate(-0.5);
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(WatermarkPainter oldDelegate) => false;
}
