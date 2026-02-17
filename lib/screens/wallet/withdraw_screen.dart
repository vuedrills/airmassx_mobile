import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/wallet.dart';

class WithdrawScreen extends StatefulWidget {
  final double availableBalance;
  
  const WithdrawScreen({super.key, required this.availableBalance});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _apiService = ApiService();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _accountNameController = TextEditingController();
  String _selectedMethod = 'ecocash';
  bool _isLoading = false;
  String? _error;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'ecocash',
      'name': 'EcoCash',
      'icon': LucideIcons.smartphone,
      'color': Colors.green,
    },
    {
      'id': 'onemoney',
      'name': 'OneMoney',
      'icon': LucideIcons.smartphone,
      'color': Colors.purple,
    },
    {
      'id': 'innbucks',
      'name': 'InnBucks',
      'icon': LucideIcons.creditCard,
      'color': Colors.blue,
    },
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _requestWithdrawal() async {
    // Validate inputs
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Please enter a valid amount');
      return;
    }

    if (amount > widget.availableBalance) {
      setState(() => _error = 'Insufficient balance. Available: \$${widget.availableBalance.toStringAsFixed(2)}');
      return;
    }

    if (amount < 5) {
      setState(() => _error = 'Minimum withdrawal is \$5.00');
      return;
    }

    if (_phoneController.text.isEmpty) {
      setState(() => _error = 'Please enter your mobile money number');
      return;
    }

    // Format phone number
    String phone = _phoneController.text.replaceAll(' ', '');
    if (phone.startsWith('0')) {
      phone = '263${phone.substring(1)}';
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final withdrawal = await _apiService.requestWithdrawal(
        amount: amount,
        paymentMethod: _selectedMethod,
        accountNumber: phone,
        accountName: _accountNameController.text.isNotEmpty 
            ? _accountNameController.text 
            : null,
      );

      _showSuccessDialog(withdrawal);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(WithdrawalRequest withdrawal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.checkCircle, color: Colors.green),
            const SizedBox(width: 12),
            const Text('Withdrawal Processed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Withdrawal request submitted. You\'ll be notified once approved and processed.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Amount', '\$${withdrawal.amount.toStringAsFixed(2)}'),
                  if (withdrawal.fee > 0)
                    _buildInfoRow('Fee', '-\$${withdrawal.fee.toStringAsFixed(2)}'),
                  _buildInfoRow('You\'ll receive', '\$${withdrawal.netAmount.toStringAsFixed(2)}'),
                  _buildInfoRow('To', withdrawal.displayPaymentMethod),
                  _buildInfoRow('Account', withdrawal.accountNumber),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Status: Pending Approval',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
          'Withdraw Funds',
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
              // Available Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.navy, AppTheme.navy.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${widget.availableBalance.toStringAsFixed(2)}',
                      style: GoogleFonts.oswald(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Amount Input
              Text(
                'Withdrawal Amount',
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

              const SizedBox(height: 12),

              // Quick Amount Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [10, 25, 50, 100].map((amount) {
                  final isAvailable = amount <= widget.availableBalance;
                  return GestureDetector(
                    onTap: isAvailable 
                        ? () => _amountController.text = amount.toString()
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isAvailable ? AppTheme.neutral100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAvailable ? AppTheme.divider : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        '\$$amount',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isAvailable ? AppTheme.navy : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Withdraw All Button
              TextButton(
                onPressed: widget.availableBalance >= 5
                    ? () => _amountController.text = widget.availableBalance.toStringAsFixed(2)
                    : null,
                child: Text(
                  'Withdraw All',
                  style: TextStyle(
                    color: widget.availableBalance >= 5 ? AppTheme.navy : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Payment Method Selection
              Text(
                'Receive Via',
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
                'Mobile Money Number',
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

              const SizedBox(height: 16),

              // Account Name (Optional)
              Text(
                'Account Name (Optional)',
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
                  controller: _accountNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Name on mobile money account',
                    prefixIcon: Icon(LucideIcons.user, size: 20),
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
                  onPressed: _isLoading ? null : _requestWithdrawal,
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
                          'Withdraw Funds',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Processing Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.info, color: Colors.blue.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Withdrawal requests are reviewed by our team and usually processed within 24 hours.',
                        style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                      ),
                    ),
                  ],
                ),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: method['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(method['icon'], color: method['color'], size: 20),
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
