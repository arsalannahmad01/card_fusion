class TemplateDefinition {
  final String template;
  final Map<String, dynamic> styles;
  final List<String> supportedFields;

  const TemplateDefinition({
    required this.template,
    required this.styles,
    required this.supportedFields,
  });

  Map<String, dynamic> toJson() => {
    'template': template,
    'styles': styles,
    'supportedFields': supportedFields,
  };

  factory TemplateDefinition.fromJson(Map<String, dynamic> json) {
    return TemplateDefinition(
      template: json['template'],
      styles: Map<String, dynamic>.from(json['styles']),
      supportedFields: List<String>.from(json['supportedFields']),
    );
  }
} 