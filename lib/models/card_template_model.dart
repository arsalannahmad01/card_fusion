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
  final Map<String, dynamic> frontLayout;
  final Map<String, dynamic> backLayout;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CardTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.supportedCardTypes,
    required this.styles,
    required this.previewImage,
    required this.frontLayout,
    required this.backLayout,
    required this.createdAt,
    required this.updatedAt,
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
    'front_layout': frontLayout,
    'back_layout': backLayout,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory CardTemplate.fromJson(Map<String, dynamic> json) => CardTemplate(
    id: json['id'],
    name: json['name'],
    type: TemplateType.values.byName(json['type']),
    supportedCardTypes: (json['supported_card_types'] as List)
        .map((t) => CardType.values.byName(t.toString()))
        .toList(),
    styles: Map<String, dynamic>.from(json['styles']),
    previewImage: json['preview_image'],
    frontLayout: Map<String, dynamic>.from(json['front_layout']),
    backLayout: Map<String, dynamic>.from(json['back_layout']),
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
} 