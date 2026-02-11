import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _apiService = ApiService();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedMethod = 'ecocash';
  bool _isLoading = false;
  String? _error;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'ecocash',
      'name': 'EcoCash',
      'icon': LucideIcons.smartphone,
      'image': 'assets/images/ecocash.png',
      'color': Colors.green,
    },
    {
      'id': 'onemoney',
      'name': 'OneMoney',
      'icon': LucideIcons.smartphone,
      'image': 'assets/images/onemoney.jpg', // Using jpg as provided
      'color': Colors.purple,
    },
    {
      'id': 'innbucks',
      'name': 'InnBucks',
      'icon': LucideIcons.creditCard,
      'image': 'assets/images/innbucks.png',
      'color': Colors.blue,
    },
    {
      'id': 'omari',
      'name': "O'mari",
      'icon': LucideIcons.wallet,
      'color': Colors.orange,
    },
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initiateTopUp() async {
    // Validate inputs
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Please enter a valid amount');
      return;
    }

    if (_phoneController.text.isEmpty) {
      setState(() => _error = 'Please enter your phone number');
      return;
    }

    // Format phone number (remove spaces, add country code if needed)
    String phone = _phoneController.text.replaceAll(' ', '');
    if (phone.startsWith('0')) {
      phone = '263${phone.substring(1)}'; // Zimbabwe country code
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.initiateTopUp(
        amount: amount,
        phone: phone,
        paymentMethod: _selectedMethod,
      );

      if (result['status'] == 'Error') {
        setState(() {
          _error = result['error'] ?? 'Payment initiation failed';
          _isLoading = false;
        });
        return;
      }

      // For InnBucks, show authorization code
      if (_selectedMethod == 'innbucks' && result['authorization_code'] != null) {
        _showInnBucksDialog(result['authorization_code']);
      }
      // For other methods, check if there's a browser URL to open
      else if (result['browser_url'] != null && result['browser_url'].isNotEmpty) {
        final uri = Uri.parse(result['browser_url']);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        _showPaymentPendingDialog();
      } else {
        // EcoCash/OneMoney will send a prompt to the phone
        _showPaymentPendingDialog();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showInnBucksDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.creditCard, color: Colors.blue),
            const SizedBox(width: 12),
            const Text('InnBucks Code'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter this code in your InnBucks app to complete payment:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                code,
                style: GoogleFonts.oswald(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied to clipboard')),
                );
              },
              icon: const Icon(LucideIcons.copy, size: 16),
              label: const Text('Copy Code'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true); // Return success
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showPaymentPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.clock, color: Colors.orange),
            const SizedBox(width: 12),
            const Text('Payment Pending'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.smartphone,
              size: 64,
              color: _paymentMethods
                  .firstWhere((m) => m['id'] == _selectedMethod)['color'],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedMethod == 'ecocash' || _selectedMethod == 'onemoney'
                  ? 'A payment prompt has been sent to your phone. Please approve it to complete the top-up.'
                  : 'Please complete the payment to add funds to your wallet.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true); // Return success to refresh
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Top Up Wallet',
          style: GoogleFonts.oswald(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.navy,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Input
              Text(
                'Enter Amount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    Text(
                      '\$',
                      style: GoogleFonts.oswald(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.oswald(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navy,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Amount Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [5, 10, 20, 50, 100].map((amount) {
                  return GestureDetector(
                    onTap: () => _amountController.text = amount.toString(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.neutral100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Text(
                        '\$$amount',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.navy,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Payment Method Selection
              Text(
                'Select Payment Method',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...(_paymentMethods.map((method) => _buildPaymentMethodTile(method))),

              const SizedBox(height: 24),

              // Phone Number
              Text(
                'Phone Number',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '07X XXX XXXX',
                    prefixIcon: Icon(LucideIcons.phone, size: 20),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.alertCircle, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _initiateTopUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Pay Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Secure Payment Note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.shield, size: 14, color: AppTheme.neutral400),
                  const SizedBox(width: 6),
                  Text(
                    'Secured by Paynow',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutral400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(Map<String, dynamic> method) {
    final isSelected = _selectedMethod == method['id'];
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? method['color'].withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? method['color'] : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: method['image'] != null ? const EdgeInsets.all(4) : const EdgeInsets.all(10),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: method['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: method['image'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        method['image'],
                        fit: BoxFit.contain,
                      ),
                    )
                  : Icon(method['icon'], color: method['color'], size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                method['name'],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.navy,
                ),
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.checkCircle, color: method['color']),
          ],
        ),
      ),
    );
  }
}
