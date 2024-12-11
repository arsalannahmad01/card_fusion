import 'package:flutter/material.dart';
import '../../config/theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Last updated: ${DateTime.now().year}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Acceptance of Terms',
              content: 'By accessing and using Card Fusion, you accept and agree to be bound by these terms and conditions. If you disagree with any part of these terms, you may not access the service.',
            ),
            _buildSection(
              title: '2. Service Description',
              content: '''Card Fusion provides:
• Digital business card creation and management
• Card template customization
• QR code generation and scanning
• Contact management
• Card sharing capabilities
• Location-based features
• Analytics and tracking''',
            ),
            _buildSection(
              title: '3. User Account',
              content: '''3.1 Registration Requirements:
• Valid email or Google account
• Accurate personal information
• Secure password maintenance
• Age 13 or older

3.2 Account Security:
• Protect account credentials
• Report unauthorized access
• One account per user
• Regular security updates''',
            ),
            _buildSection(
              title: '4. User Content and Data',
              content: '''4.1 Business Cards:
• Users retain ownership of card content
• Grant us license to display and share
• Must respect intellectual property rights
• No inappropriate or illegal content

4.2 Usage Rights:
• Personal and business use only
• No unauthorized commercial use
• No data scraping or mining
• No automated access''',
            ),
            _buildSection(
              title: '5. Acceptable Use',
              content: '''Users agree not to:
• Violate any laws or regulations
• Infringe on others' rights
• Share inappropriate content
• Misuse QR code features
• Abuse sharing functionality
• Manipulate analytics data''',
            ),
            _buildSection(
              title: '6. Service Limitations',
              content: '''• Availability may vary by region
• Features subject to device compatibility
• Internet connection required
• Storage limits may apply
• QR code restrictions''',
            ),
            _buildSection(
              title: '7. Termination',
              content: '''We may suspend or terminate accounts for:
• Terms violation
• Inappropriate content
• Suspicious activity
• Extended inactivity
• Legal requirements''',
            ),
            _buildSection(
              title: '8. Intellectual Property',
              content: '''8.1 App Content:
• Templates are our property
• Features and designs are protected
• Brand assets are trademarked
• User content remains user's property

8.2 Restrictions:
• No unauthorized copying
• No reverse engineering
• No white-labeling
• No competitive use''',
            ),
            _buildSection(
              title: '9. Liability Limitations',
              content: '''We are not liable for:
• Data loss or corruption
• Service interruptions
• Third-party actions
• User disputes
• Device compatibility issues''',
            ),
            _buildSection(
              title: '10. Changes to Service',
              content: '''We reserve the right to:
• Modify features
• Update requirements
• Change storage limits
• Adjust sharing options
• Modify templates''',
            ),
            _buildSection(
              title: '11. Contact Information',
              content: '''For service-related questions:
Email: support@cardfusion.com
Website: www.cardfusion.com''',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
} 