import 'package:flutter/material.dart';

enum ElementType {
  text,
  image,
  logo,
  qr,
  socialLinks,
  divider,
  container
}

class Position {
  final dynamic x;  // Can be double or 'center'
  final dynamic y;  // Can be double or 'center'

  const Position({required this.x, required this.y});

  factory Position.fromJson(Map<String, dynamic> json) => Position(
    x: json['x'],
    y: json['y'],
  );

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
  };
}

class Size {
  final double width;
  final double height;

  const Size({required this.width, required this.height});

  factory Size.fromJson(Map<String, dynamic> json) => Size(
    width: json['width'].toDouble(),
    height: json['height'].toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
  };
}

class TemplateElement {
  final String id;
  final String templateId;
  final ElementType type;
  final Position position;
  final Size size;
  final Map<String, dynamic> properties;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TemplateElement({
    required this.id,
    required this.templateId,
    required this.type,
    required this.position,
    required this.size,
    required this.properties,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TemplateElement.fromJson(Map<String, dynamic> json) => TemplateElement(
    id: json['id'],
    templateId: json['template_id'],
    type: ElementType.values.byName(json['element_type']),
    position: Position.fromJson(json['position']),
    size: Size.fromJson(json['size']),
    properties: Map<String, dynamic>.from(json['properties']),
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'template_id': templateId,
    'element_type': type.name,
    'position': position.toJson(),
    'size': size.toJson(),
    'properties': properties,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class TemplateCustomization {
  final String id;
  final String cardId;
  final String templateId;
  final Map<String, dynamic> customizations;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TemplateCustomization({
    required this.id,
    required this.cardId,
    required this.templateId,
    required this.customizations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TemplateCustomization.fromJson(Map<String, dynamic> json) => TemplateCustomization(
    id: json['id'],
    cardId: json['card_id'],
    templateId: json['template_id'],
    customizations: Map<String, dynamic>.from(json['customizations']),
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'card_id': cardId,
    'template_id': templateId,
    'customizations': customizations,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
} 