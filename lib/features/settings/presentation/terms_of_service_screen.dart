import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
              '1. Acceptance of Terms',
              'By accessing or using the PayPulse application, you agree to be bound by these Terms of Service. If you do not agree to all of these terms, do not use the App.',
              isDark,
            ),
            _buildSection(
              '2. User Account',
              'To use certain features of the App, you must register for an account. You represent and warrant that all information you provide is accurate and that you will keep it up to date. You are responsible for maintaining the confidentiality of your account and password.',
              isDark,
            ),
            _buildSection(
              '3. Wallet and Transactions',
              'PayPulse provides a digital wallet service. You are responsible for all transactions initiated through your account. While we implement advanced AI fraud detection, you should always verify recipient details before sending money.',
              isDark,
            ),
            _buildSection(
              '4. Prohibited Activities',
              'You agree not to use the App for any illegal or unauthorized purpose, including but not limited to money laundering, fraud, or harassment of other users.',
              isDark,
            ),
            _buildSection(
              '5. Limitation of Liability',
              'PayPulse is provided "as is" without any warranties. In no event shall PayPulse be liable for any indirect, incidental, special, or consequential damages arising out of or in connection with your use of the App.',
              isDark,
            ),
            _buildSection(
              '6. Changes to Terms',
              'We reserve the right to modify these terms at any time. We will notify you of any changes by posting the new terms within the App.',
              isDark,
            ),
            _buildSection(
              '7. Governing Law',
              'These terms shall be governed by and construed in accordance with the laws of the jurisdiction in which the company is registered, without regard to its conflict of law provisions.',
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
