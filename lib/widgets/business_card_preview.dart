import 'package:flutter/material.dart';
import '../models/business_card.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'dart:io';

class BusinessCardPreview extends StatelessWidget {
  final BusinessCard card;
  final bool showFront;
  final VoidCallback? onFlip;

  const BusinessCardPreview({
    super.key,
    required this.card,
    this.showFront = true,
    this.onFlip,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: GestureDetector(
        onTap: onFlip,
        child: Card(
          elevation: 4,
          color: Colors.black,
          child: showFront ? _buildFrontSide() : _buildBackSide(),
        ),
      ),
    );
  }

  Widget _buildFrontSide() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (card.profileImagePath != null)
                CircleAvatar(
                  radius: 30,
                  backgroundImage: FileImage(File(card.profileImagePath!)),
                )
              else
                const CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 30),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: card.design.secondaryColor,
                        fontFamily: card.design.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.jobTitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: card.design.secondaryColor.withOpacity(0.8),
                        fontFamily: card.design.fontFamily,
                      ),
                    ),
                    Text(
                      card.company,
                      style: TextStyle(
                        fontSize: 14,
                        color: card.design.secondaryColor.withOpacity(0.8),
                        fontFamily: card.design.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              if (card.logoPath != null)
                Image.file(
                  File(card.logoPath!),
                  width: 50,
                  height: 50,
                ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(child: _buildAllContactInfo()),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  // color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: QrImageView(
                  padding: const EdgeInsets.all(2),
                  data: jsonEncode(card.toShareJson()),
                  version: QrVersions.auto,
                  size: 118,
                  // eyeStyle: QrEyeStyle(
                  //   color: Colors.white,
                  // ),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Card Fusion',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: card.design.secondaryColor,
            fontFamily: card.design.fontFamily,
          ),
        ),
        Text(
          'Card Fusion',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: card.design.secondaryColor,
            fontFamily: card.design.fontFamily,
          ),
        ),
        Text(
          'Card Fusion',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: card.design.secondaryColor,
            fontFamily: card.design.fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildAllContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.email, card.email),
        const SizedBox(height: 4),
        _buildInfoRow(Icons.phone, card.phone),
        if (card.website.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildInfoRow(Icons.web, card.website),
        ],
        ...card.socialLinks.map((link) {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _buildInfoRow(Icons.link, '${link.platform}: ${link.url}'),
          );
        }),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: card.design.secondaryColor.withOpacity(0.8),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: card.design.secondaryColor.withOpacity(0.8),
              fontFamily: card.design.fontFamily,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
