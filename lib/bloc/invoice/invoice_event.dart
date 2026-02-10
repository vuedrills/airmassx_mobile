import 'package:equatable/equatable.dart';
import '../../models/invoice.dart';

abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();

  @override
  List<Object?> get props => [];
}

class CreateInvoice extends InvoiceEvent {
  final Invoice invoice;

  const CreateInvoice(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class GenerateInvoicePdf extends InvoiceEvent {
  final Invoice invoice;

  const GenerateInvoicePdf(this.invoice);

  @override
  List<Object?> get props => [invoice];
}
