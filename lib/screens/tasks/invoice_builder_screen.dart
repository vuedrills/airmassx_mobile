import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../config/theme.dart';
import '../../models/invoice.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../core/service_locator.dart';

/// Screen for creating a professional invoice to attach to an offer
class InvoiceBuilderScreen extends StatefulWidget {
  final String taskTitle;
  final String? businessName;
  final String? businessPhone;
  final String? businessEmail;

  const InvoiceBuilderScreen({
    super.key,
    required this.taskTitle,
    this.businessName,
    this.businessPhone,
    this.businessEmail,
  });

  @override
  State<InvoiceBuilderScreen> createState() => _InvoiceBuilderScreenState();
}

class _InvoiceBuilderScreenState extends State<InvoiceBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<InvoiceItem> _lineItems = [];
  
  // Controllers for new line item
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();
  
  // Invoice details controllers
  late final TextEditingController _businessNameController;
  late final TextEditingController _businessAddressController;
  late final TextEditingController _businessPhoneController;
  late final TextEditingController _businessEmailController;
  final _taxRateController = TextEditingController(text: '0');
  final _deliveryFeeController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  double _taxRate = 0.0;
  double _deliveryFee = 0.0;
  bool _isGenerating = false;
  bool _isLoadingUser = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.businessName ?? '');
    _businessAddressController = TextEditingController();
    _businessPhoneController = TextEditingController(text: widget.businessPhone ?? '');
    _businessEmailController = TextEditingController(text: widget.businessEmail ?? '');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final apiService = getIt<ApiService>();
      final user = await apiService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          if (user != null) {
            if (_businessNameController.text.isEmpty) {
              _businessNameController.text = user.businessName ?? user.name;
            }
            if (_businessAddressController.text.isEmpty) {
              _businessAddressController.text = user.businessAddress ?? user.address ?? '';
            }
            if (_businessPhoneController.text.isEmpty) {
              _businessPhoneController.text = user.phone ?? '';
            }
            if (_businessEmailController.text.isEmpty) {
              _businessEmailController.text = user.email;
            }
          }
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  Future<void> _saveBusinessInfo() async {
    if (_currentUser == null) return;

    final newBusinessName = _businessNameController.text;
    final newBusinessAddress = _businessAddressController.text;

    // Only update if changed
    if (newBusinessName != _currentUser!.businessName ||
        newBusinessAddress != _currentUser!.businessAddress) {
      try {
        await getIt<ApiService>().updateUser(_currentUser!.id, {
          'business_name': newBusinessName,
          'business_address': newBusinessAddress,
        });
      } catch (e) {
        debugPrint('Failed to save business info: $e');
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    _taxRateController.dispose();
    _deliveryFeeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal =>
      _lineItems.fold(0.0, (sum, item) => sum + item.total);

  double get _taxAmount => _subtotal * (_taxRate / 100);

  double get _total => _subtotal + _taxAmount + _deliveryFee;

  void _addLineItem() {
    if (_descriptionController.text.isEmpty || _unitPriceController.text.isEmpty) {
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;

    setState(() {
      _lineItems.add(InvoiceItem(
        description: _descriptionController.text,
        quantity: quantity,
        unitPrice: unitPrice,
      ));

      _descriptionController.clear();
      _quantityController.text = '1';
      _unitPriceController.clear();
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      _lineItems.removeAt(index);
    });
  }

  Future<void> _generatePDF() async {
    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item')),
      );
      return;
    }

    if (_businessNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your business name')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final pdf = pw.Document();
      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      final date = DateTime.now();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => _buildPdfContent(
            invoiceNumber: invoiceNumber,
            date: date,
          ),
        ),
      );
      
      // Save business info to backend for future use
      await _saveBusinessInfo();

      // Save PDF to temporary directory
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/invoice_$invoiceNumber.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        setState(() => _isGenerating = false);
        // Return both file path and total amount
        Navigator.pop(context, {
          'filePath': file.path,
          'total': _total,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  Future<void> _previewPDF() async {
    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item to preview')),
      );
      return;
    }

    final pdf = pw.Document();
    final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
    final date = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => _buildPdfContent(
          invoiceNumber: invoiceNumber,
          date: date,
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _buildPdfContent({
    required String invoiceNumber,
    required DateTime date,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(invoiceNumber, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(_businessNameController.text,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                if (_businessAddressController.text.isNotEmpty)
                  pw.Text(_businessAddressController.text, style: const pw.TextStyle(fontSize: 10)),
                if (_businessPhoneController.text.isNotEmpty)
                  pw.Text(_businessPhoneController.text, style: const pw.TextStyle(fontSize: 10)),
                if (_businessEmailController.text.isNotEmpty)
                  pw.Text(_businessEmailController.text, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 20),

        // Project Info
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PROJECT:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(widget.taskTitle),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('DATE:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat('MMM dd, yyyy').format(date)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 30),

        // Line Items Table
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Unit Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            // Items
            ..._lineItems.map((item) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(item.description),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(item.quantity.toString()),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('\$${item.unitPrice.toStringAsFixed(2)}'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('\$${item.total.toStringAsFixed(2)}'),
                    ),
                  ],
                )),
          ],
        ),
        pw.SizedBox(height: 20),

        // Totals
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            width: 250,
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal:'),
                    pw.Text('\$${_subtotal.toStringAsFixed(2)}'),
                  ],
                ),
                if (_taxRate > 0) ...[
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Tax ($_taxRate%):'),
                      pw.Text('\$${_taxAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
                if (_deliveryFee > 0) ...[
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Delivery:'),
                      pw.Text('\$${_deliveryFee.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.Text('\$${_total.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Notes
        if (_notesController.text.isNotEmpty) ...[
          pw.SizedBox(height: 30),
          pw.Text('NOTES:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(_notesController.text, style: const pw.TextStyle(fontSize: 10)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Invoice',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.navy,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.preview, color: AppTheme.primary),
            onPressed: _previewPDF,
            tooltip: 'Preview',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Information
              _SectionHeader(title: 'Business Information'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _businessNameController,
                label: 'Business Name *',
                hint: 'Your Company Name',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _businessAddressController,
                label: 'Address',
                hint: 'Street, City, State',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _businessPhoneController,
                      label: 'Phone',
                      hint: '+1234567890',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _businessEmailController,
                      label: 'Email',
                      hint: 'email@example.com',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Line Items
              _SectionHeader(title: 'Line Items'),
              const SizedBox(height: 12),
              
              // Add New Item Form
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'What service or item?',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: _quantityController,
                            label: 'Qty',
                            hint: '1',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _unitPriceController,
                            label: 'Unit Price',
                            hint: '0.00',
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addLineItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // List of Added Items
              if (_lineItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                ..._lineItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _LineItemCard(
                    item: item,
                    onRemove: () => _removeLineItem(index),
                  );
                }),
              ],
              const SizedBox(height: 32),

              // Additional Charges
              _SectionHeader(title: 'Additional Charges'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _taxRateController,
                      label: 'Tax Rate (%)',
                      hint: '0',
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        setState(() {
                          _taxRate = double.tryParse(value) ?? 0.0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _deliveryFeeController,
                      label: 'Delivery Fee',
                      hint: '0.00',
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        setState(() {
                          _deliveryFee = double.tryParse(value) ?? 0.0;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Notes
              _SectionHeader(title: 'Notes (Optional)'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _notesController,
                label: 'Additional Notes',
                hint: 'Payment terms, warranty info, etc.',
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Subtotal', value: '\$${_subtotal.toStringAsFixed(2)}'),
                    if (_taxRate > 0) _SummaryRow(label: 'Tax ($_taxRate%)', value: '\$${_taxAmount.toStringAsFixed(2)}'),
                    if (_deliveryFee > 0) _SummaryRow(label: 'Delivery', value: '\$${_deliveryFee.toStringAsFixed(2)}'),
                    const Divider(),
                    _SummaryRow(
                      label: 'TOTAL',
                      value: '\$${_total.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isGenerating ? null : _generatePDF,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isGenerating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Generate & Attach Invoice',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.navy,
      ),
    );
  }
}

class _LineItemCard extends StatelessWidget {
  final InvoiceItem item;
  final VoidCallback onRemove;

  const _LineItemCard({
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${item.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? AppTheme.navy : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? AppTheme.primary : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
