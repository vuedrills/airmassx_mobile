import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import '../../bloc/offer/offer_bloc.dart';
import '../../bloc/offer/offer_event.dart';
import '../../bloc/offer/offer_state.dart';
import '../../config/app_spacing.dart';
import '../../config/theme.dart';
import '../../core/service_locator.dart';
import '../../models/task.dart';
import 'invoice_builder_screen.dart';

class MakeOfferScreen extends StatelessWidget {
  final Task task;

  const MakeOfferScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OfferBloc>(),
      child: _MakeOfferContent(task: task),
    );
  }
}

class _MakeOfferContent extends StatefulWidget {
  final Task task;

  const _MakeOfferContent({required this.task});

  @override
  State<_MakeOfferContent> createState() => _MakeOfferContentState();
}

class _MakeOfferContentState extends State<_MakeOfferContent> {
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  String? _invoiceFilePath;
  String? _invoiceFileName;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      final val = double.tryParse(_amountController.text) ?? 0;
      context.read<OfferBloc>().add(OfferAmountChanged(val));
    });
    _messageController.addListener(() {
      context.read<OfferBloc>().add(OfferMessageChanged(_messageController.text));
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _createInvoice() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceBuilderScreen(
          taskTitle: widget.task.title,
        ),
      ),
    );

    if (result != null && mounted) {
      final filePath = result['filePath'] as String;
      final total = result['total'] as double;
      
      setState(() {
        _invoiceFilePath = filePath;
        _invoiceFileName = filePath.split('/').last;
        // Auto-populate offer amount with invoice total
        _amountController.text = total.toStringAsFixed(0);
      });
      context.read<OfferBloc>().add(OfferInvoiceChanged(filePath));
      context.read<OfferBloc>().add(OfferAmountChanged(total));
    }
  }

  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null && mounted) {
      final filePath = result.files.single.path!;
      setState(() {
        _invoiceFilePath = filePath;
        _invoiceFileName = result.files.single.name;
      });
      context.read<OfferBloc>().add(OfferInvoiceChanged(filePath));
    }
  }

  void _removeInvoice() {
    setState(() {
      _invoiceFilePath = null;
      _invoiceFileName = null;
    });
    context.read<OfferBloc>().add(const OfferInvoiceChanged(null));
  }

  void _showInvoiceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.topLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Attach Invoice',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutral900,
                  ),
            ),
            AppSpacing.vMd,
            const Text(
              'Add a professional invoice to your bid',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.neutral600),
            ),
            AppSpacing.vLg,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _createInvoice();
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Create Invoice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            AppSpacing.vMd,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickPDF();
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
            AppSpacing.vMd,
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInventoryRequiredModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.topLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.primary),
            AppSpacing.vLg,
            Text(
              'Equipment Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutral900,
                  ),
            ),
            AppSpacing.vMd,
            Text(
              'This task requires specific equipment that is not in your inventory. Please register your equipment to place a bid.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutral600,
                  ),
            ),
            AppSpacing.vXl,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Redirect to Add Equipment / Inventory screen
                  context.push('/profile/inventory');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add Equipment First'),
              ),
            ),
            AppSpacing.vMd,
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            AppSpacing.vLg,
          ],
        ),
      ),
    );
  }

  void _showApprovalPendingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.topLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pending_actions_outlined, size: 64, color: Colors.orange),
            AppSpacing.vLg,
            Text(
              'Application Pending',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutral900,
                  ),
            ),
            AppSpacing.vMd,
            const Text(
              'Your tasker application is currently under review. You\'ll be able to place bids once our team approves your profile.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.neutral600),
            ),
            AppSpacing.vXl,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Got it'),
              ),
            ),
            AppSpacing.vLg,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfferBloc, OfferState>(
      listener: (context, state) {
        if (state.status == OfferStatus.success) {
          Navigator.pop(context, true); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bid submitted successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.status == OfferStatus.failure) {
          if (state.errorCode == 'INVENTORY_REQUIRED') {
            _showInventoryRequiredModal(context);
          } else if (state.errorCode == 'TASKER_NOT_APPROVED') {
            _showApprovalPendingModal(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Failed to submit bid'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Place a Bid'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Summary
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppTheme.neutral50,
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: AppTheme.neutral200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.task.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.neutral900,
                                ),
                          ),
                          AppSpacing.vXs,
                          Text(
                            widget.task.locationAddress,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.neutral500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${widget.task.budget.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navy,
                          ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vLg,

              // Offer Amount
              Text(
                'Your Bid',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutral900,
                    ),
              ),
              AppSpacing.vSm,
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutral900,
                  ),
                  hintText: '0',
                  filled: true,
                  fillColor: AppTheme.neutral50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                    borderSide: const BorderSide(color: AppTheme.neutral200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                  helperText: 'Enter the amount you want to be paid',
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neutral900,
                ),
              ),
              AppSpacing.vLg,

              // Message
              Text(
                'Message (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutral900,
                    ),
              ),
              AppSpacing.vSm,
              TextField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Why are you the best person for this task?',
                  filled: true,
                  fillColor: AppTheme.neutral50,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                    borderSide: const BorderSide(color: AppTheme.neutral200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              AppSpacing.vLg,

              // Invoice Attachment (Optional)
              Text(
                'Invoice (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutral900,
                    ),
              ),
              AppSpacing.vSm,
              if (_invoiceFilePath == null)
                OutlinedButton.icon(
                  onPressed: _showInvoiceOptions,
                  icon: const Icon(Icons.attach_file, size: 20),
                  label: const Text('Attach Invoice or Quote'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    side: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                  ),
                )
              else
                InkWell(
                  onTap: () async {
                    if (_invoiceFilePath != null) {
                      final file = File(_invoiceFilePath!);
                      if (await file.exists()) {
                        await Printing.layoutPdf(
                          onLayout: (format) async => file.readAsBytes(),
                          name: _invoiceFileName ?? 'Invoice',
                        );
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invoice file no longer exists.')),
                          );
                        }
                      }
                    }
                  },
                  borderRadius: AppRadius.mdAll,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.05),
                      borderRadius: AppRadius.mdAll,
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.picture_as_pdf, color: AppTheme.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _invoiceFileName ?? 'Invoice',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.neutral900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'PDF attached (Click to view)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _removeInvoice,
                          icon: const Icon(Icons.close, size: 20),
                          color: AppTheme.neutral600,
                        ),
                      ],
                    ),
                  ),
                ),
              AppSpacing.vXxl,

              // Submit Button
              BlocBuilder<OfferBloc, OfferState>(
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.status == OfferStatus.submitting
                          ? null
                          : () {
                              context.read<OfferBloc>().add(OfferSubmitted(widget.task.id));
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: state.status == OfferStatus.submitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Submit Bid',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
