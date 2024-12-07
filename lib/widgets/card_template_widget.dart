import 'package:flutter/material.dart';
import '../models/card_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class CardTemplateWidget extends StatefulWidget {
  final DigitalCard card;
  final Map<String, dynamic> styles;
  final bool showFront;
  final double? width;
  final double? height;

  const CardTemplateWidget({
    super.key,
    required this.card,
    required this.styles,
    this.showFront = true,
    this.width,
    this.height,
  });

  @override
  State<CardTemplateWidget> createState() => _CardTemplateWidgetState();
}

class _CardTemplateWidgetState extends State<CardTemplateWidget> {
  // Standard business card ratio (3.5 x 2 inches)
  static const double _aspectRatio = 1.75;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: SizedBox(
        width: widget.width ?? MediaQuery.of(context).size.width * 0.9,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getBackgroundColor(),
                  _getSecondaryColor(),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.showFront ? _buildFrontSide(context) : _buildBackSide(),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    try {
      final colorStr = widget.styles['primaryColor'] as String?;
      if (colorStr == null || colorStr.isEmpty) return Colors.blue;
      return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.blue;
    }
  }

  Color _getSecondaryColor() {
    try {
      final colorStr = widget.styles['secondaryColor'] as String?;
      if (colorStr == null || colorStr.isEmpty) return Colors.blueAccent;
      return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.blueAccent;
    }
  }

  Color _getTextColor() {
    try {
      final colorStr = widget.styles['textColor'] as String?;
      if (colorStr == null || colorStr.isEmpty) return Colors.white;
      return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.white;
    }
  }

  String _getFontFamily() {
    return widget.styles['fontFamily'] as String? ?? 'Roboto';
  }

  Widget _buildFrontSide(BuildContext context) {
    switch (widget.card.type) {
      case CardType.individual:
        return _buildIndividualFront(context);
      case CardType.business:
        return _buildBusinessFront(context);
      case CardType.company:
        return _buildCompanyFront(context);
    }
  }

  Widget _buildIndividualFront(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.card.userImageUrl != null)
                CircleAvatar(
                  radius: 35,
                  backgroundImage: NetworkImage(widget.card.userImageUrl!),
                )
              else
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.card.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 28,
                      color: _getBackgroundColor(),
                    ),
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.card.name,
                      style: TextStyle(
                        color: _getTextColor(),
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: _getFontFamily(),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.card.jobTitle != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.yellow.withOpacity(0.2),
                          border: Border.all(color: Colors.yellow, width: 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.card.jobTitle!,
                          style: TextStyle(
                            color: Colors.yellow,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: _getFontFamily(),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            widget.card.email,
            style: TextStyle(
              color: _getTextColor().withOpacity(0.7),
              fontSize: 16,
              fontFamily: _getFontFamily(),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.card.phone != null)
            Text(
              widget.card.phone!,
              style: TextStyle(
                color: _getTextColor().withOpacity(0.7),
                fontSize: 16,
                fontFamily: _getFontFamily(),
              ),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildBusinessFront(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -20,
          top: 0,
          bottom: 0,
          child: Container(
            width: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getTextColor().withOpacity(0.0),
                  _getTextColor().withOpacity(0.05),
                  _getTextColor().withOpacity(0.1),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getTextColor().withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getTextColor().withOpacity(0.15),
                      width: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.card.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        color: _getBackgroundColor(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.card.name,
                          style: TextStyle(
                            color: _getTextColor(),
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            fontFamily: _getFontFamily(),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.card.companyName != null)
                          Text(
                            widget.card.companyName!,
                            style: TextStyle(
                              color: _getTextColor().withOpacity(0.7),
                              fontSize: 16,
                              fontFamily: _getFontFamily(),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.card.email,
                style: TextStyle(
                  color: _getTextColor().withOpacity(0.7),
                  fontSize: 16,
                  fontFamily: _getFontFamily(),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.card.phone != null)
                Text(
                  widget.card.phone!,
                  style: TextStyle(
                    color: _getTextColor().withOpacity(0.7),
                    fontSize: 16,
                    fontFamily: _getFontFamily(),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyFront(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -20,
          top: 0,
          bottom: 0,
          child: Container(
            width: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      image: widget.card.logoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(widget.card.logoUrl!),
                              fit: BoxFit.contain,
                            )
                          : null,
                    ),
                    child: widget.card.logoUrl == null
                        ? Icon(
                            Icons.business,
                            size: 35,
                            color: Color(int.parse(
                                    widget.styles['primaryColor']
                                        .substring(1, 7),
                                    radix: 16) +
                                0xFF000000),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.card.companyName ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: widget.styles['fontFamily'],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.card.businessType != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.card.businessType!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: widget.styles['fontFamily'],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (widget.card.headquarters != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.card.headquarters!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    fontFamily: widget.styles['fontFamily'],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 88),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContactInfo(
                        Icons.email,
                        widget.card.email,
                        color: Colors.white70,
                      ),
                      if (widget.card.phone != null) ...[
                        const SizedBox(height: 4),
                        _buildContactInfo(
                          Icons.phone,
                          widget.card.phone!,
                          color: Colors.white70,
                        ),
                      ],
                      if (widget.card.website != null) ...[
                        const SizedBox(height: 4),
                        _buildContactInfo(
                          Icons.web,
                          widget.card.website!,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? Colors.white70,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color ?? Colors.white70,
              fontFamily: widget.styles['fontFamily'],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBackSide() {
    final primaryColor = _getBackgroundColor();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            _getSecondaryColor(),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Pattern of "Card Fusion" text
          CustomPaint(
            painter: CardFusionPatternPainter(
              textColor: Colors.white.withOpacity(0.15),
            ),
            size: Size.infinite,
          ),

          // Centered QR Code
          Center(
            child: Container(
              width: 160,
              height: 160,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: QrImageView(
                data: jsonEncode({
                  'type': 'digital_card',
                  'id': widget.card.id,
                  'name': widget.card.name,
                }),
                version: QrVersions.auto,
                size: 136,
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                padding: const EdgeInsets.all(0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CardFusionPatternPainter extends CustomPainter {
  final Color textColor;

  CardFusionPatternPainter({required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    final letters = 'CARD FUSION'.split('');
    final letterPainters = letters.map((letter) => TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout()).toList();

    const columnWidth = 40.0; // Width between vertical text columns
    const letterSpacing = 24.0; // Vertical spacing between letters

    // Calculate total height of one column
    final columnHeight = letterSpacing * letters.length;

    // Calculate number of columns needed
    final numColumns = (size.width / columnWidth).ceil() + 1;
    final numRows = (size.height / columnHeight).ceil() + 1;

    for (int col = 0; col < numColumns; col++) {
      final x = col * columnWidth;
      
      // Offset every other column for a more interesting pattern
      final yOffset = col.isEven ? 0.0 : letterSpacing / 2;
      
      for (int row = -1; row < numRows; row++) {
        var y = row * columnHeight + yOffset;
        
        // Paint each letter vertically
        for (int i = 0; i < letters.length; i++) {
          final letterY = y + (i * letterSpacing);
          if (letterY >= -letterSpacing && letterY <= size.height + letterSpacing) {
            final painter = letterPainters[i];
            painter.paint(
              canvas,
              Offset(x - (painter.width / 2), letterY),
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(CardFusionPatternPainter oldDelegate) => false;
}
