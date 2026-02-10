import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../bloc/invoice/invoice_bloc.dart';
import '../../bloc/invoice/invoice_event.dart';
import '../../bloc/invoice/invoice_state.dart';
import '../../models/invoice.dart';
import '../../config/theme.dart';

class ViewInvoiceScreen extends StatefulWidget {
  final Invoice invoice;

  const ViewInvoiceScreen({super.key, required this.invoice});

  @override
  State<ViewInvoiceScreen> createState() => _ViewInvoiceScreenState();
}

class _ViewInvoiceScreenState extends State<ViewInvoiceScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InvoiceBloc>().add(GenerateInvoicePdf(widget.invoice));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Printing package handles sharing via PdfPreview
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.invoice.qrCodeData != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  const Text(
                    'Scan to Pay',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  QrImageView(
                    data: widget.invoice.qrCodeData!,
                    version: QrVersions.auto,
                    size: 150.0,
                  ),
                ],
              ),
            ),
          Expanded(
            child: BlocBuilder<InvoiceBloc, InvoiceState>(
              builder: (context, state) {
                if (state is InvoiceLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is InvoicePdfGenerated) {
                  return PdfPreview(
                    build: (format) => state.pdfData,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                  );
                } else if (state is InvoiceFailure) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                return const Center(child: Text('Generating PDF...'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
