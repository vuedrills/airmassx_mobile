import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'invoice_event.dart';
import 'invoice_state.dart';

class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  InvoiceBloc() : super(InvoiceInitial()) {
    on<CreateInvoice>(_onCreateInvoice);
    on<GenerateInvoicePdf>(_onGenerateInvoicePdf);
  }

  Future<void> _onCreateInvoice(
    CreateInvoice event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoiceLoading());
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      emit(InvoiceCreated(event.invoice));
    } catch (e) {
      emit(InvoiceFailure(e.toString()));
    }
  }

  Future<void> _onGenerateInvoicePdf(
    GenerateInvoicePdf event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoiceLoading());
    try {
      final pdf = pw.Document();
      final invoice = event.invoice;

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('INVOICE', style: pw.TextStyle(fontSize: 40)),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('From: ${invoice.fromUserName}'),
                        pw.Text('To: ${invoice.toUserName}'),
                        pw.Text('Date: ${invoice.issueDate.toString().split(' ')[0]}'),
                        pw.Text('Due Date: ${invoice.dueDate.toString().split(' ')[0]}'),
                      ],
                    ),
                    if (invoice.qrCodeData != null)
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: invoice.qrCodeData!,
                        width: 80,
                        height: 80,
                      ),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Table.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Description', 'Quantity', 'Unit Price', 'Total'],
                    ...invoice.items.map(
                      (item) => [
                        item.description,
                        item.quantity.toString(),
                        '\$${item.unitPrice.toStringAsFixed(2)}',
                        '\$${item.total.toStringAsFixed(2)}',
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total Amount: \$${invoice.totalAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Text('Thank you for your business!'),
              ],
            );
          },
        ),
      );

      final Uint8List pdfData = await pdf.save();
      emit(InvoicePdfGenerated(pdfData, 'invoice_${invoice.id}.pdf'));
    } catch (e) {
      emit(InvoiceFailure(e.toString()));
    }
  }
}
