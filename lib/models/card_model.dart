import 'package:supabase_flutter/supabase_flutter.dart';

enum CardType { individual, business, company }

class DigitalCard {
  final String id;
  final String userId;
  final String name;
  final CardType type;
  final int? age;
  final String email;
  final String? phone;
  final String? companyName;
  final String? businessType;
  final Map<String, String>? socialLinks;
  final String? website;
  final String? jobTitle;
  final String? userImageUrl;
  final String? logoUrl;
  final int? yearFounded;
  final int? employeeCount;
  final String? headquarters;
  final String? registrationNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  DigitalCard({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.email,
    this.age,
    this.phone,
    this.companyName,
    this.businessType,
    this.socialLinks,
    this.website,
    this.jobTitle,
    this.userImageUrl,
    this.logoUrl,
    this.yearFounded,
    this.employeeCount,
    this.headquarters,
    this.registrationNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DigitalCard.fromJson(Map<String, dynamic> json) {
    return DigitalCard(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      type: CardType.values.byName(json['type']),
      email: json['email'],
      age: json['age'],
      phone: json['phone'],
      companyName: json['company_name'],
      businessType: json['business_type'],
      socialLinks: Map<String, String>.from(json['social_links'] ?? {}),
      website: json['website'],
      jobTitle: json['job_title'],
      userImageUrl: json['user_image_url'],
      logoUrl: json['logo_url'],
      yearFounded: json['year_founded'],
      employeeCount: json['employee_count'],
      headquarters: json['headquarters'],
      registrationNumber: json['registration_number'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.name,
      'email': email,
      'age': age,
      'phone': phone,
      'company_name': companyName,
      'business_type': businessType,
      'social_links': socialLinks,
      'website': website,
      'job_title': jobTitle,
      'user_image_url': userImageUrl,
      'logo_url': logoUrl,
      'year_founded': yearFounded,
      'employee_count': employeeCount,
      'headquarters': headquarters,
      'registration_number': registrationNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DigitalCard copyWith({
    String? name,
    CardType? type,
    String? email,
    int? age,
    String? phone,
    String? companyName,
    String? businessType,
    Map<String, String>? socialLinks,
    String? website,
    String? jobTitle,
    String? userImageUrl,
    String? logoUrl,
    int? yearFounded,
    int? employeeCount,
    String? headquarters,
    String? registrationNumber,
  }) {
    return DigitalCard(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      email: email ?? this.email,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      businessType: businessType ?? this.businessType,
      socialLinks: socialLinks ?? this.socialLinks,
      website: website ?? this.website,
      jobTitle: jobTitle ?? this.jobTitle,
      userImageUrl: userImageUrl ?? this.userImageUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      yearFounded: yearFounded ?? this.yearFounded,
      employeeCount: employeeCount ?? this.employeeCount,
      headquarters: headquarters ?? this.headquarters,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
} 