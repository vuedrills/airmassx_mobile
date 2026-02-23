import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showSupportScreen(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.message_outlined),
                    label: const Text('Contact Support'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          
          Text(
            'Direct Contact',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
          ),
          const SizedBox(height: 16),
          
          _buildContactChip(
            context,
            Icons.phone_outlined,
            'Call Us',
            '+263 789 925 823',
            () => _launchURL(context, 'tel:+263789925823'),
          ),
          
          _buildContactChip(
            context,
            Icons.email_outlined,
            'Email Us',
            'support@airmass.co.zw',
            () => _launchURL(context, 'mailto:support@airmass.co.zw'),
          ),
          
          _buildContactChip(
            context,
            Icons.location_on_outlined,
            'Visit Us',
            '356 Rayden Drive Borrowdale,\nHarare, Zimbabwe',
            () {},
            isMultiline: true,
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
            () => _showDeleteAccountDialog(context),
          ),
          
          const SizedBox(height: 40),
          
          Center(
            child: Text(
              'Version 2.1.2',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? '
          'This action cannot be undone and you will lose all your data, history, and access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        await ApiService().deleteAccount();
        
        if (context.mounted) {
          Navigator.pop(context); // Dismiss loading
          context.read<AuthBloc>().add(AuthLogout()); // Trigger logout state
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your account has been deleted.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Dismiss loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete account. Please try again or contact support.')),
          );
        }
      }
    }
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

  Widget _buildContactChip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    VoidCallback onTap, {
    bool isMultiline = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        subtitle: Text(
          value,
          style: const TextStyle(
            color: AppTheme.navy,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            height: 1.3,
          ),
        ),
        trailing: onTap != null && value != '356 Rayden Drive Borrowdale,\nHarare, Zimbabwe' // Address isn't clickable here
            ? Icon(Icons.open_in_new, color: AppTheme.neutral400, size: 18)
            : null,
        onTap: onTap,
      ),
    );
  }

  void _showSupportScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const _ContactSupportScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}

class _ContactSupportScreen extends StatefulWidget {
  const _ContactSupportScreen();

  @override
  State<_ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<_ContactSupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subjectController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService().sendSupportMessage(
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Message sent successfully! We will get back to you soon.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to send message. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Contact Support'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.navy,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How can we help?',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: AppTheme.navy
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fill out the form below and our team will get back to you within 24 hours.',
              style: TextStyle(
                fontSize: 16, 
                color: AppTheme.textSecondary,
                height: 1.5
              ),
            ),
            const SizedBox(height: 32),
            
            // Subject Field
            const Text(
              'Subject',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.navy, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'e.g., Issue with payment',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Message Field
            const Text(
              'Message',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.navy, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Describe your issue in detail...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppTheme.primary.withOpacity(0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text(
                        'Send Message',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
