import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. Introduction',
              'Welcome to PayPulse. We are committed to protecting your personal information and your right to privacy. If you have any questions or concerns about our policy, or our practices with regards to your personal information, please contact us.',
              isDark,
            ),
            _buildSection(
              '2. Information We Collect',
              'We collect personal information that you provide to us such as name, email address, phone number, and financial data including transaction history and balance updates to provide you with a seamless digital wallet experience.',
              isDark,
            ),
            _buildSection(
              '3. How We Use Your Information',
              'We use personal information collected via our App for a variety of business purposes described below. We process your personal information for these purposes in reliance on our legitimate business interests, in order to enter into or perform a contract with you, with your consent, and/or for compliance with our legal obligations.',
              isDark,
            ),
            _buildSection(
              '4. Transaction Security',
              'All financial transactions are encrypted and processed through secure channels. We do not store your full card details on our servers; we use industry-standard tokenization to ensure the highest level of security.',
              isDark,
            ),
            _buildSection(
              '5. Data Retention',
              'We will only keep your personal information for as long as it is necessary for the purposes set out in this privacy policy, unless a longer retention period is required or permitted by law.',
              isDark,
            ),
            _buildSection(
              '6. Contact Us',
              'If you have questions or comments about this policy, you may email us at support@paypulse.ai',
              isDark,
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Last updated: February 2026',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
