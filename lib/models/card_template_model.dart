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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'supported_card_types': supportedCardTypes.map((t) => t.name).toList(),
    'styles': styles,
    'preview_image': previewImage,
  };

  factory CardTemplate.fromJson(Map<String, dynamic> json) => CardTemplate(
    id: json['id'],
    name: json['name'],
    type: TemplateType.values.byName(json['type']),
    supportedCardTypes: (json['supported_card_types'] as List)
        .map((t) => CardType.values.byName(t))
        .toList(),
    styles: Map<String, dynamic>.from(json['styles']),
    previewImage: json['preview_image'],
  );
} 