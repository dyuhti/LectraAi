import 'package:flutter/material.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last Updated
            Text(
              'Last Updated: April 23, 2026',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // Introduction
            _buildSection(
              title: '1. Introduction',
              content:
                  'Smart Lecture Notes ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
            ),
            const SizedBox(height: 18),

            // Information We Collect
            _buildSection(
              title: '2. Information We Collect',
              content:
                  'We may collect information about you in a variety of ways. The information we may collect on the Site includes:\n\n• Personal Data: Name, email address, and other identification details when you create an account.\n\n• Device Information: Device type, operating system, and unique device identifiers.\n\n• Usage Data: Information about how you interact with the app, including lectures recorded, notes created, and features used.\n\n• Location Data: Approximate location based on IP address (with your consent).',
            ),
            const SizedBox(height: 18),

            // How We Use Your Information
            _buildSection(
              title: '3. How We Use Your Information',
              content:
                  'We use the information we collect in the following ways:\n\n• To provide, maintain, and improve our services.\n\n• To personalize your experience and deliver content relevant to your interests.\n\n• To send you promotional communications (with your consent).\n\n• To monitor and analyze trends, usage, and activities for security and improvement purposes.\n\n• To comply with legal obligations and enforce our Terms of Service.',
            ),
            const SizedBox(height: 18),

            // Data Security
            _buildSection(
              title: '4. Data Security',
              content:
                  'We implement appropriate technical and organizational security measures to protect your personal data against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the Internet is 100% secure, and we cannot guarantee absolute security.',
            ),
            const SizedBox(height: 18),

            // Third-Party Services
            _buildSection(
              title: '5. Third-Party Services',
              content:
                  'Our app may contain links to third-party websites and services that are not operated by us. This Privacy Policy does not apply to third-party services, and we are not responsible for their privacy practices. We encourage you to review the privacy policies of any third-party services before providing your information.',
            ),
            const SizedBox(height: 18),

            // User Rights
            _buildSection(
              title: '6. Your Privacy Rights',
              content:
                  'Depending on your location, you may have certain rights regarding your personal data, including:\n\n• The right to access your personal data.\n\n• The right to correct or delete your personal data.\n\n• The right to restrict or object to processing of your personal data.\n\n• The right to data portability.\n\nTo exercise any of these rights, please contact us at privacy@smartlecturenotes.com.',
            ),
            const SizedBox(height: 18),

            // Data Retention
            _buildSection(
              title: '7. Data Retention',
              content:
                  'We retain your personal data for as long as necessary to fulfill the purposes for which it was collected, including satisfying legal, accounting, or reporting requirements. The retention period may vary depending on the context of the processing and our legal obligations.',
            ),
            const SizedBox(height: 18),

            // Children\'s Privacy
            _buildSection(
              title: '8. Children\'s Privacy',
              content:
                  'Smart Lecture Notes is not directed to individuals under the age of 13. We do not knowingly collect personal information from children under 13. If we become aware that a child under 13 has provided us with personal information, we will promptly delete such information and terminate the child\'s account.',
            ),
            const SizedBox(height: 18),

            // Changes to This Privacy Policy
            _buildSection(
              title: '9. Changes to This Privacy Policy',
              content:
                  'We may update this Privacy Policy from time to time to reflect changes in our practices, technology, legal requirements, or other factors. We will notify you of any significant changes by updating the "Last Updated" date at the top of this policy. Your continued use of the app after any modifications constitutes your acceptance of the updated Privacy Policy.',
            ),
            const SizedBox(height: 18),

            // Contact Us
            _buildSection(
              title: '10. Contact Us',
              content:
                  'If you have any questions about this Privacy Policy or our privacy practices, please contact us at:\n\nEmail: privacy@smartlecturenotes.com\nAddress: Smart Lecture Notes Support\n\nWe will respond to your inquiry within 30 days.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
