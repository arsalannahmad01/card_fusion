class CardCategory {
  final String id;
  final String name;
  final String? description;
  final List<String> cardIds;

  CardCategory({
    required this.id,
    required this.name,
    this.description,
    this.cardIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'cardIds': cardIds,
  };

  factory CardCategory.fromJson(Map<String, dynamic> json) => CardCategory(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    cardIds: List<String>.from(json['cardIds']),
  );
} 