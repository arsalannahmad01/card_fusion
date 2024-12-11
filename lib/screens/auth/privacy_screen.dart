import 'package:flutter/material.dart';
import '../../config/theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Last updated: ${DateTime.now().year}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Information We Collect',
              content: '''1.1 Personal Information:
• Name and contact details
• Email address and phone number
• Profile picture and business card information
• Authentication credentials (including Google Sign-in data)
• Location data (when permitted)
• Device information and IP address

1.2 Business Card Data:
• Card designs and templates
• Contact information shared via cards
• QR code data and sharing history
• Card analytics and usage statistics''',
            ),
            _buildSection(
              title: '2. How We Use Your Information',
              content: '''We use the information we collect to:
• Create and manage your digital business cards
• Enable card sharing and contact management
• Process and store card templates
• Provide location-based features
• Analyze app usage and improve user experience
• Send service-related notifications
• Maintain account security
• Generate usage analytics
• Enable QR code functionality
• Facilitate social sharing features''',
            ),
            _buildSection(
              title: '3. Information Storage and Security',
              content: '''• Data is stored securely on Supabase servers
• We use encryption for data transmission
• Local data is stored securely on your device
• Backup data may be retained for system reliability
• We implement industry-standard security measures''',
            ),
            _buildSection(
              title: '4. Information Sharing',
              content: '''We share your information with:
• Supabase (our database provider)
• Google (for authentication)
• Other users (when sharing business cards)
• Service providers for app functionality
• Legal authorities when required by law''',
            ),
            _buildSection(
              title: '5. Your Privacy Rights',
              content: '''You have the right to:
• Access and export your card data
• Modify or correct your information
• Delete your account and associated data
• Control location data sharing
• Opt-out of analytics collection
• Manage sharing preferences''',
            ),
            _buildSection(
              title: '6. Data Collection Permissions',
              content: '''We request permissions for:
• Camera (QR code scanning)
• Photo gallery (profile pictures)
• Location services (optional features)
• Storage (saving cards)
• Internet access''',
            ),
            _buildSection(
              title: '7. Children\'s Privacy',
              content: '''• Service is not intended for users under 13
• We do not knowingly collect data from children
• Parents can request data deletion''',
            ),
            _buildSection(
              title: '8. Third-Party Services',
              content: '''• Google Sign-in integration
• Image processing services
• QR code generation
• Share functionality
• Location services''',
            ),
            _buildSection(
              title: '9. Data Retention',
              content: '''• Active account data is retained until deletion
• Deleted accounts are removed within 30 days
• Backup data may be retained for up to 30 days
• Analytics data is anonymized after 90 days''',
            ),
            _buildSection(
              title: '10. Changes to Privacy Policy',
              content: '''We may update this policy periodically. Users will be notified of significant changes through:
• In-app notifications
• Email notifications
• App updates''',
            ),
            _buildSection(
              title: '11. Contact Information',
              content: '''For privacy-related inquiries:
Email: privacy@cardfusion.com
Support: support@cardfusion.com''',
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
