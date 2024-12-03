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
              content: 'By accessing and using Card Fusion, you accept and agree to be bound by the terms and provision of this agreement.',
            ),
            _buildSection(
              title: '2. Description of Service',
              content: 'Card Fusion provides a digital business card creation and management platform. Users can create, edit, share, and manage their digital business cards.',
            ),
            _buildSection(
              title: '3. User Registration',
              content: 'You must register for an account using valid credentials and maintain the security of your account. You are responsible for all activities that occur under your account.',
            ),
            _buildSection(
              title: '4. User Content',
              content: 'You retain all rights to any content you submit, post or display on Card Fusion. By submitting content, you grant Card Fusion a worldwide, non-exclusive license to use, copy, reproduce, process, adapt, modify, publish, transmit, display and distribute such content.',
            ),
            _buildSection(
              title: '5. Acceptable Use',
              content: 'You agree not to use Card Fusion for any unlawful purposes or to conduct any unlawful activity, including, but not limited to, fraud, embezzlement, money laundering or identity theft.',
            ),
            _buildSection(
              title: '6. Service Modifications',
              content: 'Card Fusion reserves the right to modify or discontinue, temporarily or permanently, the service with or without notice.',
            ),
            _buildSection(
              title: '7. Termination',
              content: 'Card Fusion may terminate or suspend your account and bar access to the service immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever.',
            ),
            _buildSection(
              title: '8. Limitation of Liability',
              content: 'In no event shall Card Fusion be liable for any indirect, incidental, special, consequential or punitive damages, or any loss of profits or revenues.',
            ),
            _buildSection(
              title: '9. Changes to Terms',
              content: 'We reserve the right to modify these terms at any time. We will notify users of any material changes by posting the new Terms of Service on this page.',
            ),
            _buildSection(
              title: '10. Contact Information',
              content: 'For any questions about these Terms, please contact us at support@cardfusion.com',
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