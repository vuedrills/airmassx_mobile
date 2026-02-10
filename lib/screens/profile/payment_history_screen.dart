import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';
import '../../models/payment_transaction.dart';
import '../../config/theme.dart';
import '../../core/service_locator.dart';

/// Payment history screen - transaction list
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadPaymentHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PaymentHistoryLoaded) {
            return _buildTransactionsList(context, state.transactions);
          }

          if (state is ProfileLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return const Center(child: Text('No transactions'));
        },
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context, List<PaymentTransaction> transactions) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(context, transaction);
      },
    );
  }

  Widget _buildTransactionCard(BuildContext context, PaymentTransaction transaction) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: CircleAvatar(
        backgroundColor: _getTransactionColor(transaction.type).withValues(alpha: 0.1),
        child: Icon(
          _getTransactionIcon(transaction.type),
          color: _getTransactionColor(transaction.type),
        ),
      ),
      title: Text(transaction.taskTitle),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(DateFormat('dd MMM yyyy, HH:mm').format(transaction.date)),
          const SizedBox(height: 2),
          Row(
            children: [
              _buildStatusChip(transaction.status),
              if (transaction.description != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    transaction.description!,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: Text(
        '${transaction.type == TransactionType.withdrawal ? '-' : '+'}USD ${transaction.amount.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: transaction.type == TransactionType.withdrawal
              ? AppTheme.accentRed
              : AppTheme.accentGreen,
        ),
      ),
      isThreeLine: true,
    );
  }

  Widget _buildStatusChip(TransactionStatus status) {
    Color color;
    String label;

    switch (status) {
      case TransactionStatus.completed:
        color = AppTheme.accentGreen;
        label = 'Completed';
        break;
      case TransactionStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case TransactionStatus.failed:
        color = AppTheme.accentRed;
        label = 'Failed';
        break;
      case TransactionStatus.cancelled:
        color = AppTheme.textSecondary;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.payment:
        return Icons.arrow_downward;
      case TransactionType.refund:
        return Icons.restart_alt;
      case TransactionType.withdrawal:
        return Icons.arrow_upward;
      case TransactionType.deposit:
        return Icons.add_circle_outline;
    }
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.payment:
        return AppTheme.accentGreen;
      case TransactionType.refund:
        return AppTheme.accentTeal;
      case TransactionType.withdrawal:
        return AppTheme.accentRed;
      case TransactionType.deposit:
        return AppTheme.navy;
    }
  }
}
