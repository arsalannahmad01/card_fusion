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
              content: 'We collect information you provide directly to us, including name, email address, phone number, profile picture, and other business card information. We also collect usage data and analytics.',
            ),
            _buildSection(
              title: '2. How We Use Your Information',
              content: '''We use the information we collect to:
• Provide and maintain our service
• Notify you about changes to our service
• Allow you to participate in interactive features
• Provide customer support
• Monitor the usage of our service
• Detect, prevent and address technical issues''',
            ),
            _buildSection(
              title: '3. Information Sharing',
              content: 'We share your information with third parties only in ways described in this privacy policy. We do not sell your personal information.',
            ),
            _buildSection(
              title: '4. Data Security',
              content: 'We implement appropriate technical and organizational security measures to protect your data. However, no method of transmission over the Internet is 100% secure.',
            ),
            _buildSection(
              title: '5. Third-Party Services',
              content: 'Our service may contain links to third-party websites. We are not responsible for the privacy practices or content of these third-party sites.',
            ),
            _buildSection(
              title: '6. Children\'s Privacy',
              content: 'Our service does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13.',
            ),
            _buildSection(
              title: '7. Your Data Rights',
              content: '''You have the right to:
• Access your personal data
• Correct inaccurate data
• Request deletion of your data
• Object to data processing
• Request data portability''',
            ),
            _buildSection(
              title: '8. Data Retention',
              content: 'We retain your personal information only for as long as necessary to fulfill the purposes outlined in this privacy policy.',
            ),
            _buildSection(
              title: '9. Changes to Privacy Policy',
              content: 'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.',
            ),
            _buildSection(
              title: '10. Contact Us',
              content: 'If you have any questions about this Privacy Policy, please contact us at privacy@cardfusion.com',
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