import 'package:flutter/material.dart';
import 'card_model.dart' show CardType;

enum TemplateType {
  modern,
  classic,
  minimal,
  bold,
  elegant,
  professional
}

class CardTemplate {
  final String id;
  final String name;
  final TemplateType type;
  final List<CardType> supportedCardTypes;
  final Map<String, dynamic> styles;
  final String previewImage;

  const CardTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.supportedCardTypes,
    required this.styles,
    required this.previewImage,
  });

  bool supportsCardType(CardType cardType) {
    return supportedCardTypes.contains(cardType);
  }
} 