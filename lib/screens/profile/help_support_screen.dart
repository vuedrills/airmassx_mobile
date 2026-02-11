import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';

/// Help & Support screen - FAQ and contact info
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          // Contact support
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.headset_mic,
                    size: 32,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Need help?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Our support team is here to help you 24/7',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'support@airmass.co.zw',
                      query: 'subject=Support Request from App',
                    );
                    try {
                      // Attempt to launch the email client
                      if (!await launchUrl(
                        emailLaunchUri,
                        mode: LaunchMode.externalApplication,
                      )) {
                        // Fallback: try different launch mode or show error
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No email client found. Please email us at support@airmass.co.zw')),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('Error launching email: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open email app.')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Contact Support'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          Text(
            'Frequently Asked Questions',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
          ),

          const SizedBox(height: 16),

          _buildFAQItem(
            context,
            'How do I post a task?',
            'Tap the "Post Task" button on the home screen, fill in the details including title, description, budget, and location, then submit.',
          ),

          _buildFAQItem(
            context,
            'How does payment work?',
            'Payment is securely held by Airmass Xpress Pay until the task is completed. Once you confirm completion, the payment is released to the Tasker.',
          ),

          _buildFAQItem(
            context,
            'What if I\'m not happy with the work?',
            'You can request a revision or open a dispute. Our support team will help resolve any issues.',
          ),

          _buildFAQItem(
            context,
            'How do I become verified?',
            'You can verify your identity by uploading your ID and phone number in the Verification section of your profile.',
          ),
          
          _buildFAQItem(
            context,
            'Can I cancel a task?',
            'Yes, you can cancel a task before it\'s assigned. Once assigned, you\'ll need to discuss with the Tasker or contact support.',
          ),

          const SizedBox(height: 40),
          Divider(height: 1, color: AppTheme.neutral200),
          const SizedBox(height: 32),

          Text(
            'Legal & Info',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
          ),

          const SizedBox(height: 16),

          _buildInfoLink(
            context,
            Icons.description_outlined,
            'Terms & Conditions',
            () {
               _launchURL(context, 'https://www.airmassxpress.com/terms');
            },
          ),
          
          _buildInfoLink(
            context,
            Icons.privacy_tip_outlined,
            'Privacy Policy',
            () {
              _launchURL(context, 'https://www.airmassxpress.com/privacy_policy');
            },
          ),

          _buildInfoLink(
            context,
            Icons.delete_forever_outlined,
            'Delete Account',
            () {
               _launchURL(context, 'https://www.airmassxpress.com/delete-account');
            },
          ),
          
          const SizedBox(height: 40),
          
          Center(
            child: Text(
              'Version 2.1.1',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $urlString')),
          );
        }
      }
    } catch (e) {
       // ignore
    }
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.navy, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(color: AppTheme.textSecondary, height: 1.5, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLink(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.chevron_right, color: AppTheme.neutral400, size: 20),
        onTap: onTap,
      ),
    );
  }
}
