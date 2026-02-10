import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../models/invoice.dart';

abstract class InvoiceState extends Equatable {
  const InvoiceState();

  @override
  List<Object?> get props => [];
}

class InvoiceInitial extends InvoiceState {}

class InvoiceLoading extends InvoiceState {}

class InvoiceCreated extends InvoiceState {
  final Invoice invoice;

  const InvoiceCreated(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class InvoicePdfGenerated extends InvoiceState {
  final Uint8List pdfData;
  final String fileName;

  const InvoicePdfGenerated(this.pdfData, this.fileName);

  @override
  List<Object?> get props => [pdfData, fileName];
}

class InvoiceFailure extends InvoiceState {
  final String message;

  const InvoiceFailure(this.message);

  @override
  List<Object?> get props => [message];
}
