import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../bloc/invoice/invoice_bloc.dart';
import '../../bloc/invoice/invoice_event.dart';
import '../../bloc/invoice/invoice_state.dart';
import '../../models/invoice.dart';
import '../../config/theme.dart';
import 'view_invoice_screen.dart';

class CreateQuoteScreen extends StatefulWidget {
  final String taskId;
  final String toUserId;
  final String toUserName;

  const CreateQuoteScreen({
    super.key,
    required this.taskId,
    required this.toUserId,
    required this.toUserName,
  });

  @override
  State<CreateQuoteScreen> createState() => _CreateQuoteScreenState();
}

class _CreateQuoteScreenState extends State<CreateQuoteScreen> {
  final List<InvoiceItem> _items = [];
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  void _addItem() {
    if (_descriptionController.text.isEmpty || _priceController.text.isEmpty) {
      return;
    }

    setState(() {
      _items.add(InvoiceItem(
        description: _descriptionController.text,
        quantity: int.tryParse(_quantityController.text) ?? 1,
        unitPrice: double.tryParse(_priceController.text) ?? 0.0,
      ));
      _descriptionController.clear();
      _quantityController.text = '1';
      _priceController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.total);

  @override
  Widget build(BuildContext context) {
    return BlocListener<InvoiceBloc, InvoiceState>(
      listener: (context, state) {
        if (state is InvoiceCreated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ViewInvoiceScreen(invoice: state.invoice),
            ),
          );
        } else if (state is InvoiceFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Quote'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To: ${widget.toUserName}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                'Items',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item.description),
                      subtitle: Text('${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${item.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _quantityController,
                              decoration: const InputDecoration(labelText: 'Quantity'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _priceController,
                              decoration: const InputDecoration(labelText: 'Unit Price'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addItem,
                        child: const Text('Add Item'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${_totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text(_dueDate.toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _dueDate = date);
                  }
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _items.isEmpty
                ? null
                : () {
                    final invoice = Invoice(
                      id: const Uuid().v4(),
                      taskId: widget.taskId,
                      fromUserId: 'current_user_id', // TODO: Get from AuthBloc
                      fromUserName: 'Current User', // TODO: Get from AuthBloc
                      toUserId: widget.toUserId,
                      toUserName: widget.toUserName,
                      items: _items,
                      issueDate: DateTime.now(),
                      dueDate: _dueDate,
                      qrCodeData: 'https://pay.airmass.com/${const Uuid().v4()}',
                    );
                    context.read<InvoiceBloc>().add(CreateInvoice(invoice));
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.navy,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Quote'),
          ),
        ),
      ),
    );
  }
}
