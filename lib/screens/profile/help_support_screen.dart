import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.all(16),
        children: [
          // Contact support
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.headset_mic,
                    size: 48,
                    color: AppTheme.navy,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Need help?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Our support team is here to help you 24/7',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contact support coming soon')),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Contact Support'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Frequently Asked Questions',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
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

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            'More Information',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 12),

          _buildInfoLink(
            context,
            Icons.description,
            'Terms & Conditions',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms & Conditions coming soon')),
              );
            },
          ),

          _buildInfoLink(
            context,
            Icons.privacy_tip,
            'Privacy Policy',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy coming soon')),
              );
            },
          ),

          _buildInfoLink(
            context,
            Icons.security,
            'Safety Center',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Safety Center coming soon')),
              );
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoLink(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textPrimary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}
