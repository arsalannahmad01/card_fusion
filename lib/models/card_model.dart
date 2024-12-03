import 'package:supabase_flutter/supabase_flutter.dart';
import 'card_template_model.dart';

enum CardType { individual, business, company }

class DigitalCard {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String? website;
  final CardType type;
  final Map<String, String>? socialLinks;
  final CardTemplate? template;
  final String? jobTitle;
  final String? companyName;
  final String? businessType;
  final int? yearFounded;
  final String? userImageUrl;
  final String? logoUrl;
  final int? employeeCount;
  final String? headquarters;
  final String? registrationNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? age;

  DigitalCard({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.website,
    required this.type,
    this.socialLinks,
    this.template,
    this.jobTitle,
    this.companyName,
    this.businessType,
    this.yearFounded,
    this.userImageUrl,
    this.logoUrl,
    this.employeeCount,
    this.headquarters,
    this.registrationNumber,
    this.age,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : this.createdAt = createdAt ?? DateTime.now(),
       this.updatedAt = updatedAt ?? DateTime.now();

  factory DigitalCard.fromJson(Map<String, dynamic> json) {
    CardTemplate? template;
    if (json['template'] != null) {
      template = CardTemplate.fromJson(json['template']);
    }

    return DigitalCard(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      website: json['website'],
      type: CardType.values.byName(json['type']),
      socialLinks: Map<String, String>.from(json['social_links'] ?? {}),
      template: template,
      jobTitle: json['job_title'],
      companyName: json['company_name'],
      businessType: json['business_type'],
      yearFounded: json['year_founded'],
      userImageUrl: json['user_image_url'],
      logoUrl: json['logo_url'],
      employeeCount: json['employee_count'],
      headquarters: json['headquarters'],
      registrationNumber: json['registration_number'],
      age: json['age'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'website': website,
      'type': type.name,
      'social_links': socialLinks,
      'template_id': template?.id,
      'job_title': jobTitle,
      'company_name': companyName,
      'business_type': businessType,
      'year_founded': yearFounded,
      'user_image_url': userImageUrl,
      'logo_url': logoUrl,
      'employee_count': employeeCount,
      'headquarters': headquarters,
      'registration_number': registrationNumber,
      'age': age,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DigitalCard copyWith({
    String? name,
    String? email,
    String? phone,
    String? website,
    CardType? type,
    Map<String, String>? socialLinks,
    CardTemplate? template,
    String? jobTitle,
    String? companyName,
    String? businessType,
    int? yearFounded,
    String? userImageUrl,
    String? logoUrl,
    int? employeeCount,
    String? headquarters,
    String? registrationNumber,
    int? age,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DigitalCard(
      id: id,
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      type: type ?? this.type,
      socialLinks: socialLinks ?? this.socialLinks,
      template: template ?? this.template,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      businessType: businessType ?? this.businessType,
      yearFounded: yearFounded ?? this.yearFounded,
      userImageUrl: userImageUrl ?? this.userImageUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      employeeCount: employeeCount ?? this.employeeCount,
      headquarters: headquarters ?? this.headquarters,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      age: age ?? this.age,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
