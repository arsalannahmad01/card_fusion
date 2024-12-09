import 'card_template_model.dart';

enum CardType {
  individual,
  business,
}

class DigitalCard {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String? website;
  final CardType type;
  final Map<String, String>? socialLinks;
  final String? template_id;
  final String? jobTitle;
  final String? companyName;
  final String? businessType;
  final int? yearFounded;
  final String? user_image_url;
  final String? logoUrl;
  final int? employeeCount;
  final String? headquarters;
  final String? registrationNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool is_public;
  final int share_count;

  DigitalCard({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.website,
    required this.type,
    this.socialLinks,
    this.template_id,
    this.jobTitle,
    this.companyName,
    this.businessType,
    this.yearFounded,
    this.user_image_url,
    this.logoUrl,
    this.employeeCount,
    this.headquarters,
    this.registrationNumber,
    required this.createdAt,
    required this.updatedAt,
    this.is_public = true,
    this.share_count = 0,
  });

  factory DigitalCard.fromJson(Map<String, dynamic> json) {
    return DigitalCard(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      website: json['website'],
      type: CardType.values.byName(json['type']),
      socialLinks: Map<String, String>.from(json['social_links'] ?? {}),
      template_id: json['template_id'],
      jobTitle: json['job_title'],
      companyName: json['company_name'],
      businessType: json['business_type'],
      yearFounded: json['year_founded'],
      user_image_url: json['user_image_url'],
      logoUrl: json['logo_url'],
      employeeCount: json['employee_count'],
      headquarters: json['headquarters'],
      registrationNumber: json['registration_number'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      is_public: json['is_public'] ?? true,
      share_count: json['share_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'user_id': userId,
    'name': name,
    'email': email,
    'phone': phone,
    'website': website,
    'type': type.name,
    'social_links': socialLinks,
    'template_id': template_id,
    'job_title': jobTitle,
    'company_name': companyName,
    'business_type': businessType,
    'year_founded': yearFounded,
    'user_image_url': user_image_url,
    'logo_url': logoUrl,
    'employee_count': employeeCount,
    'headquarters': headquarters,
    'registration_number': registrationNumber,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_public': is_public,
    'share_count': share_count,
  };

  DigitalCard copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    CardType? type,
    Map<String, String>? socialLinks,
    String? template_id,
    String? jobTitle,
    String? companyName,
    String? businessType,
    String? phone,
    String? website,
    String? user_image_url,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? is_public,
    int? share_count,
  }) {
    return DigitalCard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      type: type ?? this.type,
      socialLinks: socialLinks ?? this.socialLinks,
      template_id: template_id ?? this.template_id,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      businessType: businessType ?? this.businessType,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      user_image_url: user_image_url ?? this.user_image_url,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      is_public: is_public ?? this.is_public,
      share_count: share_count ?? this.share_count,
    );
  }
}
