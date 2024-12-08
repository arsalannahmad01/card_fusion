import 'card_model.dart' show CardType;

class CardTemplate {
  final String id;
  final String name;
  final String type;
  final String frontMarkup;
  final String backMarkup;
  final Map<String, dynamic> styles;
  final List<String> supportedCardTypes;

  const CardTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.frontMarkup,
    required this.backMarkup,
    required this.styles,
    required this.supportedCardTypes,
  });

  factory CardTemplate.fromJson(Map<String, dynamic> json) => CardTemplate(
    id: json['id'],
    name: json['name'],
    type: json['type'],
    frontMarkup: json['front_markup'] ?? '',
    backMarkup: json['back_markup'] ?? '',
    styles: json['styles'] ?? {},
    supportedCardTypes: List<String>.from(json['supported_card_types'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'front_markup': frontMarkup,
    'back_markup': backMarkup,
    'styles': styles,
    'supported_card_types': supportedCardTypes,
  };

  bool supportsCardType(CardType cardType) => 
    supportedCardTypes.contains(cardType.name);
}
