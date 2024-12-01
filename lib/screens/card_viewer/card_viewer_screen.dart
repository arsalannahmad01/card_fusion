import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../models/card_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show debugPrint;
import '../../services/analytics_service.dart'
    show AnalyticsService, CardAnalyticEvent, ScanDetails;
import '../../screens/analytics/analytics_screen.dart';
import '../../screens/templates/card_templates_screen.dart';

class CardViewerScreen extends StatefulWidget {
  final DigitalCard card;
  final bool isSavedCard;

  const CardViewerScreen({
    super.key,
    required this.card,
    this.isSavedCard = false,
  });

  @override
  State<CardViewerScreen> createState() => _CardViewerScreenState();
}

class _CardViewerScreenState extends State<CardViewerScreen> {
  final _analyticsService = AnalyticsService();
  final _qrKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text(widget.card.name),
        actions: [
          if (!widget.isSavedCard) ...[
            IconButton(
              icon: const Icon(Icons.style),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CardTemplatesScreen(card: widget.card),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnalyticsScreen(initialCard: widget.card),
                ),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareCard(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildContactInfo(context),
              const SizedBox(height: 24),
              _buildTypeSpecificInfo(context),
              const SizedBox(height: 24),
              _buildQRCode(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.card.type == CardType.individual) ...[
              // Individual card - show only profile photo
              if (widget.card.userImageUrl != null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(widget.card.userImageUrl!),
                )
              else
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    widget.card.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  ),
                ),
            ] else ...[
              // Business or Company card - show photo and logo side by side
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Profile Photo
                  Column(
                    children: [
                      if (widget.card.userImageUrl != null)
                        CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              NetworkImage(widget.card.userImageUrl!),
                        )
                      else
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            widget.card.name[0].toUpperCase(),
                            style: const TextStyle(
                                fontSize: 30, color: Colors.white),
                          ),
                        ),
                      if (widget.card.userImageUrl != null)
                        const SizedBox(height: 8),
                      const Text('Profile'),
                    ],
                  ),
                  // Logo
                  if (widget.card.logoUrl != null)
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(widget.card.logoUrl!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Logo'),
                      ],
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              widget.card.name,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.card.type.name.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            if (widget.card.socialLinks != null &&
                widget.card.socialLinks!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _buildSocialLinks(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: widget.card.socialLinks!.entries.map((entry) {
        final IconData icon;
        switch (entry.key.toLowerCase()) {
          case 'linkedin':
            icon = Icons.work;
            break;
          case 'twitter':
          case 'x':
            icon = Icons.chat;
            break;
          case 'facebook':
            icon = Icons.thumb_up;
            break;
          case 'instagram':
            icon = Icons.camera_alt;
            break;
          case 'github':
            icon = Icons.code;
            break;
          default:
            icon = Icons.link;
        }

        return IconButton(
          icon: Icon(icon),
          onPressed: () => _launchUrl(entry.value),
          color: Theme.of(context).primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoTile(
              context,
              icon: Icons.email,
              title: 'Email',
              value: widget.card.email,
              onTap: () => _launchUrl('mailto:${widget.card.email}'),
            ),
            if (widget.card.phone != null)
              _buildInfoTile(
                context,
                icon: Icons.phone,
                title: 'Phone',
                value: widget.card.phone!,
                onTap: () => _launchUrl('tel:${widget.card.phone}'),
              ),
            if (widget.card.website != null)
              _buildInfoTile(
                context,
                icon: Icons.web,
                title: 'Website',
                value: widget.card.website!,
                onTap: () => _launchUrl(widget.card.website!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificInfo(BuildContext context) {
    switch (widget.card.type) {
      case CardType.individual:
        return _buildIndividualInfo(context);
      case CardType.business:
        return _buildBusinessInfo(context);
      case CardType.company:
        return _buildCompanyInfo(context);
    }
  }

  Widget _buildIndividualInfo(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (widget.card.jobTitle != null)
              _buildInfoTile(
                context,
                icon: Icons.work,
                title: 'Job Title',
                value: widget.card.jobTitle!,
              ),
            if (widget.card.age != null)
              _buildInfoTile(
                context,
                icon: Icons.cake,
                title: 'Age',
                value: widget.card.age.toString(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfo(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (widget.card.companyName != null)
              _buildInfoTile(
                context,
                icon: Icons.business,
                title: 'Company Name',
                value: widget.card.companyName!,
              ),
            if (widget.card.businessType != null)
              _buildInfoTile(
                context,
                icon: Icons.category,
                title: 'Business Type',
                value: widget.card.businessType!,
              ),
            if (widget.card.yearFounded != null)
              _buildInfoTile(
                context,
                icon: Icons.calendar_today,
                title: 'Year Founded',
                value: widget.card.yearFounded.toString(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfo(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoTile(
              context,
              icon: Icons.business,
              title: 'Company Name',
              value: widget.card.companyName!,
            ),
            if (widget.card.businessType != null)
              _buildInfoTile(
                context,
                icon: Icons.category,
                title: 'Industry',
                value: widget.card.businessType!,
              ),
            if (widget.card.yearFounded != null)
              _buildInfoTile(
                context,
                icon: Icons.calendar_today,
                title: 'Year Founded',
                value: widget.card.yearFounded.toString(),
              ),
            if (widget.card.employeeCount != null)
              _buildInfoTile(
                context,
                icon: Icons.people,
                title: 'Employees',
                value: widget.card.employeeCount.toString(),
              ),
            if (widget.card.headquarters != null)
              _buildInfoTile(
                context,
                icon: Icons.location_city,
                title: 'Headquarters',
                value: widget.card.headquarters!,
              ),
            if (widget.card.registrationNumber != null)
              _buildInfoTile(
                context,
                icon: Icons.numbers,
                title: 'Registration Number',
                value: widget.card.registrationNumber!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _shareCard(BuildContext context) async {
    try {
      // Use existing QR widget
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      final image = await boundary?.toImage(pixelRatio: 3.0);
      final byteData = await image?.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (bytes == null) return;

      final tempDir = await getTemporaryDirectory();
      final qrFile = File('${tempDir.path}/card_qr.png');
      await qrFile.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(qrFile.path)],
        text: '''${widget.card.name}'s Digital Card

${widget.card.type.name.toUpperCase()}
${widget.card.email}
${widget.card.phone ?? ''}
${widget.card.website ?? ''}

Scan the QR code to save this contact.''',
      );

      await _analyticsService.recordScan(
        cardId: widget.card.id,
        eventType: CardAnalyticEvent.share,
        details: ScanDetails(
          deviceType: 'mobile',
          platform: Platform.isIOS ? 'iOS' : 'Android',
          source: 'share',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing card: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing card: $e')),
        );
      }
    }
  }

  Widget _buildQRCode(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Scan to Connect'),
            const SizedBox(height: 16),
            QrImageView(
              key: _qrKey, // Use the global key here
              data: _generateQRData(),
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
              // ... rest of QR code properties
            ),
          ],
        ),
      ),
    );
  }

  String _generateQRData() {
    final Map<String, dynamic> qrData = {
      'type': 'digital_card',
      'id': widget.card.id,
      'name': widget.card.name,
      'cardType': widget.card.type.name,
      'contact': {
        'email': widget.card.email,
        if (widget.card.phone != null) 'phone': widget.card.phone,
        if (widget.card.website != null) 'website': widget.card.website,
      },
      if (widget.card.type == CardType.individual) ...{
        if (widget.card.jobTitle != null) 'jobTitle': widget.card.jobTitle,
      } else ...{
        if (widget.card.companyName != null)
          'companyName': widget.card.companyName,
        if (widget.card.businessType != null)
          'businessType': widget.card.businessType,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(qrData);
  }
}
