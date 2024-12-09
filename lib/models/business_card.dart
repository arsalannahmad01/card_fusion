import 'package:card_fusion/models/card_model.dart';
import 'package:flutter/material.dart' show Color, Colors;

class BusinessCard {
  final String id;
  final String name;
  final String jobTitle;
  final String company;
  final String email;
  final String phone;
  final String website;
  final List<SocialLink> socialLinks;
  final String? profileImagePath;
  final String? logoPath;
  final CardDesign design;

  BusinessCard({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.company,
    required this.email,
    required this.phone,
    this.website = '',
    this.socialLinks = const [],
    this.profileImagePath,
    this.logoPath,
    required this.design,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'jobTitle': jobTitle,
    'company': company,
    'email': email,
    'phone': phone,
    'website': website,
    'socialLinks': socialLinks.map((link) => link.toJson()).toList(),
    'profileImagePath': profileImagePath,
    'logoPath': logoPath,
    'design': design.toJson(),
  };

  Map<String, dynamic> toShareJson() => {
    'name': name,
    'jobTitle': jobTitle,
    'company': company,
    'email': email,
    'phone': phone,
    'website': website,
    'socialLinks': socialLinks.map((link) => link.toJson()).toList(),
    'design': design.toJson(),
  };

  factory BusinessCard.fromJson(Map<String, dynamic> json) => BusinessCard(
    id: json['id'],
    name: json['name'],
    jobTitle: json['jobTitle'],
    company: json['company'],
    email: json['email'],
    phone: json['phone'],
    website: json['website'] ?? '',
    socialLinks: (json['socialLinks'] as List)
        .map((link) => SocialLink.fromJson(link))
        .toList(),
    profileImagePath: json['profileImagePath'],
    logoPath: json['logoPath'],
    design: CardDesign.fromJson(json['design']),
  );

  factory BusinessCard.fromDigitalCard(DigitalCard card) {
    return BusinessCard(
      id: card.id,
      name: card.name,
      jobTitle: card.jobTitle ?? '',
      company: card.companyName ?? '',
      email: card.email,
      phone: card.phone ?? '',
      website: card.website ?? '',
      socialLinks: card.socialLinks?.entries.map((e) => 
        SocialLink(platform: e.key, url: e.value)).toList() ?? [],
      profileImagePath: card.user_image_url,
      logoPath: card.logoUrl,
      design: CardDesign(
        template: 'default',
        primaryColor: Colors.black,
        secondaryColor: Colors.white,
        fontFamily: 'Roboto',
      ),
    );
  }
}

class SocialLink {
  final String platform;
  final String url;

  SocialLink({required this.platform, required this.url});

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'url': url,
  };

  factory SocialLink.fromJson(Map<String, dynamic> json) => SocialLink(
    platform: json['platform'],
    url: json['url'],
  );
}

class CardDesign {
  final String template;
  final Color primaryColor;
  final Color secondaryColor;
  final String fontFamily;

  CardDesign({
    required this.template,
    required this.primaryColor,
    required this.secondaryColor,
    required this.fontFamily,
  });

  Map<String, dynamic> toJson() => {
    'template': template,
    'primaryColor': primaryColor.value,
    'secondaryColor': secondaryColor.value,
    'fontFamily': fontFamily,
  };

  factory CardDesign.fromJson(Map<String, dynamic> json) => CardDesign(
    template: json['template'],
    primaryColor: Color(json['primaryColor']),
    secondaryColor: Color(json['secondaryColor']),
    fontFamily: json['fontFamily'],
  );
} 